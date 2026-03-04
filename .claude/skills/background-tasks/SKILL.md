---
name: background-tasks
description: Execute implementation plans in background while Pichu stays responsive. Wraps subagent-driven-development with run_in_background: true.
---

# Background Tasks

Execute plans in background while staying responsive to new messages.

## When to Use

After `writing-plans` skill completes and user approves execution.

User can also trigger manually: "execute the plan"

## Process

1. Load plan → Generate task ID → Reply "Started background execution..."
2. Spawn subagent with `Task(tool)` - see `references/task-template.md`
3. Return to message loop (task runs in background)
4. Handle completion with smart notification

## Critical Rules

1. **ALWAYS use `run_in_background: true`**
2. **Track state via `scripts/task-state.sh`**
3. **Reply immediately after spawn**
4. **Don't block - return to Commander**
5. **Smart notification - only if user idle > 60s**

## Integration

- `writing-plans` - creates the plan
- `subagent-driven-development` - execution engine
- `commander` - orchestrates flow and notifications

## Error Handling

If task fails:
1. Check TaskOutput for error details
2. Reply to user: "Task failed: [error summary]"
3. Offer options: "Retry with fix?", "Modify plan?", "Cancel?"
