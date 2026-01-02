# Documentation Style Guide

Comprehensive guide for creating and maintaining consistent documentation across TimeBeam project.

## Markdown Format

### Headings
- Use `#` for main document title (H1)
- Use `##` for major sections (H2)
- Use `###` for subsections (H3)
- Use `####` for nested content (H4)
- Use `#####` rarely, only for deeply nested content (H5)

**Example:**
```markdown
# Document Title

## Major Section

### Subsection

#### Nested Content
```

### Lists
- Use `-` for unordered lists (bullet points)
- Use `1.` for numbered steps (with period after number)
- Use `- [ ]` for unchecked checkboxes
- Use `- [x]` for completed checkboxes

**Examples:**
```markdown
## Requirements
- Java 17 or later
- Maven 3.8+
- Xcode 15+

## Setup Steps
1. Clone repository
2. Install dependencies
3. Configure environment

## Tasks
- [ ] Create feature branch
- [ ] Implement feature
- [ ] Write tests
- [ ] Submit pull request

## Completed Items
- [x] Backend authentication
- [x] Frontend UI completed
- [x] Integration tests passing
```

### Code Blocks
- Use triple backticks (```) for multi-line code blocks
- Specify language for syntax highlighting: ```bash, ```java, ```swift, ```yaml
- Use single backticks (`) for inline code references
- No inline code blocks for more than 1 line

**Examples:**
```markdown
## Backend Setup

```bash
cd back-end
mvn clean install
```

## Frontend Setup

```swift
import SwiftUI

struct TimerView: View {
    var body: some View {
        Text("Hello, World!")
    }
}
```

**Inline code**: Use `TimerManager` class for timer operations.

**Multiple lines:**
```
mvn clean package -DskipTests
java -jar target/timebeam-backend.jar
```
```

### Links
- Use relative links for internal documents: `[Text](path/to/file.md)`
- Use absolute links for external resources: `[Text](https://example.com)`
- No trailing punctuation in link text (periods, commas)
- Keep link text descriptive

**Examples:**
```markdown
See [Architecture Overview](architecture/overview.md) for system design.

Visit [Spring Boot Documentation](https://spring.io/projects/spring-boot) for more information.

Related: [MVP Checklist](features/mvp-checklist.md), [Code Style](../codestyle/)
```

### Emojis
- Use emojis sparingly and consistently throughout documentation
- Place emoji at start of section heading (before text)
- Consistent emoji usage for similar concepts across files

**Recommended Emojis for TimeBeam:**

| Concept | Emoji | Usage |
|----------|--------|-------|
| Documentation | 📖 | Section headers, guides |
| Getting Started | 🚀 | Onboarding, quick start |
| Setup | 🔧 | Configuration, installation |
| Implementation | 📝 | Code, features |
| Testing | 🧪 | Testing frameworks, strategies |
| Analytics | 📊 | Statistics, metrics |
| Completed | ✅ | Done items, success |
| In Progress | 🔄 | Ongoing work |
| Failed/Error | ❌ | Issues, errors |
| Warning | ⚠️ | Important notes |
| Info | ℹ️ | Informational items |
| Architecture | 🏗️ | System design |
| Security | 🔐 | Security, authentication |
| Performance | ⚡ | Optimization, speed |
| Bug/Fix | 🐛 | Issues, fixes |
| Cross-Platform | 📱 | Multi-platform features |
| API/Backend | 🌐 | Backend, server |
| Database | 🗄️ | Data layer |

**Example:**
```markdown
## 🚀 Getting Started

## 📝 Implementation

- [x] Backend authentication ✅
- [ ] Frontend UI changes 🔄
- [ ] Integration tests 🧪

## ⚠️ Important Notes

Make sure to test all changes before committing.
```

### Formatting
- 1 blank line between sections (single blank line)
- 2 blank lines between major headers (## sections)
- No trailing whitespace at end of lines
- Wrap lines at 80-120 characters where possible
- Use consistent indentation (4 spaces for code blocks)

**Example:**
```markdown
# Main Title

## Section 1

Content goes here.

## Section 2

Content goes here with multiple paragraphs.

### Subsection

- List item 1
- List item 2
```

## File Naming

### Naming Conventions
- Use **kebab-case** for all file names: `project-overview.md`, `api-reference.md`
- Use **descriptive names**: `timer-sync-implementation.md`, `google-sign-in-guide.md`
- Avoid **version numbers**: `guide.md` not `guide-v2.md` (use Git history for versions)
- Use **category prefixes** when appropriate for organization

### File Extensions
- Use `.md` extension for all documentation
- No special characters in filenames
- Use only lowercase letters, numbers, and hyphens

**Good Examples:**
- `project-overview.md` ✅
- `setup-guide.md` ✅
- `backend-api-reference.md` ✅
- `ios-client-implementation-checklist.md` ✅

**Bad Examples:**
- `Project_Overview.md` ❌ (PascalCase)
- `setup_guide.txt` ❌ (wrong extension)
- `guide-v2.1.md` ❌ (version number in name)
- `my awesome file.md` ❌ (spaces, underscores)

## Folder Structure

### Organization Pattern

```
docs/
├── {category}/           # Category folder
│   ├── README.md       # Category overview (optional)
│   └── {topic}.md       # Specific documentation
└── README.md           # Main project index
```

### Category Folders

| Category | Purpose | Example Contents |
|----------|-----------|-----------------|
| getting-started | Onboarding | project-overview.md, setup-guide.md, quick-start.md |
| architecture | System design | overview.md, design-decisions.md |
| features | Feature docs | mvp-checklist.md |
| implementation-guides | How-to guides | ios/, backend/ subfolders |
| codestyle | Coding standards | java.md, swift.md, testing-*.md |
| ci-cd | Automation | README.md, comprehensive-plan.md |
| testing | Testing strategy | e2e-testing.md, framework-overview.md |
| tools | Tool guides | github-actions-setup.md |
| project-management | Tracking | fixes-summary.md, test-results/ |
| event-based-sync | Feature docs | overview.md, implementation.md |
| contributing | Guidelines | creating-documents.md, style-guide.md |

### README Files
- Optional for each category folder
- Provides overview and navigation for that category
- Links to all documents in that category
- Should follow same formatting as main docs

**Example: docs/ci-cd/README.md**
```markdown
# CI/CD Documentation

This folder contains TimeBeam's CI/CD implementation.

## 📚 Documents

- [Comprehensive Plan](comprehensive-plan.md) - Complete 5-stage CI/CD plan
- [Stage 1](stage-1/README.md) - Stage 1 implementation

## Quick Start
For fastest setup, see [Main Documentation README](../README.md).
```

## Content Structure

### Standard Document Template

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

**Notes:**
- Keep descriptions concise and clear
- Use active voice (e.g., "Create branch" not "Branch should be created")
- Focus on user actions, not implementation details
```

### Section Guidelines

#### Overview Section
- 1-2 paragraphs maximum
- Focus on high-level understanding
- No code implementation details

#### Content Section
- Use descriptive section headings
- Provide step-by-step instructions when applicable
- Include code examples for complex concepts
- Use tables for comparing options or configurations

#### Examples Section
- Include practical, working examples
- Explain why the example is important
- Add comments within code examples if needed

#### Troubleshooting Section
- List 3-5 common issues
- Provide clear solutions
- Include error messages or symptoms
- Add references to related documentation

## Content Quality

### Clarity
- Write in clear, concise English
- Avoid jargon when possible
- Explain technical terms on first use
- Use examples for complex concepts

### Completeness
- Cover all steps required to complete task
- Include common edge cases
- Provide troubleshooting section
- Link to related documentation

### Accuracy
- Verify code examples are tested and working
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
- [ ] Overview section summarizes content effectively
- [ ] All code examples use proper syntax highlighting
- [ ] Links are correct and working
- [ ] Emojis used consistently and sparingly
- [ ] Troubleshooting section included (if applicable)
- [ ] Related documentation section added
- [ ] Content is concise and easy to understand
- [ ] No trailing whitespace or formatting issues
- [ ] Markdown renders correctly in preview

## Common Mistakes to Avoid

### Formatting
- ❌ Using inconsistent heading levels (skip from H1 to H3)
- ❌ Mixing list styles (bullets and numbers together)
- ❌ Inconsistent indentation
- ❌ Missing blank lines between sections

### Links
- ❌ Using absolute links for internal docs
- ❌ Forgetting to update related docs when changing structure
- ❌ Using link text like "click here" instead of descriptive text

### Content
- ❌ Writing in passive voice ("should be created" instead of "create")
- ❌ Including implementation details in overview sections
- ❌ Writing overly long paragraphs (should use bullet points)
- ❌ Including outdated information

## Documentation Updates

### When to Update
- Features are added, modified, or removed
- Architecture changes are implemented
- New tools or services are integrated
- Bug fixes change documented behavior
- Processes or workflows change
- Community feedback indicates confusion or issues

### How to Update
1. Make changes to documentation file
2. Update related documents if needed
3. Update index files (README.md in category folders)
4. Commit changes with descriptive message: `docs: update {file-name} for {reason}`
5. Pull request to main branch with appropriate label

### Update Process

```bash
# Make changes
vim docs/getting-started/setup-guide.md

# Update related docs
# (if applicable)

# Stage and commit
git add docs/getting-started/setup-guide.md
git commit -m "docs: update setup-guide for new installation steps"

# Pull request
git push origin feature/documentation-update
```

## Related Documentation

- [Creating Documentation](creating-documents.md) - Guidelines for documentation creation
- [Folder Structure](folder-structure.md) - Complete folder organization guide
- [AGENTS Configuration](../../AGENTS.md) - Agent-specific commands and workflows
- [Main Documentation Index](../README.md) - Project documentation hub

---

**Need help?** Check [Troubleshooting](#troubleshooting) or consult project maintainers.

## Troubleshooting

### Documentation Issues
**Documentation doesn't render correctly:**
- Check for proper markdown syntax
- Verify link formats are correct
- Check for unescaped special characters

**Links are broken:**
- Verify file paths are correct
- Check for case sensitivity (especially on Linux/Mac)
- Ensure relative paths start from correct location

**Content is unclear or confusing:**
- Ask a colleague to review
- Add examples for clarity
- Break down complex concepts into smaller sections

### Version Control Issues
**Merge conflicts in documentation:**
- Communicate with other contributors
- Use `git rebase` to maintain clean history
- Update documentation after resolving conflicts

**Lost changes during rebase:**
- Check `git reflog` for lost commits
- Manually recreate if necessary
- Always create backup branch before complex operations

---

**Good documentation makes everyone's life easier!** 📖
