"""
Episodic Store - SQLite storage for agent experience and lessons.

Design Principles (NON-NEGOTIABLE):
- Stores agent experience, NOT knowledge or facts
- Stores lessons, NOT raw logs
- Postgres-compatible schema
- Deterministic and auditable
- Must NOT conflict with symbolic memory
- Optional and non-authoritative

Every episode MUST have:
- situation: What the agent faced
- action: What it did
- outcome: success/failure
- lesson: Abstracted strategy
- confidence: 0.0-1.0

Episodic memory boundaries:
- CANNOT assert facts (use symbolic memory)
- CANNOT override decisions
- CANNOT change preferences
- CAN provide strategy advice
- CAN improve planning
"""

import sqlite3
import json
import uuid
from typing import List, Dict, Any, Optional, Tuple, Union
from datetime import datetime, timezone
from pathlib import Path


class Episode:
    """
    Represents a single agent learning episode.

    Attributes:
        id: Unique identifier (UUID)
        situation: What the agent faced (context)
        action: What the agent did (action taken)
        outcome: Result of the action (success/failure)
        lesson: Abstracted strategy (what was learned)
        confidence: Confidence level (0.0-1.0)
        created_at: Creation timestamp
    """

    def __init__(
        self,
        id: Optional[str] = None,
        project_id: str = "",
        situation: str = "",
        action: str = "",
        outcome: str = "",
        lesson: str = "",
        confidence: float = 0.5,
        created_at: Optional[str] = None
    ):
        self.id = id or str(uuid.uuid4())
        self.project_id = project_id  # <-- NEW
        self.situation = situation
        self.action = action
        self.outcome = outcome
        self.lesson = lesson
        self.confidence = max(0.0, min(1.0, confidence))  # Clamp to 0-1
        self.created_at = created_at or datetime.now(timezone.utc).isoformat()
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary representation."""
        return {
            "id": self.id,
            "project_id": self.project_id,  # <-- NEW
            "situation": self.situation,
            "action": self.action,
            "outcome": self.outcome,
            "lesson": self.lesson,
            "confidence": self.confidence,
            "created_at": self.created_at
        }

    def validate(self) -> bool:
        """
        Validate episode structure and content.

        Returns:
            True if valid, False otherwise
        """
        # Check required fields
        if not self.situation or not self.action or not self.outcome or not self.lesson:
            return False

        # Check lesson is not raw data
        # Episode should abstract, not just copy input
        if len(self.lesson) > 1000:
            return False  # Lesson too verbose, likely not abstracted

        # Ensure lesson is abstract, not situational
        lesson_lower = self.lesson.lower()
        situation_words = set(self.situation.lower().split())
        lesson_words = set(lesson_lower.split())

        # Lesson should not simply repeat situation
        if situation_words and len(lesson_words.intersection(situation_words)) > len(lesson_words) * 0.7:
            return False

        return True


class EpisodicStore:
    """
    SQLite-based episodic memory storage with full CRUD operations.

    Features:
    - Deterministic operations (no probabilistic behavior)
    - Postgres-compatible schema
    - Transaction safety
    - Controlled growth (no auto-persistence)
    - Must not conflict with symbolic memory

    Example:
        >>> store = EpisodicStore("./data/episodic.db")
        >>> episode = Episode(
        ...     situation="Large repository with unclear entry point",
        ...     action="Searched filenames before reading files",
        ...     outcome="Found relevant code quickly",
        ...     lesson="For large repos, perform keyword search before file traversal",
        ...     confidence=0.85
        ... )
        >>> store.store_episode(episode)
    """

    def __init__(self, db_path: str = "./data/episodic.db"):
        """
        Initialize episodic store.

        Args:
            db_path: Path to SQLite database file
        """
        self.db_path = db_path
        self._ensure_db_directory()
        self._init_db()

    def _ensure_db_directory(self) -> None:
        """Ensure database directory exists."""
        Path(self.db_path).parent.mkdir(parents=True, exist_ok=True)

    def _init_db(self) -> None:
        """Initialize database schema."""
        schema = self._get_schema()

        with sqlite3.connect(self.db_path) as conn:
            conn.executescript(schema)
            conn.commit()

    def _get_schema(self) -> str:
        """Get database schema."""
        return """
        CREATE TABLE IF NOT EXISTS episodic_memory (
            id TEXT PRIMARY KEY,
            project_id TEXT,
            situation TEXT NOT NULL,
            action TEXT NOT NULL,
            outcome TEXT NOT NULL,
            lesson TEXT NOT NULL,
            confidence REAL NOT NULL CHECK(confidence >= 0.0 AND confidence <= 1.0),
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );

        CREATE INDEX IF NOT EXISTS idx_project_id ON episodic_memory(project_id);
        CREATE INDEX IF NOT EXISTS idx_lesson ON episodic_memory(lesson);
        CREATE INDEX IF NOT EXISTS idx_confidence ON episodic_memory(confidence DESC);
        CREATE INDEX IF NOT EXISTS idx_created_at ON episodic_memory(created_at DESC);
        CREATE INDEX IF NOT EXISTS idx_situation ON episodic_memory(situation);

        -- View: recent_high_confidence_episodes
        -- Most recent episodes with high confidence
        CREATE VIEW IF NOT EXISTS recent_high_confidence_episodes AS
        SELECT
            id, project_id, situation, action, outcome, lesson, confidence, created_at
        FROM episodic_memory
        WHERE confidence >= 0.7
        ORDER BY created_at DESC
        LIMIT 50;
        """

    def store_episode(self, episode: Episode) -> Optional[Episode]:
        """
        Store an episode (explicit write only - no automatic persistence).

        Args:
            episode: Episode to store

        Returns:
            Stored Episode, or None if validation fails

        Raises:
            ValueError: If episode validation fails
        """
        # Validate episode before storage
        if not episode.validate():
            raise ValueError("Episode validation failed: lesson not abstracted or missing required fields")

        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()

            # Insert episode
            cursor.execute(
                """INSERT INTO episodic_memory
                   (id, project_id, situation, action, outcome, lesson, confidence, created_at)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
                (episode.id, episode.project_id, episode.situation, episode.action, episode.outcome,
                 episode.lesson, episode.confidence, episode.created_at)
            )

            conn.commit()

            # Return the stored episode
            result = self.get_episode(episode.id)
            if result is None:
                raise RuntimeError(f"Failed to retrieve stored episode {episode.id}")
            return result

    def get_episode(self, episode_id: str) -> Optional[Episode]:
        """
        Retrieve an episode by ID.

        Args:
            episode_id: ID of the episode to retrieve

        Returns:
            Episode if found, None otherwise
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()

            cursor.execute(
                """SELECT id, project_id, situation, action, outcome, lesson, confidence, created_at
                   FROM episodic_memory WHERE id = ?""",
                (episode_id,)
            )
            
            row = cursor.fetchone()
            
            if not row:
                return None
            
            return Episode(
                id=row[0],
                project_id=row[1],
                situation=row[2],
                action=row[3],
                outcome=row[4],
                lesson=row[5],
                confidence=row[6],
                created_at=row[7]
            )

    def query_episodes(
        self,
        project_id: str,
        lesson: Optional[str] = None,
        min_confidence: float = 0.0,
        situation_contains: Optional[str] = None,
        limit: int = 10
    ) -> List[Episode]:
        """
        Query episodes with optional filters.
        
        Args:
            project_id: Project identifier to filter by
            lesson: Filter by lesson text (optional, can use LIKE pattern)
            min_confidence: Minimum confidence threshold (default: 0.0)
            situation_contains: Filter by situation text (optional)
            limit: Maximum number of results (default: 10)
        
        Returns:
            List of matching Episode objects
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()

            # Build query dynamically
            conditions = ["project_id = ?"]
            params: List[Any] = [project_id]  # Allow any type for SQLite params
            
            if lesson:
                # Support both exact match and LIKE pattern
                if '%' in lesson or '_' in lesson:
                    conditions.append("lesson LIKE ?")
                else:
                    conditions.append("lesson = ?")
                params.append(lesson)
            
            conditions.append("confidence >= ?")
            params.append(float(min_confidence))
            
            if situation_contains:
                conditions.append("situation LIKE ?")
                params.append(f"%{situation_contains}%")
            
            where_clause = " AND ".join(conditions) if conditions else "1=1"

            cursor.execute(
                f"""SELECT id, project_id, situation, action, outcome, lesson, confidence, created_at
                   FROM episodic_memory WHERE {where_clause}
                   ORDER BY confidence DESC, created_at DESC LIMIT ?""",
                params + [limit]
            )

            rows = cursor.fetchall()

            return [
                Episode(
                    id=row[0],
                    project_id=row[1],
                    situation=row[2],
                    action=row[3],
                    outcome=row[4],
                    lesson=row[5],
                    confidence=row[6],
                    created_at=row[7]
                )
                for row in rows
            ]

    def list_recent_episodes(
        self,
        project_id: str = "session",
        days: int = 30,
        min_confidence: float = 0.5,
        limit: int = 20
    ) -> List[Episode]:
        """
        List recent episodes within a time range.

        Args:
            project_id: Project identifier to filter by
            days: Number of days to look back (default: 30)
            min_confidence: Minimum confidence threshold
            limit: Maximum number of results

        Returns:
            List of recent Episode objects
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()

            cursor.execute(
                """SELECT id, project_id, situation, action, outcome, lesson, confidence, created_at
                   FROM episodic_memory
                   WHERE project_id = ?
                   AND date(created_at) >= date('now', '-' || ? || ' days')
                   AND confidence >= ?
                   ORDER BY confidence DESC, created_at DESC LIMIT ?""",
                (project_id, days, min_confidence, limit)
            )

            rows = cursor.fetchall()

            return [
                Episode(
                    id=row[0],
                    project_id=row[1],
                    situation=row[2],
                    action=row[3],
                    outcome=row[4],
                    lesson=row[5],
                    confidence=row[6],
                    created_at=row[7]
                )
                for row in rows
            ]

    def delete_episode(self, episode_id: str) -> bool:
        """
        Delete an episode by ID.

        Args:
            episode_id: ID of the episode to delete

        Returns:
            True if deleted, False if not found
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()

            cursor.execute("DELETE FROM episodic_memory WHERE id = ?", (episode_id,))
            deleted = cursor.rowcount > 0
            conn.commit()

            return deleted

    def get_stats(self) -> Dict[str, Any]:
        """
        Get episodic store statistics.

        Returns:
            Dictionary with statistics
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()

            # Total episodes
            cursor.execute("SELECT COUNT(*) FROM episodic_memory")
            total_episodes = cursor.fetchone()[0]

            # Average confidence
            cursor.execute("SELECT AVG(confidence) FROM episodic_memory")
            avg_confidence = cursor.fetchone()[0] or 0.0

            # High confidence episodes (>= 0.7)
            cursor.execute("SELECT COUNT(*) FROM episodic_memory WHERE confidence >= 0.7")
            high_conf_count = cursor.fetchone()[0]

            # Episodes by confidence buckets
            cursor.execute("""
                SELECT
                    CASE
                        WHEN confidence >= 0.8 THEN 'high'
                        WHEN confidence >= 0.5 THEN 'medium'
                        ELSE 'low'
                    END as bucket,
                    COUNT(*) as count
                FROM episodic_memory
                GROUP BY bucket
            """)
            by_confidence = {row[0]: row[1] for row in cursor.fetchall()}

            # Oldest and newest episodes
            cursor.execute("SELECT MIN(created_at), MAX(created_at) FROM episodic_memory")
            oldest_newest = cursor.fetchone()

            return {
                "total_episodes": total_episodes,
                "average_confidence": round(avg_confidence, 3),
                "high_confidence_episodes": high_conf_count,
                "by_confidence": by_confidence,
                "oldest_episode": oldest_newest[0],
                "newest_episode": oldest_newest[1],
                "db_path": self.db_path
            }

    def cleanup_old_episodes(self, days: int = 90, min_confidence: float = 0.5) -> int:
        """
        Cleanup old, low-confidence episodes to prevent memory bloat.

        Args:
            days: Remove episodes older than this many days
            min_confidence: Only remove episodes with confidence below this threshold

        Returns:
            Number of episodes deleted
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()

            cursor.execute(
                """DELETE FROM episodic_memory
                   WHERE datetime(created_at) < datetime('now', '-' || ? || ' days')
                   AND confidence < ?""",
                (days, min_confidence)
            )

            deleted_count = cursor.rowcount
            conn.commit()

            return deleted_count


# Singleton instance
_episodic_store: Optional[EpisodicStore] = None


def get_episodic_store(db_path: str = "./data/episodic.db") -> EpisodicStore:
    """
    Get or create the episodic store singleton.

    Args:
        db_path: Path to SQLite database file

    Returns:
        EpisodicStore instance
    """
    global _episodic_store
    if _episodic_store is None:
        _episodic_store = EpisodicStore(db_path)
    return _episodic_store
