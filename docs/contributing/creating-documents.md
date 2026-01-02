# Creating Documentation

This guide explains how to create documentation for TimeBeam project following consistent style and structure.

## When to Create Documentation

Create or update documentation when:
- Adding new features to TimeBeam
- Making architectural changes
- Implementing complex workflows
- Updating development processes
- Recording bug fixes or solutions
- Setting up new tools or services

## Documentation Style Guide

### Markdown Format

#### Headings
- Use `#` for main document title
- Use `##` for major sections
- Use `###` for subsections
- Use `####` for nested content

#### Lists
- Use `-` for unordered lists
- Use `1.` for numbered steps
- Use `- [ ]` for unchecked checkboxes
- Use `- [x]` for completed items

#### Code Blocks
- Use triple backticks (```) for multi-line code
- Specify language: ```bash, ```java, ```swift, ```yaml
- Use single backticks (`) for inline code references
- No inline code blocks for more than 1 line

Example:
```
bash
# Create feature branch
git checkout -b feature/timer-improvements
```

#### Links
- Use relative links for internal documents: `[Text](path/to/file.md)`
- Use absolute links for external resources: `[Text](https://example.com)`
- No trailing punctuation in link text

Examples:
```markdown
See [Architecture Overview](../architecture/overview.md) for details.
Visit [Spring Boot Documentation](https://spring.io/projects/spring-boot) for more information.
```

#### Emojis
- Use emojis sparingly and consistently
- Common emojis for TimeBeam documentation:
  - 📚 - Documentation
  - 🚀 - Getting Started / Quick Start
  - 🔧 - Setup / Configuration
  - 📝 - Implementation / Code
  - 🧪 - Testing
  - 📊 - Analytics / Statistics
  - ✅ - Completed / Success
  - ❌ - Failed / Error
  - 🔄 - In Progress / Ongoing
  - ⚠️ - Warning / Important Note
  - 📖 - Project Overview
  - 🤖 - Code Style & Standards

#### Formatting
- 1 blank line between sections
- 2 blank lines between major headers (##)
- No trailing whitespace
- 80-120 characters per line where possible
- Use proper spacing around list items and code blocks

## Document Structure

### Standard File Structure

Every documentation file should follow this structure:

```markdown
# Title

Brief description (1-2 sentences) of what this document covers.

## Overview
High-level summary for quick understanding (1-2 paragraphs).

## Prerequisites
What you need before using this guide:
- Tools installed
- Files read
- Setup completed
- Permissions granted

## Content
Main documentation content with clear sections.

## Examples
Code snippets, screenshots, or practical examples when helpful.

## Troubleshooting
Common issues and solutions (optional but recommended).

## Related Documentation
Links to related documents with brief descriptions.

---

## Notes:
- Keep descriptions concise and clear
- Use active voice (e.g., "Create branch" not "Branch should be created")
- Focus on user actions, not implementation details
```

## Folder Structure Guidelines

### Organization

Documentation should be organized by category:

```
docs/
├── {category}/           # Category folder
│   ├── README.md       # Category overview (optional)
│   └── {topic}.md       # Specific documentation
└── README.md           # Main project index
```

### File Naming

- Use kebab-case for all files: `project-overview.md`
- Use descriptive names: `timer-sync-implementation.md`
- Avoid version numbers: `guide.md` not `guide-v2.md`
- Use category prefixes when appropriate:
  - `ios/` for iOS-specific guides
  - `backend/` for backend-specific guides
  - `ci-cd/` for CI/CD documentation

### Folder Categories

| Category | Description | Example Files |
|----------|-------------|---------------|
| getting-started | Onboarding, setup, quick reference | project-overview.md, setup-guide.md, quick-start.md |
| architecture | System architecture and design decisions | overview.md, design-decisions.md |
| features | Feature documentation and checklists | mvp-checklist.md |
| implementation-guides | How-to guides for specific features | ios/timer-sync.md, backend/api-reference.md |
| codestyle | Coding standards and best practices | java.md, swift.md, testing-backend.md |
| ci-cd | CI/CD pipelines and workflows | README.md, comprehensive-plan.md |
| testing | Testing frameworks and strategies | e2e-testing.md, framework-overview.md |
| tools | Tool-specific setup and usage | github-actions-setup.md |
| project-management | Tracking and reporting | fixes-summary.md |
| event-based-sync | Feature-specific documentation | overview.md, implementation.md |
| contributing | Guidelines for contributors | creating-documents.md |

## Content Quality

### Clarity
- Write in clear, concise English
- Avoid jargon when possible, or explain it
- Use examples for complex concepts
- Define acronyms on first use

### Completeness
- Cover all steps required to complete the task
- Include common edge cases
- Provide troubleshooting section
- Link to related documentation

### Accuracy
- Verify code examples work
- Check file paths and commands are correct
- Test instructions before publishing
- Update documentation when things change

### Maintainability
- Use consistent formatting across all docs
- Avoid duplication (reference other docs instead)
- Keep files focused on single topic
- Regularly review and update outdated content

## Documentation Review Checklist

Before creating or updating documentation, ensure:

- [ ] File name follows kebab-case convention
- [ ] File is placed in appropriate category folder
- [ ] Document has clear and descriptive title
- [ ] Overview section summarizes the content
- [ ] All code examples are tested and working
- [ ] Links are correct and working
- [ ] Emojis used consistently and sparingly
- [ ] Troubleshooting section included (if applicable)
- [ ] Related documentation section added
- [ ] Content is concise and easy to understand
- [ ] No trailing whitespace or formatting issues
- [ ] Markdown renders correctly

## Documentation Updates

### When to Update
- Features are added, modified, or removed
- Architecture changes are implemented
- New tools or services are integrated
- Bug fixes change documented behavior
- Processes or workflows change
- Community feedback indicates confusion or issues

### How to Update
1. Make changes to the documentation file
2. Update related documents if needed
3. Update index files (README.md in category folders)
4. Commit changes with descriptive message: `docs: update {file-name} for {reason}`
5. Pull request to main branch with appropriate label

## Related Documentation

- [Style Guide](style-guide.md) - Detailed formatting and style guidelines
- [Folder Structure](folder-structure.md) - Complete folder organization guide
- [AGENTS Configuration](../../AGENTS.md) - Agent-specific commands and workflows

---

**Need help?** Check [Troubleshooting](#troubleshooting) or consult project maintainers.

## Troubleshooting

**Documentation doesn't render correctly:**
- Check for proper markdown syntax
- Verify link formats
- Check for unescaped special characters

**Links are broken:**
- Verify file paths are correct
- Check for case sensitivity (especially on Linux/Mac)
- Ensure relative paths start from correct location

**Content is unclear or confusing:**
- Ask a colleague to review
- Add examples for clarity
- Break down complex concepts into smaller sections

---

**Good documentation helps everyone contribute effectively!** 📚
