"""
Episodic Reader - Read episodic memory for planning and strategy advice.

Design Principles (NON-NEGOTIABLE):
- Episodic memory is ADVISORY, not authoritative
- Must be treated as advice, not instruction
- Never mandatory for planning
- Clearly marked as non-factual
- Cannot conflict with symbolic memory

Episodic Memory in Planning:
- Injected sparingly (limit to 3-5 most relevant episodes)
- Treated as "past agent lessons (advisory)"
- Planner may ignore it
- Clearly marked as experience, not fact

Safety Rules:
- Must NOT modify symbolic memory
- Must NOT be injected as fact
- Must NOT be blindly followed
- Must be deletable
- Must be explainable

Example injection:
"Past agent lessons (advisory, non-authoritative):
• For large repos, search filenames first.
• User prefers concise output over verbose explanations.

Note: These are lessons from experience, not guaranteed facts.
"
"""

import sqlite3
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta, timezone


class EpisodicReader:
    """
    Reader for episodic memory with planning-focused queries.

    Responsibilities:
    - Query episodes by relevance to current task
    - Format episodes as advisory context
    - Limit results to avoid context bloat
    - Clearly mark episodes as advisory, not factual

    Example:
        >>> reader = EpisodicReader("./data/episodic.db")
        >>> advisory_context = reader.get_advisory_context(
        ...     current_task="Find relevant code in large repository"
        ... )
        >>> # In production, use: logger.info(advisory_context)
        >>> # Here we show raw output for clarity
        >>> print(advisory_context)
    """

    # Section header for planning injection
    ADVISORY_HEADER = "PAST AGENT LESSONS (ADVISORY, NON-AUTHORITATIVE):"
    ADVISORY_DISCLAIMER = "Note: These are lessons from experience, not guaranteed facts. Use your judgment."

    # Maximum episodes to include in context
    MAX_EPISODES_IN_CONTEXT = 5

    def __init__(self, db_path: str = "./data/episodic.db"):
        """
        Initialize episodic reader.

        Args:
            db_path: Path to SQLite database file
        """
        self.db_path = db_path

    def get_relevant_episodes(
        self,
        task_description: str,
        min_confidence: float = 0.7,
        limit: int = 5
    ) -> List[Dict[str, Any]]:
        """
        Get episodes relevant to the current task.

        Args:
            task_description: Description of current task
            min_confidence: Minimum confidence threshold
            limit: Maximum number of episodes to return

        Returns:
            List of relevant episode dicts
        """
        # Simple keyword-based relevance matching
        # In production, could use embeddings or semantic search
        episodes = []

        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()

            # Extract keywords from task description
            keywords = self._extract_keywords(task_description)

            if not keywords:
                # If no keywords, return recent high-confidence episodes
                cursor.execute(
                    """SELECT id, situation, action, outcome, lesson, confidence, created_at
                       FROM episodic_memory
                       WHERE confidence >= ?
                       ORDER BY confidence DESC, created_at DESC LIMIT ?""",
                    (min_confidence, limit)
                )
            else:
                # Search for episodes with matching keywords
                # Match in lesson or situation
                keyword_conditions = []
                keyword_params = []

                for keyword in keywords:
                    keyword_conditions.append("lesson LIKE ?")
                    keyword_params.append(f"%{keyword}%")
                    keyword_conditions.append("situation LIKE ?")
                    keyword_params.append(f"%{keyword}%")

                # Combine with OR
                where_clause = " OR ".join(keyword_conditions)
                where_clause = f"({where_clause}) AND confidence >= ?"
                keyword_params.append(min_confidence)

                cursor.execute(
                    f"""SELECT id, situation, action, outcome, lesson, confidence, created_at
                       FROM episodic_memory
                       WHERE {where_clause}
                       ORDER BY confidence DESC, created_at DESC LIMIT ?""",
                    keyword_params + [limit]
                )

            rows = cursor.fetchall()

            for row in rows:
                episodes.append({
                    "id": row[0],
                    "situation": row[1],
                    "action": row[2],
                    "outcome": row[3],
                    "lesson": row[4],
                    "confidence": row[5],
                    "created_at": row[6],
                    "relevance_score": self._calculate_relevance(task_description, row[4])
                })

            # Sort by confidence and relevance
            episodes.sort(
                key=lambda e: (e["confidence"], e["relevance_score"]),
                reverse=True
            )

        return episodes[:limit]

    def get_advisory_context(
        self,
        task_description: str = "",
        min_confidence: float = 0.7,
        max_episodes: int = 5
    ) -> str:
        """
        Get episodic memory formatted as advisory context for planning.

        Args:
            task_description: Description of current task
            min_confidence: Minimum confidence threshold
            max_episodes: Maximum episodes to include

        Returns:
            Formatted advisory context string, or empty string if no episodes
        """
        episodes = self.get_relevant_episodes(
            task_description,
            min_confidence=min_confidence,
            limit=max_episodes
        )

        if not episodes:
            return ""

        # Format episodes as advisory bullet points
        lines = [self.ADVISORY_HEADER]

        for episode in episodes:
            lesson = episode["lesson"]
            confidence = episode["confidence"]
            created_days = self._get_days_ago(episode["created_at"])

            # Include only the lesson with confidence
            lines.append(f"• {lesson} (confidence: {confidence:.2f}, learned {created_days} days ago)")

        # Add disclaimer
        lines.append("\n" + self.ADVISORY_DISCLAIMER)

        return "\n".join(lines)

    def get_summary(self) -> Dict[str, Any]:
        """
        Get episodic memory summary statistics.

        Returns:
            Dictionary with summary statistics
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()

            # Total episodes
            cursor.execute("SELECT COUNT(*) FROM episodic_memory")
            total_episodes = cursor.fetchone()[0]

            # Average confidence
            cursor.execute("SELECT AVG(confidence) FROM episodic_memory")
            avg_confidence = cursor.fetchone()[0] or 0.0

            # Recent episodes (last 30 days)
            cursor.execute(
                """SELECT COUNT(*) FROM episodic_memory
                   WHERE datetime(created_at) >= datetime('now', '-30 days')"""
            )
            recent_episodes = cursor.fetchone()[0]

            # High confidence episodes
            cursor.execute(
                "SELECT COUNT(*) FROM episodic_memory WHERE confidence >= 0.8"
            )
            high_conf_episodes = cursor.fetchone()[0]

            return {
                "total_episodes": total_episodes,
                "average_confidence": round(avg_confidence, 3),
                "recent_episodes_30_days": recent_episodes,
                "high_confidence_episodes": high_conf_episodes,
                "db_path": self.db_path
            }

    def list_episodes_by_confidence(
        self,
        min_confidence: float = 0.0,
        max_confidence: float = 1.0,
        limit: int = 20
    ) -> List[Dict[str, Any]]:
        """
        List episodes by confidence range.

        Args:
            min_confidence: Minimum confidence
            max_confidence: Maximum confidence
            limit: Maximum episodes to return

        Returns:
            List of episode dicts
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()

            cursor.execute(
                """SELECT id, situation, action, outcome, lesson, confidence, created_at
                   FROM episodic_memory
                   WHERE confidence >= ? AND confidence <= ?
                   ORDER BY confidence DESC, created_at DESC LIMIT ?""",
                (min_confidence, max_confidence, limit)
            )

            rows = cursor.fetchall()

            return [
                {
                    "id": row[0],
                    "situation": row[1],
                    "action": row[2],
                    "outcome": row[3],
                    "lesson": row[4],
                    "confidence": row[5],
                    "created_at": row[6]
                }
                for row in rows
            ]

    def _extract_keywords(self, text: str) -> List[str]:
        """
        Extract keywords from text for relevance matching.

        Args:
            text: Text to extract keywords from

        Returns:
            List of keywords
        """
        if not text:
            return []

        # Simple keyword extraction
        # Remove common words and split
        common_words = {
            "the", "a", "an", "and", "or", "but", "in", "on", "at", "to",
            "for", "of", "with", "by", "from", "as", "is", "was", "are",
            "be", "been", "being", "have", "has", "had", "do", "does", "did",
            "will", "would", "could", "should", "may", "might", "must",
            "can", "this", "that", "these", "those", "it", "its", "they",
            "them", "their", "what", "which", "who", "whom", "where", "when",
            "why", "how", "help", "please", "i", "you", "me", "my", "your",
        }

        # Convert to lowercase and split
        words = text.lower().split()

        # Filter out common words and short words
        keywords = [
            word.strip(".,!?;:\"'()[]{}")
            for word in words
            if word not in common_words and len(word) > 3
        ]

        return keywords

    def _calculate_relevance(self, task: str, lesson: str) -> float:
        """
        Calculate relevance score between task and lesson.

        Args:
            task: Task description
            lesson: Episode lesson

        Returns:
            Relevance score (0.0-1.0)
        """
        task_keywords = set(self._extract_keywords(task))
        lesson_keywords = set(self._extract_keywords(lesson))

        if not task_keywords or not lesson_keywords:
            return 0.0

        # Calculate overlap
        overlap = task_keywords.intersection(lesson_keywords)

        # Jaccard similarity
        union = task_keywords.union(lesson_keywords)
        jaccard = len(overlap) / len(union) if union else 0.0

        return jaccard

    def _get_days_ago(self, created_at: str) -> int:
        """
        Calculate days ago from timestamp.

        Args:
            created_at: ISO format timestamp

        Returns:
            Number of days ago
        """
        try:
            created = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
            now = datetime.now(timezone.utc)
            delta = now - created
            return delta.days
        except (ValueError, AttributeError):
            return 0


def get_episodic_reader(db_path: str = "./data/episodic.db") -> EpisodicReader:
    """
    Get an episodic reader instance.

    Args:
        db_path: Path to SQLite database file

    Returns:
        EpisodicReader instance
    """
    return EpisodicReader(db_path)
