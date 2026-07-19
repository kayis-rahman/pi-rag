"""Tests for Gmail integration service."""

from datetime import datetime
from unittest.mock import AsyncMock, MagicMock, patch

from app.models.briefing import EmailItem
from app.services.gmail import fetch_today_emails


def _mock_gmail_service() -> MagicMock:
    """Create a mock Gmail service that returns sample emails."""
    mock_service = MagicMock()
    mock_messages = [
        {"id": "1", "snippet": "Meeting at 10am"},
        {"id": "2", "snippet": "Project update"},
        {"id": "3", "snippet": "Lunch plans"},
    ]
    mock_service.users().messages().list().execute.return_value = {
        "messages": [{"id": m["id"]} for m in mock_messages]
    }
    mock_service.users().messages().get().execute.return_value = {
        "payload": {"headers": [
            {"name": "Subject", "value": "Team standup"},
            {"name": "From", "value": "alice@example.com"},
            {"name": "Date", "value": "Mon, 14 Jul 2026 09:00:00"},
        ]},
        "snippet": "Meeting at 10am",
        "id": "1",
    }
    return mock_service


def _mock_gmail_credentials() -> MagicMock:
    creds = MagicMock()
    creds.valid = True
    return creds


async def test_fetch_today_emails_returns_list() -> None:
    """fetch_today_emails returns a list of EmailItem."""
    mock_service = _mock_gmail_service()
    mock_creds = _mock_gmail_credentials()

    with patch("app.services.gmail.build") as mock_build, \
         patch("app.services.gmail.google.auth.transport.requests.Request") as mock_auth_req, \
         patch("app.services.gmail.credentials_from_file", return_value=mock_creds):
        mock_build.return_value = MagicMock(users=MagicMock(return_value=mock_service))
        mock_auth_req.return_value = MagicMock()

        result = await fetch_today_emails()

    assert isinstance(result, list)
    assert len(result) == 1  # One message returned
    assert isinstance(result[0], EmailItem)
    assert result[0].subject == "Team standup"
    assert result[0].sender == "alice@example.com"


async def test_fetch_today_emails_empty_when_disabled() -> None:
    """When Gmail is disabled, returns empty list."""
    with patch("app.config.settings.GMAIL_API_ENABLED", False):
        result = await fetch_today_emails()

    assert result == []


async def test_fetch_today_emails_empty_when_no_messages() -> None:
    """When Gmail returns no messages, returns empty list."""
    mock_service = MagicMock()
    mock_service.users().messages().list().execute.return_value = {}

    with patch("app.services.gmail.build") as mock_build, \
         patch("app.services.gmail.google.auth.transport.requests.Request") as mock_auth_req, \
         patch("app.services.gmail.credentials_from_file", return_value=MagicMock(valid=True)):
        mock_build.return_value = MagicMock(users=MagicMock(return_value=mock_service))
        mock_auth_req.return_value = MagicMock()

        result = await fetch_today_emails()

    assert result == []