# Phase 5: Tasks Tab - Discussion Log

**Date:** 2026-05-10

## Areas Discussed

### Task Completion Experience
- **Q:** Primary completion method?
  - Options: Checkbox toggle, Swipe to complete, Both checkbox + swipe
  - **Choice:** Both checkbox + swipe — checkbox for quick complete, swipe for secondary actions (complete, delete, edit)

- **Q:** Visual feedback on completion?
  - Options: Haptic + strikethrough, Haptic + strikethrough + flash, Haptic + strikethrough + confetti
  - **Choice:** Haptic + strikethrough — clean, satisfying, no extra UI

### Timer-Task Integration
- **Q:** How to link task to timer?
  - Options: Play button on task row, Full-screen focus mode, Task picker before timer
  - **Choice:** Play button on task row — ▶ on in-progress tasks, tap to start timer with task linked

### Task Progress Tracking
- **Q:** What metrics and where?
  - Options: Inline progress bar, Detail view on tap, Progress in analytics tab
  - **Choice:** Inline progress bar — `[████░░░░] 3/4 · 45min` in task row, always visible

### Recycle Bin & Soft Delete
- **Q:** How should soft delete work?
  - Options: Swipe delete + undo + recycle bin, Delete with no undo, Recycle bin only
  - **Choice:** Swipe delete + undo + recycle bin — 5-second inline undo, cross-device sync, 30-day auto-expire
