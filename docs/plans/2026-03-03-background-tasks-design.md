# Background Tasks + Memory Updates Design

> **For Claude:** Use `subagent-driven-development` skill wrapped by new `background-tasks` skill.

**Goal:** Enable Pichu to run implementation tasks in background while staying responsive to new messages, with automatic memory updates.

**Architecture:** New `background-tasks` skill wraps `subagent-driven-development` with `run_in_background: true`. File-based task tracking + smart notification.

**Tech Stack:** Node.js/TypeScript (gateway), Bash scripts, Markdown state files

---

## Skill Architecture

```
brainstorming → writing-plans → [Ask user: Start execution?]
                                     ↓ Yes
                              background-tasks (NEW)
                                     ↓
                         subagent-driven-development
                         (run_in_background: true)
                         (auto-reviews, no checkpoints)
                                     ↓
                              Smart notification when done
```

### New Skill: `background-tasks`

**Purpose:** Execute implementation plans in background while Pichu stays responsive.

**Location:** `.claude/skills/background-tasks/SKILL.md`

**Behavior:**
- Wraps `subagent-driven-development` with `run_in_background: true`
- No checkpoint pauses - auto-reviews continue automatically
- Tracks state in `state/tasks/{chat_id}.md`
- Smart notification when complete
- User can chat while task runs

---

## Design Decisions (User Approved)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Task execution | Background (`run_in_background: true`) | Pichu stays responsive |
| New message handling | Always respond | User can chat while task runs |
| Completion notification | Smart notify | Auto-notify if idle, silent if chatting |
| Task concurrency | One at a time per chat | Simpler, no conflicts |
| Memory updates | After each task | Persistent session needs regular updates |
| Skill approach | New `background-tasks` skill | Clean separation, reusable |

---

## State File Structure

### New: `state/tasks/` directory

```
state/tasks/
├── {chat_id}.md              # Current/last task summary + last message time
├── {chat_id}-{task_id}.md    # Detailed state while running (archived after)
└── TEMPLATE.md               # Template for new task files
```

### `state/tasks/{chat_id}.md` - Summary file

```markdown
# Task Summary for Chat 195061634

## Last Message Time
- Timestamp: 2026-03-03T22:05:00Z
- Msg ID: 702

## Current/Last Task
- Task ID: task_abc123
- Description: Implement background task support
- Status: running | completed | failed
- Started: 2026-03-03T22:00:00Z
- Completed: 2026-03-03T22:30:00Z (if done)

## Pending Notification
- Has completed task: true
- Result summary: "Done! 3 files changed..."
```

### `state/tasks/{chat_id}-{task_id}.md` - Detailed task file

Created when task starts, kept as history after completion:

```markdown
# Task: task_abc123

## Meta
- Chat ID: 195061634
- Plan File: docs/plans/2026-03-03-background-tasks.md
- Started: 2026-03-03T22:00:00Z
- Status: running

## Progress
- Current Step: Task 2/5
- Completed Steps: Task 1 (spec review passed, code review passed)

## Review History
### Task 1: Create task state directory
- Implementer: completed
- Spec Review: passed
- Code Review: passed (minor: extracted constant)

## Final Summary (added on completion)
- Files Changed: 3
- Commits: 2
- Tests: 5/5 passing
```

### Updated: `state/sessions/{chat_id}.md`

Session context (created on first message):

```markdown
# Session: Chat 195061634

## Context
- User: Jeff
- Started: 2026-03-03T21:00:00Z
- Last active: 2026-03-03T22:05:00Z

## Recent Topics
- Background task design
- Memory system review

## Pending Actions
- None
```

### Updated: `state/memory/project-status.md`

Added after task completion:

```markdown
## Recent Decisions
- 2026-03-03: Background task support implemented
- 2026-03-03: Memory update mechanism added

## Active Work
- Branch: feature/background-tasks
- Status: Implementation complete, testing
```

---

## Message Flow (Updated Commander)

### Step 1: Parse message
Extract chat_id, bot_id, msg_id, reply_to, file, message.

### Step 2: Check task state + smart notify
```bash
TASK_FILE="state/tasks/${CHAT_ID}.md"
if has_pending_notification && is_idle(>60s); then
    send_notification()
    clear_pending_notification()
fi
```

### Step 3: Send ACK
Always ACK the new message immediately.

### Step 4: Check for running task
```
if task_running:
    if message == "/status":
        report_task_status()
    elif message == "/stop":
        TaskStop(task_id)
        reply("Task stopped.")
    else:
        reply("Still working on [task]. /status for update.")
        return  # Don't start new task
```

### Step 5: Detect intent
```
if intent == "brainstorm/design":
    use brainstorming skill
elif intent == "implement" and has_plan:
    ask: "Start background execution?"
    if yes: use background-tasks skill
elif intent == "implement" and no_plan:
    use brainstorming → writing-plans first
```

### Step 6: Update last message time
```bash
update_last_message_time(chat_id, msg_id)
```

---

## background-tasks Skill Flow

### When invoked (after writing-plans approval):

1. **Read plan file** - Load implementation plan
2. **Create task state files**:
   - `state/tasks/{chat_id}-{task_id}.md` - Detailed progress tracking
   - Update `state/tasks/{chat_id}.md` - Set current task
3. **Spawn background subagent**:
   ```
   Task(
       description: "Execute plan: [plan name]"
       prompt: "Use subagent-driven-development to execute this plan..."
       run_in_background: true
   )
   ```
4. **Reply to user** - "Started in background. I'll notify when done."
5. **Return to message loop** - Ready for new messages

### On task completion:

1. **Update task files**:
   - `{chat_id}-{task_id}.md` - Add final summary, status: completed
   - `{chat_id}.md` - Merge summary, set pending notification
2. **Update memory files** - Add to project-status.md, etc.
3. **Set pending notification** - Will notify on next interaction or when idle

---

## Memory Update Mechanism

### When to Update
1. **After task completion** - Subagent reports what was done
2. **On /save command** - Explicit save request
3. **On significant learnings** - User requests "remember this"

### What to Update

| File | Update Trigger |
|------|----------------|
| `project-status.md` | Task completed, branch changed, blockers |
| `preferences.md` | User corrects behavior, expresses preference |
| `knowledge/patterns.md` | Reusable solution discovered |
| `knowledge/gotchas.md` | Issue encountered and resolved |

### Update Format
Append to "Recent Decisions" or relevant section with timestamp:
```markdown
- 2026-03-03: [Decision/learning description]
```

---

## Commands

| Command | Action |
|---------|--------|
| `/status` | Show running task status + pending notifications |
| `/stop` | Stop current background task |
| `/save` | Force memory update |
| `/tasks` | List recent tasks (last 5) |

---

## Edge Cases

### Task fails
- Update task state with `status: failed`
- Set pending notification with error summary
- User notified on next interaction

### User sends many messages while task runs
- Each message gets a brief response
- Original task continues uninterrupted
- No new tasks start until current completes

### Session restart (tmux dies)
- Task state persists in file
- On restart, check for running tasks
- Report "Previous task may be incomplete"

### Multiple chats
- Each chat has independent task state
- Pichu can run one task per chat simultaneously
- No cross-chat interference

---

## Files to Create/Modify

### New Files

1. **`.claude/skills/background-tasks/SKILL.md`**
   - New skill that wraps subagent-driven-development
   - Background execution + state tracking
   - Smart notification logic

2. **`state/tasks/` directory**
   - `.gitkeep` - Keep directory in git
   - `TEMPLATE.md` - Template for task files
   - `{chat_id}.md` - Created on first message (summary + last message time)
   - `{chat_id}-{task_id}.md` - Created when task starts (detailed progress)

3. **`scripts/task-state.sh`**
   - `get_task_status(chat_id)` - Read from `{chat_id}.md`
   - `set_task_running(chat_id, task_id, description)` - Create both files
   - `set_task_completed(chat_id, task_id, summary)` - Update both files
   - `check_idle(chat_id)` - Returns true if > 60s since last message
   - `merge_task_summary(chat_id, task_id)` - Copy summary from task file to chat file

### Modified Files

1. **`.claude/skills/commander/SKILL.md`**
   - Update "Message Flow" section
   - Add "Task State Management" section
   - Update "Command Detection" section
   - Reference new `background-tasks` skill

2. **`.claude/skills/writing-plans/SKILL.md`**
   - Update "Execution Handoff" section
   - Change from two options to single `background-tasks` option

3. **`state/sessions/TEMPLATE.md`**
   - Add "Last Active" tracking

---

## Implementation Order

1. Create `state/tasks/` directory + TEMPLATE.md
2. Create `scripts/task-state.sh` helper
3. Create `.claude/skills/background-tasks/SKILL.md`
4. Update Commander SKILL.md with new flow
5. Update writing-plans SKILL.md execution handoff
6. Add memory update logic to Commander
7. Test with a simple background task
