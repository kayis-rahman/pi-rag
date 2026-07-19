"""GitHub Projects integration — fetch active tasks for briefing."""

from __future__ import annotations

import logging
from datetime import datetime

import httpx
from app.config import settings
from app.models.briefing import TaskItem

logger = logging.getLogger(__name__)

GITHUB_GRAPHQL = "https://api.github.com/graphql"


async def fetch_active_tasks() -> list[TaskItem]:
    """Fetch active/open tasks from GitHub Projects board."""
    if not settings.GITHUB_TOKEN:
        return []

    query = """
    query {
      projectV2(number: $projectNumber) {
        items(first: 50) {
          nodes {
            content {
              ... on Issue {
                title
                body
                state
                labels(first: 10) { nodes { name } }
                dueDate
                assignee { login }
              }
            }
          }
        }
      }
    }
    """

    variables = {
        "projectNumber": settings.GITHUB_PROJECT_NUMBER,
        "owner": settings.GITHUB_OWNER,
    }

    async with httpx.AsyncClient() as client:
        resp = await client.post(
            GITHUB_GRAPHQL,
            json={"query": query, "variables": variables},
            headers={"Authorization": f"Bearer {settings.GITHUB_TOKEN}"},
        )
        resp.raise_for_status()
        data = resp.json()

    nodes = data.get("data", {}).get("projectV2", {}).get("items", {}).get("nodes", [])
    today = datetime.now().strftime("%Y-%m-%d")

    tasks = []
    for node in nodes:
        content = node.get("content")
        if not content or content.get("state") != "OPEN":
            continue

        due_date = content.get("dueDate")
        priority = "normal"
        if due_date and due_date < today:
            priority = "high"

        tasks.append(TaskItem(
            title=content.get("title", "Untitled"),
            source="github",
            priority=priority,
            due_date=due_date or None,
            description=content.get("body", "") or "",
        ))

    return tasks