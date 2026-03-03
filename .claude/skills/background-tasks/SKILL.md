---
name: background-tasks
description: Execute implementation plans in background while Pichu stays responsive. Wraps subagent-driven-development with run_in_background: true.
---

# Background Tasks

## Overview

Execute implementation plans in background while Pichu stays responsive to new messages.

**Announce at start:** "I'm using the background-tasks skill to execute this plan in background."

## When to Use

After `writing-plans` skill completes and user approves execution:
- User says "yes", "go", "start", "approve" to start execution
- Plan file exists at `docs/plans/YYYY-MM-DD-*.md`

## The Process

### Step 1: Load plan and prepare state

1. Read the plan file (passed as argument or most recent in `docs/plans/`)
2. Generate task ID using `scripts/task-state.sh set_running`
3. Reply to user: "Started background execution. I'll notify when done. /status for updates."

### Step 2: Spawn background subagent

Use Task tool with `run_in_background: true`:

```
Task tool:
  description: "Execute plan: [plan name]"
  prompt: |
    Use subagent-driven-development skill to execute this plan:

    [Plan content or file path]

    Work through all tasks. Report completion with summary.
  run_in_background: true
```

### Step 3: Return to message loop

After spawning:
- Control returns immediately to Commander
- Pichu can respond to new messages
- Task runs in background

### Step 4: Handle completion

When Task completes (detected via TaskOutput):
1. Get result summary from subagent
2. Update task state: `scripts/task-state.sh set_completed`
3. Set pending notification flag
4. If user idle > 60s: send notification immediately
5. Otherwise: notify on next interaction

## Smart Notification

On each new message, Commander checks:
1. If `has_pending_notification` is true AND `check_idle` > 60s
2. Send notification: "Background task complete! [summary]"
3. Clear notification flag

## State Files

Task state tracked in `state/tasks/`:
- `{chat_id}.md` - Summary + last message time + pending notification
- `{chat_id}-{task_id}.md` - Detailed progress

## Commands

Users can interact with background tasks:
- `/status` - Show current task status (Commander handles this)
- `/stop` - Stop running task with TaskStop tool

## Critical Rules

1. **ALWAYS use run_in_background: true** - This is the core feature
2. **Track state via scripts** - Use task-state.sh for all state updates
3. **Reply immediately after spawn** - User knows task started
4. **Don't block** - Return to Commander after spawning
5. **Smart notification** - Only notify if user is idle

## Integration

Works with:
- `writing-plans` - Creates the plan this skill executes
- `subagent-driven-development` - The actual execution engine
- `commander` - Orchestrates message flow and notifications
