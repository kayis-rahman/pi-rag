"""Tests for GitHub Projects integration service."""

from unittest.mock import AsyncMock, MagicMock, patch

from app.models.briefing import TaskItem
from app.services.github import fetch_active_tasks


def _mock_httpx_client(resp_json: dict) -> AsyncMock:
    """Create a mock httpx.AsyncClient that returns the given JSON."""
    mock_resp = MagicMock()
    mock_resp.json.return_value = resp_json
    mock_resp.raise_for_status = MagicMock()

    mock_client = AsyncMock()
    mock_client.post.return_value = mock_resp
    mock_client.__aenter__.return_value = mock_client
    mock_client.__aexit__.return_value = None
    return mock_client


async def test_fetch_active_tasks_returns_tasks() -> None:
    """fetch_active_tasks returns list of TaskItem from GitHub Projects."""
    mock_response = {
        "data": {
            "projectV2": {
                "items": {
                    "nodes": [
                        {
                            "content": {
                                "typename": "Issue",
                                "title": "Fix login bug",
                                "body": "Users can't log in with SSO",
                                "state": "OPEN",
                                "labels": {"nodes": [{"name": "bug"}]},
                                "dueDate": "2026-07-20",
                                "assignee": {"login": "kayis-rahman"},
                            }
                        },
                        {
                            "content": {
                                "typename": "Issue",
                                "title": "Add API docs",
                                "body": "Document all endpoints",
                                "state": "OPEN",
                                "labels": {"nodes": [{"name": "docs"}]},
                                "dueDate": None,
                                "assignee": None,
                            }
                        },
                    ]
                }
            }
        }
    }

    mock_client = _mock_httpx_client(mock_response)

    with patch("app.services.github.httpx.AsyncClient", return_value=mock_client):
        result = await fetch_active_tasks()

    assert len(result) == 2
    assert isinstance(result[0], TaskItem)
    assert result[0].title == "Fix login bug"
    assert result[0].source == "github"
    assert result[0].due_date == "2026-07-20"
    assert result[1].title == "Add API docs"


async def test_fetch_active_tasks_empty_when_no_token() -> None:
    """When no GitHub token, returns empty list."""
    with patch("app.config.settings.GITHUB_TOKEN", ""):
        result = await fetch_active_tasks()

    assert result == []


async def test_fetch_active_tasks_empty_when_no_issues() -> None:
    """When GitHub returns no issues, returns empty list."""
    mock_client = _mock_httpx_client({"data": {"projectV2": {"items": {"nodes": []}}}})

    with patch("app.services.github.httpx.AsyncClient", return_value=mock_client):
        result = await fetch_active_tasks()

    assert result == []


async def test_fetch_active_tasks_sets_priority_for_overdue() -> None:
    """Overdue tasks get high priority."""
    mock_client = _mock_httpx_client({
        "data": {
            "projectV2": {
                "items": {
                    "nodes": [
                        {
                            "content": {
                                "typename": "Issue",
                                "title": "Overdue task",
                                "body": "",
                                "state": "OPEN",
                                "labels": {"nodes": []},
                                "dueDate": "2020-01-01",
                                "assignee": None,
                            }
                        },
                    ]
                }
            }
        }
    })

    with patch("app.services.github.httpx.AsyncClient", return_value=mock_client):
        result = await fetch_active_tasks()

    assert result[0].priority == "high"