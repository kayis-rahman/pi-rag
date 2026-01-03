# RAG Enforcement Checklist

## ⚠️ USAGE INSTRUCTIONS

**MANDATORY**: Complete this checklist for EVERY operation in OpenCode.

**When to Use:**
- Before EVERY operation (file read, edit, search, bash command, decision)
- Verify RAG was queried with broad context
- Document RAG citations in reasoning

**Enforcement Level: Hybrid**
- Documentation-driven approach (AGENTS.md)
- Checklist validation for compliance
- OpenCode prompts for missing RAG queries
- Can proceed with explicit acknowledgment

---

## 🚨 Pre-Operation Checklist (MANDATORY - ALL OPERATIONS)

Complete ALL items BEFORE ANY operation:

### Step 1: Query RAG for Broad Context
- [ ] Called `rag_get_context` with `context_type="all"`
- [ ] Query included "architecture code standards" + operation-specific topic
- [ ] Retrieved symbolic memory (authoritative facts)
- [ ] Retrieved episodic memory (lessons learned)
- [ ] Retrieved semantic memory (documentation)

### Step 2: Review RAG Results
- [ ] Reviewed code standards from symbolic memory
- [ ] Identified relevant patterns from episodic memory
- [ ] Located related implementations in semantic memory
- [ ] Identified applicable constraints or requirements

### Step 3: Apply Patterns
- [ ] Applied architecture patterns from RAG
- [ ] Matched code style from RAG standards
- [ ] Used best practices from episodic memory
- [ ] Considered lessons learned to avoid mistakes

### Step 4: Document Citations
- [ ] Cited RAG sources in reasoning
- [ ] Referenced specific files/components from RAG
- [ ] Noted code standards applied
- [ ] Documented patterns used

---

## 📝 Pre-Read Checklist (MANDATORY - FILE OPERATIONS)

Complete ALL items BEFORE READING files:

- [ ] Queried RAG for file-specific context
- [ ] Used `rag_search` for filename/component
- [ ] Reviewed existing implementations from RAG
- [ ] Understood file purpose from documentation
- [ ] Identified related files/components

---

## ✏️ Pre-Edit Checklist (MANDATORY - FILE EDITS)

Complete ALL items BEFORE EDITING files:

- [ ] Queried RAG for file-specific context
- [ ] Used `rag_search` for filename/component
- [ ] Reviewed existing implementations in RAG
- [ ] Matched coding style from RAG standards
- [ ] Verified patterns align with project standards

---

## 🎯 Pre-Decision Checklist (MANDATORY - DECISIONS)

Complete ALL items BEFORE MAKING decisions:

- [ ] Queried RAG for decision-related context
- [ ] Verified against authoritative facts (symbolic memory)
- [ ] Checked episodic memory for relevant lessons
- [ ] Reviewed semantic memory for similar situations
- [ ] Documented reasoning with RAG citations

---

## 🔄 Post-Operation Checklist (MANDATORY - ALL OPERATIONS)

Complete ALL items AFTER COMPLETING operations:

### Step 1: Validation
- [ ] Validated results against RAG code standards
- [ ] Verified alignment with RAG knowledge
- [ ] Checked for violations of code style
- [ ] Confirmed architectural alignment

### Step 2: Documentation
- [ ] Noted any discrepancies found
- [ ] Documented lessons learned
- [ ] Added new patterns to episodic memory (if applicable)
- [ ] Updated documentation if new insights discovered

### Step 3: Quality Check
- [ ] Code follows SOLID principles (from symbolic memory)
- [ ] No null returns in Java (from symbolic memory)
- [ ] No force unwrapping in Swift (from symbolic memory)
- [ ] Security requirements met (from symbolic memory)
- [ ] Logging standards followed (from symbolic memory)

---

## ⚠️ Exception Handling

If RAG query fails or returns no results:

1. **WARN user explicitly**: "⚠️ RAG query failed/no results. Proceeding with limited context."
2. **CONTINUE with operation** (don't block)
3. **NOTE in reasoning**: "RAG unavailable - using general LLM knowledge"
4. **Document discrepancy** for future reference

**Valid Exceptions** (MUST be documented):
1. Creating completely new files (no prior context exists)
2. Working outside timebeam project (document explicitly)
3. RAG system unavailable (log error)
4. User explicitly requests to skip (document)

---

## 📊 Compliance Verification

**RAG Query Present?**
- [ ] Broad context query (architecture + standards + topic)
- [ ] Specific file/component search (if applicable)
- [ ] Code style verification (if editing)
- [ ] Citations documented in reasoning

**Results Applied?**
- [ ] Code standards followed
- [ ] Architecture patterns applied
- [ ] Lessons learned considered
- [ ] Best practices used

**Quality Check Passed?**
- [ ] No violations of symbolic memory facts
- [ ] Aligns with project standards
- [ ] Follows DDD architecture
- [ ] Meets security requirements
- [ ] Uses proper logging

---

## 🔍 Quick Reference: RAG Query Templates

### For All Operations (MANDATORY)
```
rag_get_context(
  project_id="timebeam",
  context_type="all",
  query="architecture code standards <operation-specific topic>",
  max_results=15
)
```

### For File Operations
```
rag_search(
  project_id="timebeam",
  query="<filename or component name>",
  memory_type="semantic",
  top_k=10
)
```

### For Code Style Verification
```
rag_get_context(
  project_id="timebeam",
  query="code style standards Java Swift",
  context_type="symbolic",
  max_results=10
)
```

### For API Usage
```
rag_search(
  project_id="timebeam",
  query="API endpoints authentication timer <specific endpoint>",
  memory_type="semantic",
  top_k=15
)
```

### For Architecture Decisions
```
rag_get_context(
  project_id="timebeam",
  context_type="all",
  query="DDD layers SOLID principles architecture",
  max_results=10
)
```

---

## 📚 RAG Memory Types Reference

### Symbolic Memory (100% Trusted - Authoritative Facts)

**When to Use:**
- Verifying tech stack information
- Understanding architecture patterns
- Checking code standards and requirements
- Learning build/test commands
- Understanding security requirements

**Contains:**
- Technology stack (Spring Boot 3.2.0, Java 17, SwiftUI, etc.)
- Architecture (DDD layers, SOLID principles)
- Code standards (no null returns, no force unwrapping, 80% coverage)
- Build commands (Maven, Xcode, SwiftLint)
- Security requirements (JWT tokens, Keychain storage)

### Episodic Memory (Highly Trusted - Lessons Learned)

**When to Use:**
- Understanding development patterns
- Learning from previous issues/solutions
- Applying migration/refactoring experiences
- Avoiding common mistakes

**Contains:**
- Development patterns and best practices
- Common issues and their solutions
- Migration and refactoring experiences
- Bug fixes and their root causes

### Semantic Memory (Reference Material - Documentation)

**When to Use:**
- Finding specific files or components
- Searching for code examples
- Locating documentation
- Understanding existing implementations

**Contains:**
- Documentation (AGENTS.md, docs/codestyle/, etc.)
- Source code (Swift, Java)
- API definitions and examples
- Configuration files

---

## ✅ Final Compliance Check

Before completing any operation, verify:

- [ ] RAG was queried BEFORE starting operation
- [ ] Broad context retrieved (architecture + standards + topic)
- [ ] RAG citations documented in reasoning
- [ ] Code/style follows RAG standards
- [ ] Architecture aligns with RAG patterns
- [ ] No violations of RAG constraints
- [ ] Exceptions (if any) are documented

If ANY item is unchecked, document why and proceed with caution.
