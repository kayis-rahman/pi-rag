"""Tests for Gmail integration service."""

from unittest.mock import MagicMock, patch

from app.models.briefing import EmailItem
from app.services.gmail import fetch_today_emails


async def test_fetch_today_emails_returns_list() -> None:
    """fetch_today_emails returns a list of EmailItem."""
    mock_creds = MagicMock()
    mock_creds.valid = True

    mock_service = MagicMock()
    mock_service.users().messages().list().execute.return_value = {
        "messages": [{"id": "1"}],
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

    with patch("app.services.gmail.build", return_value=MagicMock(users=MagicMock(return_value=mock_service))), \
         patch("app.services.gmail.Credentials.from_authorized_user_file", return_value=mock_creds):
        result = await fetch_today_emails()

    assert len(result) == 1
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
    mock_creds = MagicMock()
    mock_creds.valid = True

    mock_service = MagicMock()
    mock_service.users().messages().list().execute.return_value = {}

    with patch("app.services.gmail.build", return_value=MagicMock(users=MagicMock(return_value=mock_service))), \
         patch("app.services.gmail.Credentials.from_authorized_user_file", return_value=mock_creds):
        result = await fetch_today_emails()

    assert result == []