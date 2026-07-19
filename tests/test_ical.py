"""Tests for iCal integration service."""

from datetime import datetime
from unittest.mock import AsyncMock, MagicMock, patch

from app.models.briefing import TaskItem
from app.services.ical import fetch_today_events


async def test_fetch_today_events_parses_ics() -> None:
    """fetch_today_events parses ics data and returns EventItem list."""
    ics_data = """BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Test//Test//EN
BEGIN:VEVENT
DTSTART;VALUE=DATE:20260714
DTEND;VALUE=DATE:20260715
SUMMARY:Team meeting
DESCRIPTION:Weekly sync
UID:meeting-001@test.com
END:VEVENT
BEGIN:VEVENT
DTSTART;VALUE=DATE:20260714T140000
DTEND;VALUE=DATE:20260714T150000
SUMMARY:Code review
DESCRIPTION:Review PR #42
UID:review-001@test.com
END:VEVENT
BEGIN:VEVENT
DTSTART;VALUE=DATE:20260715
DTEND;VALUE=DATE:20260716
SUMMARY:Tomorrow event
UID:future-001@test.com
END:VEVENT
END:VCALENDAR
"""

    mock_response = AsyncMock()
    mock_response.text = ics_data
    mock_response.raise_for_status = MagicMock()

    with patch("app.services.github.httpx.AsyncClient") as mock_client_cls:
        mock_client = AsyncMock()
        mock_client.__aenter__ = AsyncMock(return_value=mock_client)
        mock_client.__aexit__ = AsyncMock(return_value=None)
        mock_client.get.return_value = mock_response
        mock_client_cls.return_value = mock_client

        result = await fetch_today_events(["http://example.com/calendar.ics"])

    assert len(result) == 2
    assert result[0].title == "Team meeting"
    assert result[0].source == "ical"
    assert result[1].title == "Code review"
    # Future event should not be included
    assert not any(e.title == "Tomorrow event" for e in result)


async def test_fetch_today_events_empty_when_no_urls() -> None:
    """When no iCal URLs configured, returns empty list."""
    result = await fetch_today_events([])
    assert result == []


async def test_fetch_today_events_handles_single_url() -> None:
    """fetch_today_events works with a single URL."""
    ics_data = """BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Test//Test//EN
BEGIN:VEVENT
DTSTART;VALUE=DATE:20260714
DTEND;VALUE=DATE:20260715
SUMMARY:Daily standup
UID:daily-001@test.com
END:VEVENT
END:VCALENDAR
"""

    mock_response = AsyncMock()
    mock_response.text = ics_data
    mock_response.raise_for_status = MagicMock()

    with patch("app.services.github.httpx.AsyncClient") as mock_client_cls:
        mock_client = AsyncMock()
        mock_client.__aenter__ = AsyncMock(return_value=mock_client)
        mock_client.__aexit__ = AsyncMock(return_value=None)
        mock_client.get.return_value = mock_response
        mock_client_cls.return_value = mock_client

        result = await fetch_today_events(["http://example.com/calendar.ics"])

    assert len(result) == 1
    assert result[0].title == "Daily standup"


async def test_fetch_today_events_handles_fetch_errors() -> None:
    """When an iCal URL fails, it skips that URL and tries others."""
    ics_data = """BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Test//Test//EN
BEGIN:VEVENT
DTSTART;VALUE=DATE:20260714
DTEND;VALUE=DATE:20260715
SUMMARY:Good calendar
UID:good-001@test.com
END:VEVENT
END:VCALENDAR
"""

    good_response = AsyncMock()
    good_response.text = ics_data
    good_response.raise_for_status = MagicMock()

    with patch("app.services.github.httpx.AsyncClient") as mock_client_cls:
        mock_client = AsyncMock()
        mock_client.__aenter__ = AsyncMock(return_value=mock_client)
        mock_client.__aexit__ = AsyncMock(return_value=None)

        # First URL fails, second succeeds
        async def side_effect(*args, **kwargs):
            if "bad" in str(kwargs.get("url", "")):
                raise Exception("Connection error")
            return good_response

        mock_client.get.side_effect = side_effect
        mock_client_cls.return_value = mock_client

        result = await fetch_today_events([
            "http://bad.example.com/calendar.ics",
            "http://good.example.com/calendar.ics",
        ])

    assert len(result) == 1
    assert result[0].title == "Good calendar"