"""
Learning Extractor - LLM-assisted extraction of learnings from operations.

This module uses LLM to extract episodes and facts from completed tasks
and code changes. Supports rule-based fallback for reliability.

Design Principles:
- LLM-based extraction with rule-based fallback
- Confidence scoring to filter low-quality learnings
- Abstracted strategies (not specific to exact situation)
- Error handling with graceful degradation
"""

import json
import re
import logging
from typing import Dict, Any, Optional, List

logger = logging.getLogger(__name__)


class LearningExtractor:
    """
    LLM-assisted extraction of episodes and facts from operations.
    
    Responsibilities:
    - Extract episodes from task completion data
    - Extract facts from code file content
    - Provide rule-based fallback when LLM fails
    - Score confidence for extracted learnings
    """
    
    # Episode extraction prompt
    EPISODE_EXTRACTION_PROMPT = """You are a Learning Extraction System for an AI agent.

Analyze this completed task and extract a learnable episode:

Task Information:
- Situation: {situation}
- Action: {action}
- Outcome: {outcome}

STRICT RULES:
1. Extract an episode ONLY if:
   - Task succeeded in a non-obvious way
   - A mistake was made and corrected
   - Strategy can be applied to future tasks

2. DO NOT extract if:
   - Task succeeded in an obvious/expected way
   - No lesson can be generalized
   - Only facts were learned (not strategies)

3. Lesson MUST be:
   - Abstract (not specific to this exact situation)
   - Actionable (what to do differently next time)
   - Concise (under 200 characters)

OUTPUT FORMAT (JSON only):
{{
  "situation": "Brief description of situation",
  "action": "Brief description of action taken",
  "outcome": "success/failure",
  "lesson": "Abstracted strategy (what to apply in future)",
  "confidence": 0.75
}}

If NO lesson qualifies, return: {{"should_extract": false}"""
    
    def __init__(self, model_manager: Optional[Any] = None, config: Optional[Dict[str, Any]] = None):
        """
        Initialize learning extractor.

        Args:
            model_manager: Optional ModelManager for LLM access
            config: Optional auto-learning configuration
        """
        self.model_manager = model_manager
        self.config = config or {}
        self.track_code_changes = self.config.get("track_code_changes", True)
    
    def extract_episode_from_task(self, task: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Extract episode from task completion data using LLM.
        
        Args:
            task: Task completion dict with keys:
                - type: "task_completion"
                - situation: str
                - action: str
                - outcome: str
                - confidence: float
        
        Returns:
            Episode dict or None (if no episode qualifies)
        """
        # If confidence is too low, don't extract
        if task.get("confidence", 0.7) < 0.6:
            logger.info(f"Task confidence too low for episode extraction: {task.get('confidence')}")
            return None
        
        # Try LLM extraction
        if self.model_manager:
            llm_result = self._extract_episode_with_llm(task)
            if llm_result:
                return llm_result
        
        # Fallback to rule-based extraction
        return self._extract_episode_rule_based(task)
    
    def _extract_episode_with_llm(self, task: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Extract episode using LLM.
        
        Returns:
            Episode dict or None
        """
        try:
            # Build prompt
            prompt = self.EPISODE_EXTRACTION_PROMPT.format(
                situation=task.get("situation", "Unknown"),
                action=task.get("action", "Unknown"),
                outcome=task.get("outcome", "Unknown")
            )
            
            # Call LLM
            response = self.model_manager.chat_completion(
                "chat",  # Use chat model
                [
                    {"role": "system", "content": "You are a helpful assistant that outputs valid JSON only."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.3,  # Low temperature for more consistent extraction
                max_tokens=500
            )
            
            # Extract content from response
            llm_content = ""
            if response and isinstance(response, dict):
                choices = response.get("choices", [])
                if choices:
                    choice = choices[0]
                    if "message" in choice:
                        llm_content = choice["message"].get("content", "")
                    elif "text" in choice:
                        llm_content = choice.get("text", "")
            
            # Parse JSON response
            return self._parse_episode_response(llm_content)
            
        except Exception as e:
            logger.error(f"LLM episode extraction failed: {e}, using rule-based fallback")
            return self._extract_episode_rule_based(task)
    
    def _parse_episode_response(self, response_text: str) -> Optional[Dict[str, Any]]:
        """
        Parse JSON from LLM response with error handling.
        
        Args:
            response_text: Raw LLM response string
        
        Returns:
            Episode dict or None
        """
        if not response_text:
            return None
        
        try:
            # Remove markdown code blocks if present
            cleaned = response_text.strip()
            
            # Remove ```json and ``` markers
            if cleaned.startswith("```json"):
                cleaned = cleaned[7:]
            if cleaned.startswith("```"):
                cleaned = cleaned[3:]
            if cleaned.endswith("```"):
                cleaned = cleaned[:-3]
            
            cleaned = cleaned.strip()
            
            # Parse JSON
            data = json.loads(cleaned)
            
            # Check if should extract (may be {"should_extract": false})
            if isinstance(data, dict):
                if "should_extract" in data and not data["should_extract"]:
                    return None
                return data
            
            # Validate required fields
            required_fields = ["situation", "action", "outcome", "lesson"]
            if not all(field in data for field in required_fields):
                logger.warning(f"Episode data missing required fields: {data.keys()}")
                return None
            
            # Ensure lesson is abstract
            lesson = data.get("lesson", "")
            if lesson == data.get("situation", ""):
                logger.warning("Lesson is just repeating situation, not abstracting")
                return None
            
            # Check confidence range
            confidence = float(data.get("confidence", 0.7))
            if confidence < 0.0 or confidence > 1.0:
                logger.warning(f"Invalid confidence: {confidence}")
                data["confidence"] = 0.7  # Default to reasonable value
            
            return data
            
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse JSON: {e}")
            return None
        except Exception as e:
            logger.error(f"Error parsing episode response: {e}")
            return None
    
    def _extract_episode_rule_based(self, task: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Fallback extraction if LLM fails.
        
        Args:
            task: Task completion dict
        
        Returns:
            Episode dict or None
        """
        if task.get("outcome") != "success":
            return None
        
        # Only create episode if confidence is high enough
        if task.get("confidence", 0.7) >= 0.75:
            return {
                "situation": task.get("situation", ""),
                "action": task.get("action", ""),
                "outcome": "success",
                "lesson": f"Strategy: {task['action']} leads to success",
                "confidence": task.get("confidence", 0.7)
            }
        
        return None
    
    def extract_facts_from_code(self, file_path: str, file_content: str) -> List[Dict[str, Any]]:
        """
        Extract facts from code file using patterns.
        
        Args:
            file_path: Path to file (for metadata)
            file_content: Content of code file
        
        Returns:
            List of fact dicts
        """
        if not self.track_code_changes:
            return []
        
        facts = []
        
        # Pattern 1: Import statements
        import_pattern = re.compile(r'^\\s*(import|from)\\s+(\\w+)')
        imports = import_pattern.findall(file_content)
        
        if imports:
            # Group by top-level package
            packages = [imp.split('.')[0] for imp in imports]
            unique_packages = list(set(packages))
            
            facts.append({
                "category": "fact",
                "key": "dependencies",
                "value": {"packages": unique_packages},
                "confidence": 1.0,
                "source": "code_analysis",
                "metadata": {"file_path": file_path}
            })
        
        # Pattern 2: Framework usage
        framework_patterns = {
            r'@app\\.route\\(': 'fastapi',
            r'router\\.(': 'express',
            r'@Component': 'react/vue/angular',
            r'class Component': 'react/vue/angular'
        }
        
        for pattern, framework in framework_patterns.items():
            if pattern in file_content:
                facts.append({
                    "category": "fact",
                    "key": "framework",
                    "value": {"framework": framework},
                    "confidence": 1.0,
                    "source": "code_analysis",
                    "metadata": {"file_path": file_path}
                })
        
        # Pattern 3: API endpoints
        api_pattern = re.compile(r'@\\w+\\.(get|post|put|delete|patch)\\(')
        endpoints = api_pattern.findall(file_content)
        
        if endpoints:
            # Unique endpoints
            unique_endpoints = list(set(endpoints))
            
            facts.append({
                "category": "fact",
                "key": "api_endpoints",
                "value": {"endpoints": unique_endpoints},
                "confidence": 1.0,
                "source": "code_analysis",
                "metadata": {"file_path": file_path}
            })
        
        return facts
    
    def extract_facts_from_ingestion(self, file_path: str) -> List[Dict[str, Any]]:
        """
        Extract facts from file ingestion (simpler version for ingestion).
        
        Args:
            file_path: Path to ingested file
        
        Returns:
            List of fact dicts
        """
        if not self.track_code_changes:
            return []
        
        facts = []
        
        # Extract framework/language from file path
        # Check for common framework indicators
        framework_patterns = {
            "/app.py": "Flask/FastAPI",
            "/main.py": "Various",
            "/router": "Express/FastAPI",
            "/component": "React/Vue/Angular"
        }
        
        detected_framework = "unknown"
        for pattern, framework in framework_patterns.items():
            if pattern in file_path.lower():
                detected_framework = framework
                break
        
        if detected_framework != "unknown":
            facts.append({
                "category": "fact",
                "key": "framework",
                "value": {"framework": detected_framework},
                "confidence": 1.0,
                "source": "ingestion_analysis",
                "metadata": {"file_path": file_path}
            })
        
        return facts
