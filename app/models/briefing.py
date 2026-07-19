"""Briefing context models — unified format from all data sources."""

from __future__ import annotations

from datetime import date

from pydantic import BaseModel


class EmailItem(BaseModel):
    subject: str
    sender: str
    snippet: str
    date: str


class TaskItem(BaseModel):
    title: str
    source: str  # "github" or "ical"
    priority: str = "normal"
    due_date: str | None = None
    description: str = ""


class BriefingContext(BaseModel):
    date: date
    emails: list[EmailItem] = []
    tasks: list[TaskItem] = []
    events: list[TaskItem] = []
    summary: str = ""