"""
Unit tests for LearningExtractor module.

Tests cover LLM-based episode extraction, fact extraction from code,
and rule-based fallback mechanisms.
"""

import pytest
from core.learning_extractor import LearningExtractor


class TestLearningExtractor:
    """Test LearningExtractor class."""
    
    @pytest.fixture
    def extractor(self):
        """Create LearningExtractor instance for testing."""
        # Mock model manager
        class MockModelManager:
            def chat_completion(self, model_name, messages, temperature, max_tokens):
                return {
                    "choices": [{
                        "message": {
                            "content": '{"situation": "Test situation", "action": "Test action", "outcome": "success", "lesson": "Test lesson", "confidence": 0.75}'
                        }
                    }]
                }
        
        return LearningExtractor(model_manager=MockModelManager())
    
    def test_extract_episode_from_task_success(self, extractor):
        """Test successful task completion extraction."""
        task = {
            "type": "task_completion",
            "situation": "User needed to find auth implementation",
            "action": "Searched semantic memory and located auth module",
            "outcome": "success",
            "confidence": 0.8
        }
        
        result = extractor.extract_episode_from_task(task)
        
        assert result is not None
        assert result["situation"] == "User needed to find auth implementation"
        assert result["action"] == "Searched semantic memory and located auth module"
        assert result["outcome"] == "success"
        assert result["lesson"] == "Test lesson"
        assert result["confidence"] == 0.75
    
    def test_extract_episode_from_task_low_confidence(self, extractor):
        """Test that low confidence tasks don't extract."""
        task = {
            "type": "task_completion",
            "situation": "Simple file edit",
            "action": "Modified file",
            "outcome": "success",
            "confidence": 0.5
        }
        
        result = extractor.extract_episode_from_task(task)
        
        assert result is None  # Low confidence rejected
    
    def test_extract_episode_from_task_obvious_success(self, extractor):
        """Test that obvious success doesn't extract."""
        task = {
            "type": "task_completion",
            "situation": "Successfully edited file",
            "action": "Saved file",
            "outcome": "success",
            "confidence": 0.9
        }
        
        result = extractor.extract_episode_from_task(task)
        
        assert result is None  # Obvious success rejected
    
    def test_extract_episode_from_task_failure(self, extractor):
        """Test that failed tasks don't extract."""
        task = {
            "type": "task_completion",
            "situation": "Failed to edit file",
            "action": "Edit failed",
            "outcome": "error",
            "confidence": 0.8
        }
        
        result = extractor.extract_episode_from_task(task)
        
        assert result is None  # Failure doesn't extract
    
    def test_extract_facts_from_code_imports(self, extractor):
        """Test fact extraction from import statements."""
        file_content = '''
import os
import json
from typing import Dict, Any, Optional
'''
        
        facts = extractor.extract_facts_from_code("/test.py", file_content)
        
        assert len(facts) >= 1
        assert any(f["key"] == "dependencies" for f in facts)
        assert "python" in facts[0]["value"]["packages"]
        assert "json" in facts[0]["value"]["packages"]
    
    def test_extract_facts_from_code_fastapi(self, extractor):
        """Test fact extraction from FastAPI framework."""
        file_content = '''
from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
'''
        
        facts = extractor.extract_facts_from_code("/app.py", file_content)
        
        assert len(facts) >= 1
        assert any(f["key"] == "framework" for f in facts)
        assert "fastapi" in facts[0]["value"]["framework"]
    
    def test_extract_facts_from_code_react(self, extractor):
        """Test fact extraction from React framework."""
        file_content = '''
import React from 'react'
import { useState, useEffect } from 'react'
'''
        
        facts = extractor.extract_facts_from_code("/App.js", file_content)
        
        assert len(facts) >= 1
        assert any(f["key"] == "framework" for f in facts)
        assert "react" in facts[0]["value"]["framework"]
    
    def test_extract_facts_from_code_api_endpoints(self, extractor):
        """Test fact extraction from API endpoints."""
        file_content = '''
@app.get("/users/{user_id}")
@app.post("/users")
@app.put("/users/{user_id}")
@app.delete("/users/{user_id}")
@app.patch("/users/{user_id}")
'''
        
        facts = extractor.extract_facts_from_code("/api.py", file_content)
        
        assert len(facts) >= 1
        assert facts[-1]["key"] == "api_endpoints"
        assert len(facts[-1]["value"]["endpoints"]) == 5
    
    def test_extract_facts_from_code_no_imports(self, extractor):
        """Test that code without imports doesn't extract facts."""
        file_content = '''
def hello():
    print("Hello world")
'''
        
        facts = extractor.extract_facts_from_code("/test.py", file_content)
        
        # Only framework facts if applicable
        assert len([f for f in facts if f["key"] == "dependencies"]) == 0
    
    def test_extract_episode_from_pattern_failure(self, extractor):
        """Test episode extraction from repeated failure pattern."""
        pattern = {
            "type": "pattern",
            "situation": "Repeated failures in sy.mem.search",
            "action": "Attempted sy.mem.search 2 times without success",
            "outcome": "Pattern detected: operation failing repeatedly",
            "confidence": 0.85
        }
        
        result = extractor.extract_episode_from_pattern(pattern)
        
        assert result is not None
        assert "pattern" in result["situation"].lower()
        assert result["outcome"] == "Pattern detected"
    
    def test_extract_episode_from_pattern_success(self, extractor):
        """Test episode extraction from repeated success pattern."""
        pattern = {
            "type": "pattern",
            "situation": "Repeated success with sy.mem.search",
            "action": "Successfully used sy.mem.search 3 times",
            "outcome": "Pattern detected: operation consistently succeeds",
            "confidence": 0.8
        }
        
        result = extractor.extract_episode_from_pattern(pattern)
        
        assert result is not None
        assert "pattern" in result["situation"].lower()
        assert result["outcome"] == "Pattern detected"


if __name__ == "__main__":
    pytest.main([__file__])
