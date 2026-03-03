# Background Tasks Implementation Plan

> **For Claude:** Use `subagent-driven-development` skill to implement this plan task-by-task.

**Goal:** Enable Pichu to run implementation tasks in background while staying responsive to new messages.

**Architecture:** New `background-tasks` skill wraps `subagent-driven-development` with `run_in_background: true`. File-based task tracking in `state/tasks/` + smart notification on completion.

**Tech Stack:** Bash scripts, Markdown state files

---

## Task 1: Create task state directory structure

**Files:**
- Create: `state/tasks/.gitkeep`
- Create: `state/tasks/TEMPLATE.md`

**Step 1: Create the tasks directory**

```bash
mkdir -p state/tasks
touch state/tasks/.gitkeep
```

**Step 2: Verify directory exists**

Run: `ls -la state/tasks/`
Expected: Shows `.gitkeep` file

**Step 3: Create TEMPLATE.md for task files**

```markdown
# Task: {task_id}

## Meta
- Chat ID: {chat_id}
- Plan File: {plan_file}
- Started: {timestamp}
- Status: running

## Progress
- Current Step: Task 1/N
- Completed Steps: None

## Review History
(Added as tasks complete)

## Final Summary
(Added on completion)
```

**Step 4: Write TEMPLATE.md**

```bash
cat > state/tasks/TEMPLATE.md << 'EOF'
# Task: {task_id}

## Meta
- Chat ID: {chat_id}
- Plan File: {plan_file}
- Started: {timestamp}
- Status: running

## Progress
- Current Step: Task 1/N
- Completed Steps: None

## Review History
(Added as tasks complete)

## Final Summary
(Added on completion)
EOF
```

**Step 5: Verify template**

Run: `cat state/tasks/TEMPLATE.md`
Expected: Shows template content

**Step 6: Commit**

```bash
git add state/tasks/.gitkeep state/tasks/TEMPLATE.md
git commit -m "feat(tasks): add task state directory and template"
```

---

## Task 2: Create task-state.sh helper script

**Files:**
- Create: `scripts/task-state.sh`

**Step 1: Create the helper script**

```bash
cat > scripts/task-state.sh << 'SCRIPT'
#!/bin/bash
# task-state.sh - Manage background task state files
# Usage: ./scripts/task-state.sh <command> [args...]

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TASKS_DIR="$PROJECT_ROOT/state/tasks"

# Generate a simple task ID
generate_task_id() {
  echo "task_$(date +%s)"
}

# Get current ISO timestamp
get_timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# get_status <chat_id> - Returns: running|completed|failed|none
get_status() {
  local chat_id="$1"
  local summary_file="$TASKS_DIR/${chat_id}.md"

  if [ ! -f "$summary_file" ]; then
    echo "none"
    return
  fi

  # Extract status from summary file
  grep -m1 "^- Status:" "$summary_file" | sed 's/- Status: //' || echo "none"
}

# set_running <chat_id> <plan_file> <description>
set_running() {
  local chat_id="$1"
  local plan_file="$2"
  local description="$3"
  local task_id=$(generate_task_id)
  local timestamp=$(get_timestamp)

  local summary_file="$TASKS_DIR/${chat_id}.md"
  local detail_file="$TASKS_DIR/${chat_id}-${task_id}.md"

  # Create summary file
  cat > "$summary_file" << EOF
# Task Summary for Chat ${chat_id}

## Last Message Time
- Timestamp: ${timestamp}
- Msg ID: 0

## Current/Last Task
- Task ID: ${task_id}
- Description: ${description}
- Status: running
- Started: ${timestamp}

## Pending Notification
- Has completed task: false
- Result summary:
EOF

  # Create detail file
  cat > "$detail_file" << EOF
# Task: ${task_id}

## Meta
- Chat ID: ${chat_id}
- Plan File: ${plan_file}
- Started: ${timestamp}
- Status: running

## Progress
- Current Step: Starting
- Completed Steps: None

## Review History
(Added as tasks complete)

## Final Summary
(Added on completion)
EOF

  echo "$task_id"
}

# set_completed <chat_id> <task_id> <summary>
set_completed() {
  local chat_id="$1"
  local task_id="$2"
  local summary="$3"
  local timestamp=$(get_timestamp)

  local summary_file="$TASKS_DIR/${chat_id}.md"
  local detail_file="$TASKS_DIR/${chat_id}-${task_id}.md"

  # Update summary file
  sed -i "s/- Status: running/- Status: completed/" "$summary_file"
  sed -i "s/- Has completed task: false/- Has completed task: true/" "$summary_file"
  sed -i "s/- Result summary:/- Result summary: ${summary}/" "$summary_file"

  # Update detail file
  if [ -f "$detail_file" ]; then
    sed -i "s/- Status: running/- Status: completed/" "$detail_file"
    echo "" >> "$detail_file"
    echo "## Final Summary" >> "$detail_file"
    echo "- Completed: ${timestamp}" >> "$detail_file"
    echo "- Summary: ${summary}" >> "$detail_file"
  fi
}

# set_failed <chat_id> <task_id> <error>
set_failed() {
  local chat_id="$1"
  local task_id="$2"
  local error="$3"
  local timestamp=$(get_timestamp)

  local summary_file="$TASKS_DIR/${chat_id}.md"
  local detail_file="$TASKS_DIR/${chat_id}-${task_id}.md"

  # Update summary file
  sed -i "s/- Status: running/- Status: failed/" "$summary_file"
  sed -i "s/- Has completed task: false/- Has completed task: true/" "$summary_file"
  sed -i "s/- Result summary:/- Result summary: ERROR: ${error}/" "$summary_file"

  # Update detail file
  if [ -f "$detail_file" ]; then
    sed -i "s/- Status: running/- Status: failed/" "$detail_file"
    echo "" >> "$detail_file"
    echo "## Final Summary" >> "$detail_file"
    echo "- Failed: ${timestamp}" >> "$detail_file"
    echo "- Error: ${error}" >> "$detail_file"
  fi
}

# get_task_id <chat_id> - Returns current task ID or empty
get_task_id() {
  local chat_id="$1"
  local summary_file="$TASKS_DIR/${chat_id}.md"

  if [ ! -f "$summary_file" ]; then
    return
  fi

  grep -m1 "^- Task ID:" "$summary_file" | sed 's/- Task ID: //'
}

# update_last_message <chat_id> <msg_id>
update_last_message() {
  local chat_id="$1"
  local msg_id="$2"
  local timestamp=$(get_timestamp)
  local summary_file="$TASKS_DIR/${chat_id}.md"

  if [ -f "$summary_file" ]; then
    sed -i "s/- Timestamp: .*/- Timestamp: ${timestamp}/" "$summary_file"
    sed -i "s/- Msg ID: .*/- Msg ID: ${msg_id}/" "$summary_file"
  fi
}

# check_idle <chat_id> [threshold_seconds] - Returns true if idle > threshold
check_idle() {
  local chat_id="$1"
  local threshold="${2:-60}"
  local summary_file="$TASKS_DIR/${chat_id}.md"

  if [ ! -f "$summary_file" ]; then
    echo "true"
    return
  fi

  local last_ts=$(grep -m1 "^- Timestamp:" "$summary_file" | sed 's/- Timestamp: //')
  if [ -z "$last_ts" ]; then
    echo "true"
    return
  fi

  local last_epoch=$(date -d "$last_ts" +%s 2>/dev/null || echo "0")
  local now_epoch=$(date +%s)
  local diff=$((now_epoch - last_epoch))

  if [ "$diff" -gt "$threshold" ]; then
    echo "true"
  else
    echo "false"
  fi
}

# has_pending_notification <chat_id> - Returns true|false
has_pending_notification() {
  local chat_id="$1"
  local summary_file="$TASKS_DIR/${chat_id}.md"

  if [ ! -f "$summary_file" ]; then
    echo "false"
    return
  fi

  local has_completed=$(grep "^- Has completed task:" "$summary_file" | sed 's/- Has completed task: //')
  if [ "$has_completed" = "true" ]; then
    echo "true"
  else
    echo "false"
  fi
}

# clear_notification <chat_id>
clear_notification() {
  local chat_id="$1"
  local summary_file="$TASKS_DIR/${chat_id}.md"

  if [ -f "$summary_file" ]; then
    sed -i "s/- Has completed task: true/- Has completed task: false/" "$summary_file"
  fi
}

# get_notification_summary <chat_id>
get_notification_summary() {
  local chat_id="$1"
  local summary_file="$TASKS_DIR/${chat_id}.md"

  if [ -f "$summary_file" ]; then
    grep "^- Result summary:" "$summary_file" | sed 's/- Result summary: //'
  fi
}

# Command dispatcher
case "$1" in
  get_status) get_status "$2" ;;
  set_running) set_running "$2" "$3" "$4" ;;
  set_completed) set_completed "$2" "$3" "$4" ;;
  set_failed) set_failed "$2" "$3" "$4" ;;
  get_task_id) get_task_id "$2" ;;
  update_last_message) update_last_message "$2" "$3" ;;
  check_idle) check_idle "$2" "${3:-60}" ;;
  has_pending_notification) has_pending_notification "$2" ;;
  clear_notification) clear_notification "$2" ;;
  get_notification_summary) get_notification_summary "$2" ;;
  *)
    echo "Usage: $0 <command> [args...]"
    echo "Commands:"
    echo "  get_status <chat_id>"
    echo "  set_running <chat_id> <plan_file> <description>"
    echo "  set_completed <chat_id> <task_id> <summary>"
    echo "  set_failed <chat_id> <task_id> <error>"
    echo "  get_task_id <chat_id>"
    echo "  update_last_message <chat_id> <msg_id>"
    echo "  check_idle <chat_id> [threshold_seconds]"
    echo "  has_pending_notification <chat_id>"
    echo "  clear_notification <chat_id>"
    echo "  get_notification_summary <chat_id>"
    exit 1
    ;;
esac
SCRIPT
chmod +x scripts/task-state.sh
```

**Step 2: Verify script is executable**

Run: `ls -la scripts/task-state.sh`
Expected: Shows executable permissions (-rwxr-xr-x)

**Step 3: Test get_status command**

Run: `./scripts/task-state.sh get_status 123456789`
Expected: `none`

**Step 4: Test set_running command**

Run: `./scripts/task-state.sh set_running 123456789 "docs/plans/test.md" "Test task"`
Expected: Returns a task_id like `task_1234567890`

**Step 5: Verify files were created**

Run: `ls -la state/tasks/`
Expected: Shows `123456789.md` and `123456789-task_*.md`

**Step 6: Test get_status returns running**

Run: `./scripts/task-state.sh get_status 123456789`
Expected: `running`

**Step 7: Clean up test files**

```bash
rm -f state/tasks/123456789.md state/tasks/123456789-task_*.md
```

**Step 8: Commit**

```bash
git add scripts/task-state.sh
git commit -m "feat(scripts): add task-state.sh helper for background task management"
```

---

## Task 3: Create background-tasks skill

**Files:**
- Create: `.claude/skills/background-tasks/SKILL.md`

**Step 1: Create skill directory**

```bash
mkdir -p .claude/skills/background-tasks
```

**Step 2: Create SKILL.md**

```markdown
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
```

**Step 3: Write SKILL.md**

```bash
cat > .claude/skills/background-tasks/SKILL.md << 'EOF'
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
EOF
```

**Step 4: Verify skill file**

Run: `cat .claude/skills/background-tasks/SKILL.md | head -20`
Expected: Shows skill frontmatter and overview

**Step 5: Commit**

```bash
git add .claude/skills/background-tasks/SKILL.md
git commit -m "feat(skills): add background-tasks skill for non-blocking execution"
```

---

## Task 4: Update Commander with task state management

**Files:**
- Modify: `.claude/skills/commander/SKILL.md`

**Step 1: Add task state section to Commander**

Add new section after "Message Flow" section (after line ~128). The new content:

```markdown
## Task State Management

Pichu tracks background tasks per chat using `state/tasks/{chat_id}.md`.

### On each message:

1. **Check for smart notification:**
```bash
# After parsing message, before ACK
if [ "$(./scripts/task-state.sh has_pending_notification $CHAT_ID)" = "true" ] && \
   [ "$(./scripts/task-state.sh check_idle $CHAT_ID 60)" = "true" ]; then
    SUMMARY=$(./scripts/task-state.sh get_notification_summary $CHAT_ID)
    ./scripts/reply.sh $BOT_ID $CHAT_ID "Background task done! $SUMMARY"
    ./scripts/task-state.sh clear_notification $CHAT_ID
fi
```

2. **Update last message time:**
```bash
./scripts/task-state.sh update_last_message $CHAT_ID $MSG_ID
```

3. **Check for running task before starting new one:**
```bash
STATUS=$(./scripts/task-state.sh get_status $CHAT_ID)
TASK_ID=$(./scripts/task-state.sh get_task_id $CHAT_ID)

if [ "$STATUS" = "running" ]; then
    case "$MESSAGE" in
        /status)
            # Report task status
            ./scripts/reply.sh $BOT_ID $CHAT_ID "Task $TASK_ID still running..."
            ;;
        /stop)
            # Stop the task
            TaskStop(task_id=$TASK_ID)
            ./scripts/task-state.sh set_failed $CHAT_ID $TASK_ID "Stopped by user"
            ./scripts/reply.sh $BOT_ID $CHAT_ID "Task stopped."
            ;;
        *)
            # User chatting while task runs - respond briefly
            ./scripts/reply.sh $BOT_ID $CHAT_ID "Still working on background task. /status for update."
            ;;
    esac
    return  # Don't start new task
fi
```

### Commands (updated)

| Command | Action |
|---------|--------|
| /status | Show running task status + pending notifications |
| /stop | Stop current background task |
| /clear | Reset session file |
| /compact | Trigger strategic compact |
| /save | Force memory update |
| /tasks | List recent tasks (last 5) |

## Workflow Skills (updated)

| Skill | When to Use |
|------|-------------|
| `using-skill` | Detect intent before processing |
| `brainstorming` | Creative work - features, components, functionality |
| `writing-plans` | After design approved - create implementation plan |
| `background-tasks` | After plan approved - execute in background |
| `subagent-driven-development` | Used by background-tasks for actual execution |
| `verification-before-completion` | Before claiming work is complete |
```

**Step 2: Update Command Detection section**

Find the "Command Detection" section (around line 128-137) and update to:

```markdown
## Command Detection

If message starts with `/`, handle as command:

| Command | Action |
|---------|--------|
| /status | Show running task status + pending notifications |
| /stop | Stop current background task (TaskStop) |
| /clear | Reset session file |
| /compact | Trigger strategic compact |
| /save | Force memory update |
| /tasks | List recent task files |
```

**Step 3: Update Step 3 (Detect Intent) in Message Flow**

Find "Step 3: Detect Intent" and update the table:

```markdown
### Step 3: Detect Intent

| Intent | Action |
|--------|--------|
| **brainstorm/design** | Use `brainstorming` skill |
| **implement/build** | Use `background-tasks` skill (if plan exists) |
| **status/question** | Answer directly |
```

**Step 4: Add Step 2a for smart notification**

Insert after Step 1 (Parse message), before Step 2 (Send ACK):

```markdown
### Step 1b: Check for smart notification

Before ACK, check if there's a completed task to notify:

```bash
if [ "$(./scripts/task-state.sh has_pending_notification $CHAT_ID)" = "true" ] && \
   [ "$(./scripts/task-state.sh check_idle $CHAT_ID 60)" = "true" ]; then
    SUMMARY=$(./scripts/task-state.sh get_notification_summary $CHAT_ID)
    ./scripts/reply.sh $BOT_ID $CHAT_ID "Background task complete! $SUMMARY"
    ./scripts/task-state.sh clear_notification $CHAT_ID
fi
```
```

**Step 5: Commit**

```bash
git add .claude/skills/commander/SKILL.md
git commit -m "feat(commander): add task state management and smart notification"
```

---

## Task 5: Update writing-plans execution handoff

**Files:**
- Modify: `.claude/skills/writing-plans/SKILL.md`

**Step 1: Update "Execution Handoff" section**

Replace the entire "Execution Handoff" section (lines 97-117) with:

```markdown
## Execution Handoff

After saving the plan, ask user to start background execution:

**"Plan saved to `docs/plans/<filename>.md`. Start background execution now?"**

**If user approves (yes/go/start/approve):**
- **REQUIRED SUB-SKILL:** Use `background-tasks` skill
- Plan executes in background
- Pichu stays responsive to new messages
- Smart notification when complete

**If user declines:**
- Plan is saved and ready for later
- User can start execution anytime by saying "execute the plan"
```

**Step 2: Verify change**

Run: `grep -A 15 "Execution Handoff" .claude/skills/writing-plans/SKILL.md`
Expected: Shows new simplified handoff with background-tasks

**Step 3: Commit**

```bash
git add .claude/skills/writing-plans/SKILL.md
git commit -m "feat(writing-plans): update execution handoff to use background-tasks"
```

---

## Task 6: Update session template for last active tracking

**Files:**
- Modify: `state/sessions/TEMPLATE.md`

**Step 1: Update template**

Replace current content with:

```markdown
# Session: Chat {chat_id}

## Context
- User: {username}
- Started: {timestamp}
- Last active: {timestamp}

## Current Mode
idle

## Active Task
None

## Recent Topics
- (tracked automatically)

## Recent Messages
### User ({time})
{user_message}

### Pichu ({time})
{pichu_response}
```

**Step 2: Write updated template**

```bash
cat > state/sessions/TEMPLATE.md << 'EOF'
# Session: Chat {chat_id}

## Context
- User: {username}
- Started: {timestamp}
- Last active: {timestamp}

## Current Mode
idle

## Active Task
None

## Recent Topics
- (tracked automatically)

## Recent Messages
### User ({time})
{user_message}

### Pichu ({time})
{pichu_response}
EOF
```

**Step 3: Commit**

```bash
git add state/sessions/TEMPLATE.md
git commit -m "feat(sessions): add last active tracking to session template"
```

---

## Task 7: Test background task execution

**Files:**
- None (verification only)

**Step 1: Verify all files exist**

Run: `ls -la state/tasks/ scripts/task-state.sh .claude/skills/background-tasks/SKILL.md`
Expected: All files present

**Step 2: Test task-state.sh workflow**

```bash
# Set task running
TASK_ID=$(./scripts/task-state.sh set_running 999999 "docs/plans/test.md" "Test task")
echo "Task ID: $TASK_ID"

# Check status
./scripts/task-state.sh get_status 999999

# Update message time
./scripts/task-state.sh update_last_message 999999 100

# Check idle (should be false - just updated)
./scripts/task-state.sh check_idle 999999 60

# Set completed
./scripts/task-state.sh set_completed 999999 "$TASK_ID" "All done!"

# Check notification
./scripts/task-state.sh has_pending_notification 999999
./scripts/task-state.sh get_notification_summary 999999

# Clear notification
./scripts/task-state.sh clear_notification 999999
./scripts/task-state.sh has_pending_notification 999999

# Cleanup
rm -f state/tasks/999999.md state/tasks/999999-*.md
```

Expected: All commands execute without error

**Step 3: Verify Commander skill mentions background-tasks**

Run: `grep -c "background-tasks" .claude/skills/commander/SKILL.md`
Expected: Count > 0

**Step 4: Verify writing-plans mentions background-tasks**

Run: `grep -c "background-tasks" .claude/skills/writing-plans/SKILL.md`
Expected: Count > 0

**Step 5: Final commit (if any uncommitted changes)**

```bash
git status
# If clean, nothing to commit
```

---

## Summary

After all tasks complete:
- Background tasks run non-blocking with `run_in_background: true`
- Task state tracked in `state/tasks/` files
- Smart notification on completion (if idle > 60s)
- `/status`, `/stop`, `/save`, `/tasks` commands available
- Commander checks for pending notifications on each message
- Memory updates triggered after task completion
