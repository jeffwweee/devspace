# Quick Wins Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use subagent-driven-development to implement this plan task-by-task.

**Goal:** Add typing indicator and varied response phrases to make Pichu feel more responsive and natural.

**Architecture:** Gateway provides /typing endpoint, Pichu calls it after ACK with 5s refresh. Phrases loaded from memory file on session start, random selection per category.

**Tech Stack:** TypeScript (gateway), Bash (scripts), Markdown (memory)

---

## Task 1: Add /typing Endpoint to Gateway

**Files:**
- Modify: `gateway/src/index.ts:207` (after /reply endpoint)

**Step 1: Add typing endpoint after /reply endpoint**

Add this code after the `/reply` endpoint (around line 207):

```typescript
// Typing endpoint - called by Pichu to show typing indicator
app.post('/typing', async (req, res) => {
  const { bot_id, chat_id } = req.body;

  if (!bot_id || !chat_id) {
    res.status(400).json({ error: 'Missing required fields: bot_id, chat_id' });
    return;
  }

  const botToken = process.env[`TELEGRAM_BOT_TOKEN_${bot_id.toUpperCase()}`];
  if (!botToken) {
    res.status(400).json({ error: `Unknown bot: ${bot_id}` });
    return;
  }

  try {
    const response = await fetch(
      `https://api.telegram.org/bot${botToken}/sendChatAction`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ chat_id, action: 'typing' })
      }
    );

    const result = await response.json();
    if (!result.ok) {
      console.error('Telegram typing API error:', result);
      res.status(500).json(result);
      return;
    }
    res.json(result);
  } catch (err) {
    console.error('Typing error:', err);
    res.status(500).json({ error: 'Failed to send typing indicator' });
  }
});
```

**Step 2: Rebuild gateway**

Run: `cd /home/jeffwweee/jef/devspace/gateway && npm run build`
Expected: Build succeeds with no errors

**Step 3: Test endpoint manually**

Run: `curl -X POST http://localhost:3100/typing -H "Content-Type: application/json" -d '{"bot_id":"pichu","chat_id":195061634}'`
Expected: `{"ok":true,"result":true}`

**Step 4: Commit**

```bash
git add gateway/src/index.ts
git commit -m "feat(gateway): add /typing endpoint for typing indicator (#5)"
```

---

## Task 2: Create typing.sh Helper Script

**Files:**
- Create: `scripts/typing.sh`

**Step 1: Create typing.sh script**

Create file `scripts/typing.sh` with this content:

```bash
#!/bin/bash
# typing.sh - Send typing indicator to Telegram via gateway
# Usage: ./scripts/typing.sh <bot_id> <chat_id>

BOT_ID="${1:-pichu}"
CHAT_ID="$2"

if [ -z "$CHAT_ID" ]; then
  echo "Usage: $0 <bot_id> <chat_id>"
  exit 1
fi

# Build JSON payload with jq
PAYLOAD=$(jq -n \
  --arg bot_id "$BOT_ID" \
  --argjson chat_id "$CHAT_ID" \
  '{bot_id: $bot_id, chat_id: $chat_id}')

curl -s -X POST http://localhost:3100/typing \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD"
```

**Step 2: Make script executable**

Run: `chmod +x /home/jeffwweee/jef/devspace/scripts/typing.sh`
Expected: No output (success)

**Step 3: Test script**

Run: `/home/jeffwweee/jef/devspace/scripts/typing.sh pichu 195061634`
Expected: `{"ok":true,"result":true}`

**Step 4: Commit**

```bash
git add scripts/typing.sh
git commit -m "feat(scripts): add typing.sh helper for typing indicator (#5)"
```

---

## Task 3: Create Phrases Memory File

**Files:**
- Create: `state/memory/phrases.md`

**Step 1: Create phrases.md file**

Create file `state/memory/phrases.md` with this content:

```markdown
# Response Phrases

Phrases for varied response tone. Categories: ack, progress, complete.

## ack

Used when acknowledging a new message.

- Got it, working on that...
- On it! Let me check...
- Roger that, diving in...
- Sure thing, looking into it...
- Understood, processing...

## progress

Used for long-running operations (optional follow-up messages).

- Still crunching...
- Making progress...
- Working through it...
- Almost there...
- Continuing...

## complete

Used when task is finished.

- Done! Here's the result...
- All set! Summary:
- Finished! Check above ^
- Complete! Here's what I found:
- Ready! Output:
```

**Step 2: Verify file exists**

Run: `cat /home/jeffwweee/jef/devspace/state/memory/phrases.md`
Expected: File content shown

**Step 3: Commit**

```bash
git add state/memory/phrases.md
git commit -m "feat(memory): add phrases.md for varied response tone (#6)"
```

---

## Task 4: Update Commander Skill

**Files:**
- Modify: `.claude/skills/commander/SKILL.md`

**Step 1: Add phrase loading to session start section**

In the "Session Start" section, add loading phrases.md:

```markdown
## Session Start

When starting a new session:

1. **Load memory files:**
   - `state/memory/project-status.md`
   - `state/memory/preferences.md`
   - `state/memory/coding-standards.md`
   - `state/memory/phrases.md`  <!-- ADD THIS LINE -->
```

**Step 2: Add typing indicator instructions**

Add this section after "### Step 2: Send ACK immediately":

```markdown
### Step 2b: Start typing indicator (for long operations)

For tasks that take more than a few seconds, start typing indicator AFTER ACK:

```bash
# Start typing indicator
$PROJECT_ROOT/scripts/typing.sh EXTRACTED_BOT_ID EXTRACTED_CHAT_ID
```

For very long operations, refresh typing every 5 seconds with background task:

```bash
# Start background typing refresh (returns task_id)
# Note: Implement as needed based on operation length
```
```

**Step 3: Add phrase selection guidance**

Add this section to the "Critical Rules" section:

```markdown
## Phrase Selection

When sending ACKs and responses, use varied phrases from `state/memory/phrases.md`:

| Situation | Category | Example |
|-----------|----------|---------|
| Acknowledging new message | ack | "Got it, working on that..." |
| Long operation update | progress | "Still crunching..." |
| Task completed | complete | "Done! Here's the result..." |

Select randomly from the appropriate category. Do not repeat the same phrase consecutively.
```

**Step 4: Verify changes**

Run: `grep -A5 "phrases.md" /home/jeffwweee/jef/devspace/.claude/skills/commander/SKILL.md`
Expected: Shows the phrases.md loading line

**Step 5: Commit**

```bash
git add .claude/skills/commander/SKILL.md
git commit -m "feat(commander): add typing indicator and phrase selection (#5, #6)"
```

---

## Task 5: Integration Testing

**Files:**
- None (manual testing)

**Step 1: Restart Pichu session**

In tmux, exit current session and restart to load new skill changes.

**Step 2: Send test message from Telegram**

Send: "hello pichu"
Expected:
1. Varied ACK phrase (not "Checking status...")
2. Typing indicator appears in Telegram

**Step 3: Send longer task**

Send: "list all files in the project"
Expected:
1. Varied ACK phrase
2. Typing indicator shows during processing
3. Varied complete phrase in final response

**Step 4: Verify phrase variety**

Send multiple messages and confirm ACK phrases vary.

---

## Summary

| Task | Description | Files |
|------|-------------|-------|
| 1 | Add /typing endpoint | `gateway/src/index.ts` |
| 2 | Create typing.sh | `scripts/typing.sh` |
| 3 | Create phrases.md | `state/memory/phrases.md` |
| 4 | Update Commander | `.claude/skills/commander/SKILL.md` |
| 5 | Integration test | Manual |

**Total estimated time:** 30-45 minutes
