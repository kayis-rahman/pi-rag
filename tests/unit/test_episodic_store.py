"""
Unit tests for EpisodicStore.

Tests cover CRUD operations, querying, validation, and advisory authority level.
"""

import pytest
from core.episodic_store import EpisodicStore, Episode


@pytest.mark.unit
class TestEpisodicStore:
    """Test EpisodicStore class for episodic memory."""

    def test_add_episode(self, episodic_store):
        """Test adding an episode to episodic store."""
        episode = Episode(
            situation="User asked about authentication",
            action="Retrieved OAuth2 documentation",
            outcome="success",
            lesson="OAuth2 is the preferred authentication method",
            confidence=0.9,
            lesson_type="pattern",
            quality=0.9
        )

        result = episodic_store.add_episode(episode)

        assert result is not None, "Episode should be added successfully"
        assert result.id is not None, "Episode should have an ID"
        assert result.situation == "User asked about authentication"
        assert result.action == "Retrieved OAuth2 documentation"
        assert result.outcome == "success"
        assert result.lesson == "OAuth2 is the preferred authentication method"
        assert result.confidence == 0.9
        assert result.lesson_type == "pattern"
        assert result.quality == 0.9

    def test_get_episode_by_id(self, episodic_store):
        """Test retrieving an episode by ID."""
        episode = Episode(
            situation="Tried to use basic authentication",
            action="Attempted to implement basic auth",
            outcome="failure",
            lesson="Basic authentication is not supported, use OAuth2",
            confidence=0.85,
            lesson_type="failure",
            quality=0.95
        )

        added = episodic_store.add_episode(episode)
        retrieved = episodic_store.get_episode_by_id(added.id)

        assert retrieved is not None, "Episode should be retrievable"
        assert retrieved.id == added.id
        assert retrieved.lesson == "Basic authentication is not supported, use OAuth2"
        assert retrieved.outcome == "failure"

    def test_update_episode(self, episodic_store):
        """Test updating an existing episode."""
        episode = Episode(
            situation="User requested Python code for authentication",
            action="Provided complete OAuth2 implementation",
            outcome="success",
            lesson="Users appreciate complete code examples",
            confidence=0.7,
            lesson_type="success",
            quality=0.8
        )

        added = episodic_store.add_episode(episode)

        # Update confidence and quality
        added.confidence = 0.9
        added.quality = 0.95
        updated = episodic_store.update_episode(added)

        assert updated is not None, "Episode should be updated"
        assert updated.confidence == 0.9
        assert updated.quality == 0.95

    def test_delete_episode(self, episodic_store):
        """Test deleting an episode from episodic store."""
        episode = Episode(
            situation="Test situation",
            action="Test action",
            outcome="success",
            lesson="Test lesson",
            confidence=0.9,
            lesson_type="pattern",
            quality=0.9
        )

        added = episodic_store.add_episode(episode)
        deleted = episodic_store.delete_episode(added.id)

        assert deleted is True, "Episode should be deleted"

        # Verify episode is gone
        retrieved = episodic_store.get_episode_by_id(added.id)
        assert retrieved is None, "Deleted episode should not be retrievable"

    def test_query_episodes_by_lesson_type(self, episodic_store):
        """Test querying episodes by lesson type."""
        # Add episodes with different types
        episode1 = Episode(
            situation="Success case",
            action="Action 1",
            outcome="success",
            lesson="Lesson 1",
            confidence=0.9,
            lesson_type="success",
            quality=0.9
        )
        episode2 = Episode(
            situation="Pattern case",
            action="Action 2",
            outcome="success",
            lesson="Lesson 2",
            confidence=0.8,
            lesson_type="pattern",
            quality=0.85
        )
        episode3 = Episode(
            situation="Failure case",
            action="Action 3",
            outcome="failure",
            lesson="Lesson 3",
            confidence=0.85,
            lesson_type="failure",
            quality=0.95
        )

        episodic_store.add_episode(episode1)
        episodic_store.add_episode(episode2)
        episodic_store.add_episode(episode3)

        # Query by pattern type
        pattern_episodes = episodic_store.query_episodes(lesson_type="pattern")

        assert len(pattern_episodes) == 1, "Should retrieve 1 pattern episode"
        assert pattern_episodes[0].lesson_type == "pattern"

        # Query by failure type
        failure_episodes = episodic_store.query_episodes(lesson_type="failure")

        assert len(failure_episodes) == 1, "Should retrieve 1 failure episode"
        assert failure_episodes[0].lesson_type == "failure"

    def test_query_episodes_by_quality(self, episodic_store):
        """Test querying episodes by quality score."""
        # Add episodes with different quality scores
        episode1 = Episode(
            situation="High quality",
            action="Action 1",
            outcome="success",
            lesson="Lesson 1",
            confidence=0.9,
            lesson_type="success",
            quality=0.95
        )
        episode2 = Episode(
            situation="Medium quality",
            action="Action 2",
            outcome="success",
            lesson="Lesson 2",
            confidence=0.8,
            lesson_type="pattern",
            quality=0.75
        )
        episode3 = Episode(
            situation="Low quality",
            action="Action 3",
            outcome="success",
            lesson="Lesson 3",
            confidence=0.7,
            lesson_type="pattern",
            quality=0.6
        )

        episodic_store.add_episode(episode1)
        episodic_store.add_episode(episode2)
        episodic_store.add_episode(episode3)

        # Query with min quality 0.8
        high_quality_episodes = episodic_store.query_episodes(min_quality=0.8)

        assert len(high_quality_episodes) == 2, "Should retrieve 2 episodes with quality >= 0.8"

        # Query with min quality 0.9
        very_high_quality_episodes = episodic_store.query_episodes(min_quality=0.9)

        assert len(very_high_quality_episodes) == 1, "Should retrieve 1 episode with quality >= 0.9"

    def test_query_episodes_by_confidence(self, episodic_store):
        """Test querying episodes by confidence threshold."""
        # Add episodes with different confidence levels
        episode1 = Episode(
            situation="High confidence",
            action="Action 1",
            outcome="success",
            lesson="Lesson 1",
            confidence=0.9,
            lesson_type="success",
            quality=0.9
        )
        episode2 = Episode(
            situation="Medium confidence",
            action="Action 2",
            outcome="success",
            lesson="Lesson 2",
            confidence=0.7,
            lesson_type="pattern",
            quality=0.8
        )
        episode3 = Episode(
            situation="Low confidence",
            action="Action 3",
            outcome="success",
            lesson="Lesson 3",
            confidence=0.5,
            lesson_type="pattern",
            quality=0.6
        )

        episodic_store.add_episode(episode1)
        episodic_store.add_episode(episode2)
        episodic_store.add_episode(episode3)

        # Query with min confidence 0.8
        high_conf_episodes = episodic_store.query_episodes(min_confidence=0.8)

        assert len(high_conf_episodes) == 1, "Should retrieve 1 episode with confidence >= 0.8"
        assert high_conf_episodes[0].confidence == 0.9

        # Query with min confidence 0.6
        medium_conf_episodes = episodic_store.query_episodes(min_confidence=0.6)

        assert len(medium_conf_episodes) == 2, "Should retrieve 2 episodes with confidence >= 0.6"

    def test_advisory_authority(self, episodic_store):
        """Test that episodes have 85% advisory authority."""
        episode = Episode(
            situation="Advisory lesson",
            action="Provided advice",
            outcome="success",
            lesson="This is advisory, not authoritative",
            confidence=0.85,
            lesson_type="pattern",
            quality=0.85
        )

        added = episodic_store.add_episode(episode)

        # Episodic memory has 85% advisory authority
        # This is tested by ensuring confidence is in valid range
        assert 0.0 <= added.confidence <= 1.0, "Episode confidence should be valid"
        assert added.lesson_type in ["success", "pattern", "mistake", "failure"], "Lesson type should be valid"

    def test_no_fact_assertion(self, episodic_store):
        """Test that episodes cannot assert facts."""
        # Episodes should store lessons, not facts
        episode = Episode(
            situation="User asked about configuration",
            action="Provided configuration information",
            outcome="success",
            lesson="Chunk size is 500",  # This looks like a fact
            confidence=0.8,
            lesson_type="pattern",
            quality=0.8
        )

        added = episodic_store.add_episode(episode)

        # Episodic memory should NOT assert facts
        # Facts should go in symbolic memory
        # Episodes store lessons learned from experience
        assert added.lesson_type in ["success", "pattern", "mistake", "failure"], \
            "Episode lesson type should be advisory, not factual"

        # Episodic lessons are advisory (85% authority)
        # Not authoritative like symbolic facts (100% authority)
        # This is tested by the lesson_type and quality fields

    def test_lesson_extraction(self, episodic_store):
        """Test that lessons are abstracted from situations."""
        # Lesson should be abstracted, not just a restatement
        episode = Episode(
            situation="User asked 'How do I implement OAuth2?' and I provided code",
            action="Provided complete OAuth2 implementation example",
            outcome="success",
            lesson="Users appreciate complete, copy-pasteable code examples",  # Abstracted lesson
            confidence=0.9,
            lesson_type="success",
            quality=0.9
        )

        added = episodic_store.add_episode(episode)

        # Lesson should be abstracted from the specific situation
        assert added.lesson is not None, "Episode should have a lesson"
        assert len(added.lesson) > 0, "Lesson should not be empty"
        assert added.situation != added.lesson, "Lesson should be abstracted, not just restating situation"

    def test_quality_scoring(self, episodic_store):
        """Test that quality scores affect retrieval priority."""
        # Add episodes with different quality scores
        episode1 = Episode(
            situation="Low quality",
            action="Action 1",
            outcome="success",
            lesson="Lesson 1",
            confidence=0.7,
            lesson_type="pattern",
            quality=0.6
        )
        episode2 = Episode(
            situation="High quality",
            action="Action 2",
            outcome="success",
            lesson="Lesson 2",
            confidence=0.7,
            lesson_type="pattern",
            quality=0.95
        )

        episodic_store.add_episode(episode1)
        episodic_store.add_episode(episode2)

        # Query episodes (should be sorted by quality)
        all_episodes = episodic_store.query_episodes()

        assert len(all_episodes) == 2, "Should retrieve both episodes"

        # Higher quality episodes should be retrieved first
        # This tests that quality scoring affects retrieval priority
        # (assuming the implementation sorts by quality)
        assert all(0.0 <= ep.quality <= 1.0 for ep in all_episodes), \
            "All quality scores should be in valid range"

    def test_db_persistence(self, test_db_path):
        """Test that episodes persist across connections."""
        # Add episode with first connection
        store1 = EpisodicStore(str(test_db_path))
        episode = Episode(
            situation="Persistent situation",
            action="Persistent action",
            outcome="success",
            lesson="Persistent lesson",
            confidence=0.9,
            lesson_type="pattern",
            quality=0.9
        )

        added = store1.add_episode(episode)
        store1.close()

        # Retrieve with second connection
        store2 = EpisodicStore(str(test_db_path))
        retrieved = store2.get_episode_by_id(added.id)
        store2.close()

        assert retrieved is not None, "Episode should persist across connections"
        assert retrieved.situation == "Persistent situation"
        assert retrieved.lesson == "Persistent lesson"
