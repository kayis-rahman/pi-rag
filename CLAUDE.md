# CLAUDE.md — Developer's Second Brain

## Who I Am
You're a developer working on TimeBeam, a cross-platform productivity application with iOS/macOS SwiftUI apps and a Spring Boot backend. You track your swing trading system separately and use this vault for project-specific notes, research, and planning.

## My Vault Structure
```
inbox/          Drop zone — everything new lands here first
daily/          Daily brain dumps and quick captures
research/       Technical research, docs, API references
clients/        Client/project context (TimeBeam, Swing Trade)
projects/       Active work with status and next actions
archive/        Completed work — never deleted, just moved
```

## How I Work
- **Capture first, organize later** — dump ideas in inbox/, sort later
- **Technical focus** — deep notes on Swift, SwiftUI, Spring Boot, PostgreSQL
- **Project-based** — TimeBeam and Swing Trade are separate focus areas
- **AI as co-pilot** — use `/project` to load context, `/tldr` to save session

## Context Rules
When I mention TimeBeam → check `clients/timebeam/` and `projects/timebeam/`
When I mention Swing Trade → check `clients/swing-trade/` and `projects/swing-trade/`
When I ask to write code → read relevant project/ folder for context
When something lands in inbox/ → ask if I want it sorted now

## Skill routing

When the user's request matches an available skill, ALWAYS invoke it using the Skill
tool as your FIRST action. Do NOT answer directly, do NOT use other tools first.
The skill has specialized workflows that produce better results than ad-hoc answers.

Key routing rules:
- Product ideas, "is this worth building", brainstorming → invoke office-hours
- Bugs, errors, "why is this broken", 500 errors → invoke investigate
- Ship, deploy, push, create PR → invoke ship
- QA, test the site, find bugs → invoke qa
- Code review, check my diff → invoke review
- Update docs after shipping → invoke document-release
- Weekly retro → invoke retro
- Design system, brand → invoke design-consultation
- Visual audit, design polish → invoke design-review
- Architecture review → invoke plan-eng-review
- Save progress, checkpoint, resume → invoke checkpoint
- Code quality, health check → invoke health
