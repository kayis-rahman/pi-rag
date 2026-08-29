# /checkpoint — Save/load checkpoints

Save current project state for session continuity.

## Save Checkpoint
```
# Save current git state
git rev-parse HEAD > .claude/checkpoints.log
echo "$(date +%Y-%m-%d-%H:%M) | $(git rev-parse --short HEAD)" >> .claude/checkpoints.log
```

## Load Checkpoint
Read `.claude/checkpoints.log` for last saved state.

## Manual Checkpoint
- Save current branch: `git branch`
- Save uncommitted changes: `git status`
- Save current phase: read `.planning/STATE.md`
- Save active tasks: note any in-progress work

## Checkpoint Best Practices
- Save before major refactors
- Save after completing a phase task
- Save before switching branches
- Include brief description of what was changed
