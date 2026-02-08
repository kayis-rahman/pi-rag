"""
Memory Store - SQLite storage for symbolic memory subsystem.

Design Principles (NON-NEGOTIABLE):
- Stores explicit, durable facts only
- Deterministic, auditable, and safe from hallucinations
- No embeddings, no vector DB
- Separates memory from chat history
- Safe to inject into future prompts

Every memory entry MUST have: scope, category, confidence, source
"""

import sqlite3
import json
import uuid
from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime
from pathlib import Path


class MemoryFact:
    """
    Represents a single memory fact.

    Attributes:
        id: Unique identifier (UUID)
        scope: Scope level (user | project | org | session)
        category: Category (preference | constraint | decision | fact)
        key: Unique identifier within scope
        value: JSON string with fact data
        confidence: Confidence level (0.0-1.0)
        source: Who created this fact (user | agent | tool)
        created_at: Creation timestamp
        updated_at: Last update timestamp
    """

    def __init__(
        self,
        id: Optional[str] = None,
        scope: str = "session",
        category: str = "fact",
        key: str = "",
        value: Any = "",
        confidence: float = 1.0,
        source: str = "agent",
        created_at: Optional[str] = None,
        updated_at: Optional[str] = None
    ):
        self.id = id or str(uuid.uuid4())
        self.scope = scope
        self.category = category
        self.key = key
        # Don't double-encode if already JSON string
        if isinstance(value, str):
            try:
                # Try to parse as JSON to check if it's already encoded
                json.loads(value)
                self.value = value
            except (json.JSONDecodeError, TypeError):
                # Not valid JSON, encode it
                self.value = json.dumps(value)
        else:
            self.value = json.dumps(value)
        self.confidence = max(0.0, min(1.0, confidence))  # Clamp to 0-1
        self.source = source
        self.created_at = created_at or datetime.utcnow().isoformat()
        self.updated_at = updated_at or datetime.utcnow().isoformat()

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary representation."""
        return {
            "id": self.id,
            "scope": self.scope,
            "category": self.category,
            "key": self.key,
            "value": json.loads(self.value) if self._is_json(self.value) else self.value,
            "confidence": self.confidence,
            "source": self.source,
            "created_at": self.created_at,
            "updated_at": self.updated_at
        }

    @staticmethod
    def _is_json(value: str) -> bool:
        """Check if string is valid JSON."""
        try:
            json.loads(value)
            return True
        except (json.JSONDecodeError, TypeError):
            return False


class MemoryStore:
    """
    SQLite-based memory storage with full CRUD operations.

    Features:
    - Deterministic operations (no probabilistic behavior)
    - Full audit trail via triggers
    - Conflict resolution (highest confidence wins)
    - Postgres-compatible schema
    - Transaction safety

    Example:
        >>> store = MemoryStore("./data/memory.db")
        >>> fact = MemoryFact(
        ...     scope="user",
        ...     category="preference",
        ...     key="output_format",
        ...     value="json",
        ...     confidence=0.9,
        ...     source="user"
        ... )
    """

    VALID_SCOPES = ["user", "project", "org", "session"]

    # Valid category values
    VALID_CATEGORIES = {"preference", "constraint", "decision", "fact"}

    # Valid source values
    VALID_SOURCES = {"user", "agent", "tool"}

    # Valid source values
    VALID_SOURCES = {"user", "agent", "tool"}

    def __init__(self, db_path: str = "./data/memory.db"):
        """
        Initialize memory store.

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
        # Read schema file if it exists, otherwise use inline schema
        schema_path = Path(__file__).parent.parent / "data" / "memory_db_schema.sql"

        with sqlite3.connect(self.db_path) as conn:
            if schema_path.exists():
                with open(schema_path, 'r') as f:
                    schema = f.read()
                conn.executescript(schema)
            else:
                # Inline schema as fallback
                conn.executescript(self._get_inline_schema())
            conn.commit()

    def _get_inline_schema(self) -> str:
        """Get inline database schema."""
        return """
        CREATE TABLE IF NOT EXISTS memory_facts (
            id TEXT PRIMARY KEY,
            scope TEXT NOT NULL,
            category TEXT NOT NULL,
            key TEXT NOT NULL,
            value TEXT NOT NULL,
            confidence REAL NOT NULL CHECK(confidence >= 0.0 AND confidence <= 1.0),
            source TEXT NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT unique_scope_key UNIQUE (scope, key)
        );

        CREATE INDEX IF NOT EXISTS idx_scope_key ON memory_facts(scope, key);
        CREATE INDEX IF NOT EXISTS idx_category_scope ON memory_facts(category, scope);

        CREATE TABLE IF NOT EXISTS memory_audit_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fact_id TEXT NOT NULL,
            operation TEXT NOT NULL,
            old_value TEXT,
            new_value TEXT NOT NULL,
            changed_by TEXT NOT NULL,
            changed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (fact_id) REFERENCES memory_facts(id) ON DELETE CASCADE
        );

        CREATE TRIGGER IF NOT EXISTS update_timestamp
        AFTER UPDATE ON memory_facts
        FOR EACH ROW
        BEGIN
            UPDATE memory_facts SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
        END;

        CREATE TRIGGER IF NOT EXISTS audit_insert
        AFTER INSERT ON memory_facts
        FOR EACH ROW
        BEGIN
            INSERT INTO memory_audit_log (fact_id, operation, old_value, new_value, changed_by, changed_at)
            VALUES (NEW.id, 'INSERT', NULL, NEW.value, NEW.source, CURRENT_TIMESTAMP);
        END;

        CREATE TRIGGER IF NOT EXISTS audit_update
        AFTER UPDATE ON memory_facts
        FOR EACH ROW
        BEGIN
            INSERT INTO memory_audit_log (fact_id, operation, old_value, new_value, changed_by, changed_at)
            VALUES (NEW.id, 'UPDATE', OLD.value, NEW.value, NEW.source, CURRENT_TIMESTAMP);
        END;

        CREATE TRIGGER IF NOT EXISTS audit_delete
        AFTER DELETE ON memory_facts
        FOR EACH ROW
        BEGIN
            INSERT INTO memory_audit_log (fact_id, operation, old_value, new_value, changed_by, changed_at)
            VALUES (OLD.id, 'DELETE', OLD.value, NULL, OLD.source, CURRENT_TIMESTAMP);
        END;
        """

    def _validate_fact(self, fact: MemoryFact) -> None:
        """Validate memory fact constraints."""
        # Validate project_id format (name-shortUUID or just name)
        if not self._is_valid_project_id(fact.scope):
            raise ValueError(
                f"Invalid project_id: {fact.scope}. "
                f"Must be in format 'name-shortUUID' or a valid project name."
            )

        if fact.category not in self.VALID_CATEGORIES:
            raise ValueError(f"Invalid category: {fact.category}. Must be one of {self.VALID_CATEGORIES}")

        if fact.source not in self.VALID_SOURCES:
            raise ValueError(f"Invalid source: {fact.source}. Must be one of {self.VALID_SOURCES}")

        if not fact.key:
            raise ValueError("Memory fact key cannot be empty")

        if fact.confidence < 0.0 or fact.confidence > 1.0:
            raise ValueError(f"Confidence must be between 0.0 and 1.0, got {fact.confidence}")
    
    @staticmethod
    def _is_valid_project_id(project_id: str) -> bool:
        """
        Validate project_id format (name-shortUUID or simple name).
        
        Accepts:
        - Simple names (alphanumeric, hyphens, underscores)
        - name-shortUUID format (e.g., "myapp-a1b2c3d4")
        
        Returns:
            True if valid, False otherwise
        """
        if not project_id or not isinstance(project_id, str):
            return False
        
        # Check length
        if len(project_id) < 1 or len(project_id) > 150:
            return False
        
        # Check for valid characters (alphanumeric, hyphens, underscores)
        import re
        if not re.match(r'^[a-zA-Z0-9_-]+$', project_id):
            return False
        
        return True
    
    def _validate_fact(self, fact: MemoryFact) -> None:
        """Validate memory fact constraints."""
        # Validate project_id format (name-shortUUID or just name)
        if not self._is_valid_project_id(fact.scope):
            raise ValueError(
                f"Invalid project_id: {fact.scope}. "
                f"Must be in format 'name-shortUUID' or a valid project name."
            )
    
    @staticmethod
    def _is_valid_project_id(project_id: str) -> bool:
        """
        Validate project_id format.
        
        Accepts:
        - Simple names (alphanumeric, hyphens, underscores)
        - name-shortUUID format (e.g., "myapp-a1b2c3d4")
        
        Returns:
            True if valid, False otherwise
        """
        if not project_id or not isinstance(project_id, str):
            return False
        
        # Check length
        if len(project_id) < 1 or len(project_id) > 150:
            return False
        
        # Check for valid characters (alphanumeric, hyphens, underscores)
        import re
        if not re.match(r'^[a-zA-Z0-9_-]+$', project_id):
            return False
        
        return True

    def store_memory(self, fact: MemoryFact) -> Optional[MemoryFact]:
        """
        Store a memory fact.

        If a fact with the same (scope, key) already exists, it will be
        updated only if the new confidence is higher than the existing one.

        Args:
            fact: MemoryFact to store

        Returns:
            Stored MemoryFact (with updated id/timestamps if needed), or None if error

        Raises:
            ValueError: If fact validation fails
        """
        self._validate_fact(fact)

        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()

            # Check if fact already exists
            cursor.execute(
                "SELECT id, confidence FROM memory_facts WHERE scope = ? AND key = ?",
                (fact.scope, fact.key)
            )
            existing = cursor.fetchone()

            if existing:
                existing_id, existing_confidence = existing

                # Only update if new confidence is higher
                if fact.confidence > existing_confidence:
                    cursor.execute(
                        """UPDATE memory_facts
                           SET category = ?, value = ?, confidence = ?, source = ?
                           WHERE id = ?""",
                        (fact.category, fact.value, fact.confidence, fact.source, existing_id)
                    )
                    fact.id = existing_id
                else:
                    # Return existing fact without modification
                    result = self.get_memory(existing_id)
                    if result is None:
                        # This should never happen, but handle it
                        raise RuntimeError(f"Failed to retrieve existing fact {existing_id}")
                    return result
            else:
                # Insert new fact
                cursor.execute(
                    """INSERT INTO memory_facts
                       (id, scope, category, key, value, confidence, source, created_at, updated_at)
                       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                    (fact.id, fact.scope, fact.category, fact.key,
                     fact.value, fact.confidence, fact.source,
                     fact.created_at, fact.updated_at)
                )

            conn.commit()

            # Return the stored fact
            result = self.get_memory(fact.id)
            if result is None:
                raise RuntimeError(f"Failed to retrieve stored fact {fact.id}")
            return result

    def update_memory(self, fact: MemoryFact) -> Optional[MemoryFact]:
        """
        Update an existing memory fact by ID.

        Args:
            fact: MemoryFact with updated values (id must exist)

        Returns:
            Updated MemoryFact, or None if error

        Raises:
            ValueError: If fact validation fails or id doesn't exist
        """
        self._validate_fact(fact)

        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()

            # Check if fact exists
            cursor.execute("SELECT id FROM memory_facts WHERE id = ?", (fact.id,))
            if not cursor.fetchone():
                raise ValueError(f"Memory fact with id {fact.id} not found")

            # Update fact
            cursor.execute(
                """UPDATE memory_facts
                   SET category = ?, key = ?, value = ?, confidence = ?, source = ?
                   WHERE id = ?""",
                (fact.category, fact.key, fact.value, fact.confidence, fact.source, fact.id)
            )

            conn.commit()

            result = self.get_memory(fact.id)
            if result is None:
                raise RuntimeError(f"Failed to retrieve updated fact {fact.id}")
            return result

    def query_memory(
        self,
        scope: Optional[str] = None,
        category: Optional[str] = None,
        key: Optional[str] = None,
        min_confidence: float = 0.0,
        source: Optional[str] = None
    ) -> List[MemoryFact]:
        """
        Query memory facts with optional filters.

        Args:
            scope: Filter by scope (optional)
            category: Filter by category (optional)
            key: Filter by key (optional, can use LIKE pattern)
            min_confidence: Minimum confidence threshold (default: 0.0)
            source: Filter by source (optional)

        Returns:
            List of matching MemoryFact objects
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()

            # Build query dynamically
            conditions = []
            params = []

            if scope:
                conditions.append("scope = ?")
                params.append(scope)

            if category:
                conditions.append("category = ?")
                params.append(category)

            if key:
                # Support both exact match and LIKE pattern
                if '%' in key or '_' in key:
                    conditions.append("key LIKE ?")
                else:
                    conditions.append("key = ?")
                params.append(key)

            conditions.append("confidence >= ?")
            params.append(min_confidence)

            if source:
                conditions.append("source = ?")
                params.append(source)

            where_clause = " AND ".join(conditions) if conditions else "1=1"

            cursor.execute(
                f"""SELECT id, scope, category, key, value, confidence, source, created_at, updated_at
                   FROM memory_facts WHERE {where_clause} ORDER BY confidence DESC, updated_at DESC""",
                params
            )

            rows = cursor.fetchall()

            return [
                MemoryFact(
                    id=row[0],
                    scope=row[1],
                    category=row[2],
                    key=row[3],
                    value=row[4],
                    confidence=row[5],
                    source=row[6],
                    created_at=row[7],
                    updated_at=row[8]
                )
                for row in rows
            ]

    def list_memory(self, scope: str) -> List[MemoryFact]:
        """
        List all memory facts for a given scope/project_id.
        
        Args:
            scope: Project ID (name-shortUUID format or project name)
        
        Returns:
            List of all MemoryFact objects in scope
        """
        if not self._is_valid_project_id(scope):
            raise ValueError(f"Invalid project_id: {scope}")

        return self.query_memory(scope=scope)

    def delete_memory(self, fact_id: str) -> bool:
        """
        Delete a memory fact by ID.

        Args:
            fact_id: ID of the fact to delete

        Returns:
            True if deleted, False if not found
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()

            cursor.execute("DELETE FROM memory_facts WHERE id = ?", (fact_id,))
            deleted = cursor.rowcount > 0
            conn.commit()

            return deleted

    def get_memory(self, fact_id: str) -> Optional[MemoryFact]:
        """
        Retrieve a memory fact by ID.

        Args:
            fact_id: ID of the fact to retrieve

        Returns:
            MemoryFact if found, None otherwise
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()

            cursor.execute(
                """SELECT id, scope, category, key, value, confidence, source, created_at, updated_at
                   FROM memory_facts WHERE id = ?""",
                (fact_id,)
            )

            row = cursor.fetchone()

            if not row:
                return None

            return MemoryFact(
                id=row[0],
                scope=row[1],
                category=row[2],
                key=row[3],
                value=row[4],
                confidence=row[5],
                source=row[6],
                created_at=row[7],
                updated_at=row[8]
            )

    def get_audit_log(self, fact_id: Optional[str] = None) -> List[Dict[str, Any]]:
        """
        Retrieve audit log entries.

        Args:
            fact_id: Optional fact ID to filter by

        Returns:
            List of audit log entries
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()

            if fact_id:
                cursor.execute(
                    """SELECT id, fact_id, operation, old_value, new_value, changed_by, changed_at
                       FROM memory_audit_log WHERE fact_id = ? ORDER BY changed_at DESC""",
                    (fact_id,)
                )
            else:
                cursor.execute(
                    """SELECT id, fact_id, operation, old_value, new_value, changed_by, changed_at
                       FROM memory_audit_log ORDER BY changed_at DESC LIMIT 100"""
                )

            rows = cursor.fetchall()

            return [
                {
                    "id": row[0],
                    "fact_id": row[1],
                    "operation": row[2],
                    "old_value": row[3],
                    "new_value": row[4],
                    "changed_by": row[5],
                    "changed_at": row[6]
                }
                for row in rows
            ]

    def get_stats(self) -> Dict[str, Any]:
        """
        Get memory store statistics.

        Returns:
            Dictionary with statistics
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()

            # Total facts by scope
            cursor.execute("""
                SELECT scope, COUNT(*) as count
                FROM memory_facts
                GROUP BY scope
            """)
            by_scope = {row[0]: row[1] for row in cursor.fetchall()}

            # Total facts by category
            cursor.execute("""
                SELECT category, COUNT(*) as count
                FROM memory_facts
                GROUP BY category
            """)
            by_category = {row[0]: row[1] for row in cursor.fetchall()}

            # Total facts
            cursor.execute("SELECT COUNT(*) FROM memory_facts")
            total_facts = cursor.fetchone()[0]

            # Average confidence
            cursor.execute("SELECT AVG(confidence) FROM memory_facts")
            avg_confidence = cursor.fetchone()[0] or 0.0

            return {
                "total_facts": total_facts,
                "by_scope": by_scope,
                "by_category": by_category,
                "average_confidence": round(avg_confidence, 3),
                "db_path": self.db_path
            }

    def close(self) -> None:
        """Close database connection (if using persistent connection pattern)."""
        # SQLite with sqlite3.connect() handles connections per method
        # This is a no-op but provided for API consistency
        pass


# Singleton instance
_memory_store: Optional[MemoryStore] = None


def get_memory_store(db_path: str = "./data/memory.db") -> MemoryStore:
    """
    Get or create the memory store singleton.

    Args:
        db_path: Path to SQLite database file

    Returns:
        MemoryStore instance
    """
    global _memory_store
    if _memory_store is None:
        _memory_store = MemoryStore(db_path)
    return _memory_store
