"""Tests for iCal integration service."""

from datetime import date
from unittest.mock import AsyncMock, MagicMock, patch

from app.models.briefing import TaskItem
from app.services.ical import fetch_today_events


def _today_ics() -> str:
    """Return ICS data with today's date."""
    today = date.today().strftime("%Y%m%d")
    tomorrow = (date.today() + __import__("datetime").timedelta(days=1)).strftime("%Y%m%d")
    return f"""BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Test//Test//EN
BEGIN:VEVENT
DTSTART;VALUE=DATE:{today}
DTEND;VALUE=DATE:{tomorrow}
SUMMARY:Team meeting
DESCRIPTION:Weekly sync
UID:meeting-001@test.com
END:VEVENT
BEGIN:VEVENT
DTSTART;VALUE=DATE:{today}T140000
DTEND;VALUE=DATE:{today}T150000
SUMMARY:Code review
DESCRIPTION:Review PR #42
UID:review-001@test.com
END:VEVENT
BEGIN:VEVENT
DTSTART;VALUE=DATE:{tomorrow}
DTEND;VALUE=DATE:{tomorrow}
SUMMARY:Tomorrow event
UID:future-001@test.com
END:VEVENT
END:VCALENDAR
"""


async def test_fetch_today_events_parses_ics() -> None:
    """fetch_today_events parses ics data and returns EventItem list."""
    ics_data = _today_ics()

    mock_response = AsyncMock()
    mock_response.text = ics_data
    mock_response.raise_for_status = MagicMock()

    with patch("app.services.ical.httpx.AsyncClient") as mock_client_cls:
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
    ics_data = _today_ics()

    mock_response = AsyncMock()
    mock_response.text = ics_data
    mock_response.raise_for_status = MagicMock()

    with patch("app.services.ical.httpx.AsyncClient") as mock_client_cls:
        mock_client = AsyncMock()
        mock_client.__aenter__ = AsyncMock(return_value=mock_client)
        mock_client.__aexit__ = AsyncMock(return_value=None)
        mock_client.get.return_value = mock_response
        mock_client_cls.return_value = mock_client

        result = await fetch_today_events(["http://example.com/calendar.ics"])

    assert len(result) == 2
    assert result[0].title == "Team meeting"


async def test_fetch_today_events_handles_fetch_errors() -> None:
    """When an iCal URL fails, it skips that URL and tries others."""
    ics_data = _today_ics()

    good_response = AsyncMock()
    good_response.text = ics_data
    good_response.raise_for_status = MagicMock()

    with patch("app.services.ical.httpx.AsyncClient") as mock_client_cls:
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

    assert len(result) == 2
    assert result[0].title == "Team meeting"