"""Gmail integration — fetch today's emails for briefing."""

from __future__ import annotations

import logging
from datetime import datetime

from app.config import settings
from app.models.briefing import EmailItem

logger = logging.getLogger(__name__)


async def fetch_today_emails() -> list[EmailItem]:
    """Fetch today's unread emails via Gmail API."""
    if not settings.GMAIL_API_ENABLED:
        return []

    try:
        from google.oauth2.credentials import Credentials
        from googleapiclient.discovery import build
        from google.auth.transport.requests import Request as GoogleRequest
        from google.oauth2 import service_account

        creds = None
        if settings.GMAIL_CREDENTIALS_PATH:
            try:
                from google.oauth2 import credentials
                creds = credentials.Credentials.from_authorized_user_file(
                    settings.GMAIL_CREDENTIALS_PATH,
                    ["https://www.googleapis.com/auth/gmail.readonly"],
                )
            except (FileNotFoundError, ValueError):
                logger.warning("No Gmail credentials found at %s", settings.GMAIL_CREDENTIALS_PATH)
                return []

        if not creds or not creds.valid:
            if creds and creds.expired and creds.refresh_token:
                creds.refresh(GoogleRequest())
            else:
                return []

        service = build("gmail", "v1", credentials=creds)

        # Fetch recent messages (last 7 days)
        results = service.users().messages().list(
            userId="me",
            q="is:unread after:" + datetime.now().strftime("%Y/%m/01"),
            maxResults=50,
        ).execute()

        messages = results.get("messages", [])
        if not messages:
            return []

        emails = []
        for msg_id in messages[:10]:
            msg = service.users().messages().get(
                userId="me", id=msg_id["id"], format="metadata",
                metadataHeaders=["Subject", "From", "Date"],
            ).execute()

            headers = {h["name"].lower(): h["value"] for h in msg.get("payload", {}).get("headers", [])}
            emails.append(EmailItem(
                subject=headers.get("subject", "(no subject)"),
                sender=headers.get("from", "unknown"),
                snippet=msg.get("snippet", ""),
                date=headers.get("date", ""),
            ))

        return emails

    except Exception:
        logger.exception("Failed to fetch Gmail messages")
        return []