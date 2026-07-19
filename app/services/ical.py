"""iCal integration — fetch today's events from .ics URLs."""

from __future__ import annotations

import logging
from datetime import datetime, date

import httpx
from app.models.briefing import TaskItem

logger = logging.getLogger(__name__)


def _parse_ics_events(ics_text: str) -> list[TaskItem]:
    """Parse ics text into EventItem list for today."""
    today = date.today()
    events = []

    for vevent in _extract_vevents(ics_text):
        dtstart = _extract_datetime(vevent, "DTSTART")
        if dtstart is None:
            continue

        summary = _extract_property(vevent, "SUMMARY") or "(no title)"
        description = _extract_property(vevent, "DESCRIPTION") or ""

        # Compare dates — handle both date-only and datetime
        if isinstance(dtstart, datetime):
            event_date = dtstart.date()
        else:
            event_date = dtstart

        if event_date == today:
            events.append(TaskItem(
                title=summary,
                source="ical",
                priority="normal",
                due_date=dtstart.strftime("%Y-%m-%d") if hasattr(dtstart, "strftime") else str(dtstart),
                description=description,
            ))

    return events


def _extract_vevents(text: str) -> list[str]:
    """Extract VEVENT blocks from ics text."""
    events = []
    in_event = False
    current = []

    for line in text.splitlines():
        if line == "BEGIN:VEVENT":
            in_event = True
            current = []
        elif line == "END:VEVENT" and in_event:
            in_event = False
            events.append("\n".join(current))
        elif in_event:
            current.append(line)

    return events


def _extract_property(vevent: str, prop: str) -> str | None:
    """Extract a property value from a VEVENT block."""
    for line in vevent.splitlines():
        if line.startswith(prop + ":"):
            return line[len(prop) + 1:].strip()
    return None


def _extract_datetime(vevent: str, prop: str) -> date | datetime | None:
    """Extract a date or datetime from a VEVENT block."""
    value = _extract_property(vevent, prop)
    if not value:
        return None

    # Remove VALUE=DATE parameter if present
    value = value.replace("VALUE=DATE:", "")

    # Try datetime format first
    for fmt in ("%Y%m%dT%H%M%SZ", "%Y%m%dT%H%M%S", "%Y-%m-%dT%H:%M:%S"):
        try:
            return datetime.strptime(value, fmt)
        except ValueError:
            continue

    # Try date-only format
    try:
        return datetime.strptime(value, "%Y%m%d").date()
    except ValueError:
        return None


async def fetch_today_events(ical_urls: list[str] | None = None) -> list[TaskItem]:
    """Fetch today's events from all configured iCal URLs."""
    if not ical_urls:
        from app.config import settings
        ical_urls = settings.ICAL_URLS

    if not ical_urls:
        return []

    all_events = []
    async with httpx.AsyncClient(timeout=30.0) as client:
        for url in ical_urls:
            try:
                resp = await client.get(url)
                resp.raise_for_status()
                all_events.extend(_parse_ics_events(resp.text))
            except Exception:
                logger.warning("Failed to fetch iCal from %s", url)

    return all_events