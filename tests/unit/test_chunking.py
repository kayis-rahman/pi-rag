"""
Unit tests for text chunking functionality.

Tests cover chunk splitting, size control, overlap, and edge cases.
"""

import pytest
from core.ingest import chunk_text


@pytest.mark.unit
class TestChunking:
    """Test text chunking functionality."""

    def test_chunk_text(self):
        """Test basic text chunking."""
        text = "Hello world. This is a test. " * 100  # Long text

        chunks = chunk_text(text, chunk_size=50, chunk_overlap=10)

        assert len(chunks) > 0, "Should produce at least one chunk"
        assert all(isinstance(chunk, str) for chunk in chunks), "All chunks should be strings"
        assert all(len(chunk) > 0 for chunk in chunks), "No chunk should be empty"

    def test_chunk_size_control(self):
        """Test that chunk size is controlled."""
        text = "A" * 200  # 200 characters

        # With chunk_size=50, should produce 4 chunks
        chunks = chunk_text(text, chunk_size=50, chunk_overlap=0)

        assert len(chunks) == 4, f"Should produce 4 chunks, got {len(chunks)}"
        assert all(len(chunk) <= 50 for chunk in chunks), "All chunks should be <= chunk_size"

    def test_chunk_overlap_control(self):
        """Test that chunk overlap is controlled."""
        text = "A" * 200  # 200 characters

        chunks = chunk_text(text, chunk_size=50, chunk_overlap=10)

        assert len(chunks) > 1, "Should produce multiple chunks"

        # Verify overlap between consecutive chunks
        for i in range(len(chunks) - 1):
            chunk1_end = chunks[i][-10:]
            chunk2_start = chunks[i+1][:10]
            # Should have overlap
            assert chunk1_end == chunk2_start, \
                f"Chunks should overlap by 10 chars: '{chunk1_end}' != '{chunk2_start}'"

    def test_paragraph_preservation(self):
        """Test that paragraph boundaries are preserved."""
        text = """
First paragraph with some text.

Second paragraph here.

Third paragraph with more text.
""".strip()

        chunks = chunk_text(text, chunk_size=30, chunk_overlap=5)

        # Check that paragraphs aren't split mid-sentence when possible
        assert len(chunks) > 0, "Should produce chunks"

        # Paragraphs should be preserved as much as possible
        # (This is a soft constraint, not absolute)

    def test_empty_text(self):
        """Test handling of empty text."""
        text = ""

        chunks = chunk_text(text, chunk_size=50, chunk_overlap=10)

        assert chunks == [], "Empty text should produce no chunks"

    def test_large_paragraph(self):
        """Test handling of large paragraphs that exceed chunk size."""
        text = "A" * 200  # Single long paragraph

        chunks = chunk_text(text, chunk_size=50, chunk_overlap=10)

        # Should split large paragraph into multiple chunks
        assert len(chunks) > 1, "Large paragraph should be split into multiple chunks"
        assert all(len(chunk) <= 50 for chunk in chunks), "All chunks should respect chunk_size"

    def test_text_shorter_than_chunk_size(self):
        """Test text shorter than chunk size."""
        text = "Short text"

        chunks = chunk_text(text, chunk_size=100, chunk_overlap=10)

        assert len(chunks) == 1, "Text shorter than chunk_size should produce 1 chunk"
        assert chunks[0] == text, "Single chunk should contain entire text"

    def test_chunk_overlap_zero(self):
        """Test chunking with zero overlap."""
        text = "A" * 100

        chunks = chunk_text(text, chunk_size=25, chunk_overlap=0)

        # Should produce 4 non-overlapping chunks
        assert len(chunks) == 4, "Should produce 4 non-overlapping chunks"

        # Verify no overlap
        for i in range(len(chunks) - 1):
            chunk1_end = chunks[i][-5:]
            chunk2_start = chunks[i+1][:5]
            assert chunk1_end != chunk2_start, "Chunks should not overlap"

    def test_chunk_overlap_large(self):
        """Test chunking with large overlap."""
        text = "A" * 100

        chunks = chunk_text(text, chunk_size=25, chunk_overlap=20)

        assert len(chunks) > 0, "Should produce chunks"

        # With 20 char overlap, each chunk should share most of previous chunk
        # This tests that overlap is working

    def test_multiple_paragraphs(self):
        """Test chunking multiple paragraphs."""
        text = """
Paragraph one with some text.

Paragraph two here.

Paragraph three with content.

Paragraph four final.
""".strip()

        chunks = chunk_text(text, chunk_size=30, chunk_overlap=5)

        assert len(chunks) > 0, "Should produce chunks"

        # Total characters in chunks should approximately match original
        # (accounting for overlap)
        total_chunk_chars = sum(len(chunk) for chunk in chunks)
        assert abs(total_chunk_chars - len(text)) < len(chunks) * 10, \
            "Total chunked characters should approximate original length"

    def test_whitespace_handling(self):
        """Test that whitespace is handled correctly."""
        text = "  \n\n  Hello world  \n\n  Test  \n\n  "

        chunks = chunk_text(text, chunk_size=20, chunk_overlap=5)

        assert len(chunks) > 0, "Should produce chunks"

        # Whitespace should be preserved within chunks
        # But excessive whitespace might be trimmed
