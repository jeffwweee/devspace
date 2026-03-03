# Quick Wins Design: Typing Indicator + Varied Response Tone

**Date:** 2026-03-03
**Issues:** #5, #6
**Approach:** A - Start Simple

## Overview

Add two UX improvements to make Pichu feel more responsive and natural:
1. **Typing indicator** - Shows "typing..." while Pichu processes
2. **Varied response tone** - Different phrases for ACKs, progress, and completion

## Architecture

### Component 1: TypingIndicator Service (Gateway)

- **New endpoint:** `POST /typing`
- **Accepts:** `bot_id`, `chat_id`
- **Action:** Calls Telegram `sendChatAction` API with `typing` action
- **Behavior:** Pichu calls after ACK, refreshes every 5s during work

### Component 2: Phrase System (Memory)

- **New file:** `state/memory/phrases.md`
- **Categories:** `ack`, `progress`, `complete`
- **Loading:** Commander reads on session start
- **Selection:** Random pick from appropriate category

## Data Flow

### Typing Indicator Flow

```
1. Message arrives → Pichu parses [TG:...] prefix
2. Pichu sends ACK → starts typing indicator
3. Background task → refresh typing every 5s
4. Pichu processes request (subagent, etc)
5. Final reply sent → typing stops
```

### Phrase Selection Flow

```
1. Session start → load phrases.md
2. Need ACK → random pick from [ack] category
3. Need progress msg → random from [progress]
4. Need complete msg → random from [complete]
```

## File Format

### state/memory/phrases.md

```markdown
[ack]
Got it, working on that...
On it! Let me check...
Roger that, diving in...

[progress]
Still crunching...
Making progress...
Working through it...

[complete]
Done! Here's the result...
All set! Summary:
Finished! Check above ^
```

## Implementation Details

### Files to Modify

| File | Changes |
|------|---------|
| `gateway/src/index.ts` | Add `POST /typing` endpoint |
| `scripts/typing.sh` | New helper script (similar to reply.sh) |
| `.claude/skills/commander/SKILL.md` | Add typing + phrase selection logic |
| `state/memory/phrases.md` | New file with default phrases |

### Error Handling

- **Typing fails:** Silent failure (non-critical UX feature)
- **Missing phrases:** Fallback to hardcoded defaults
- **Invalid category:** Use `[ack]` as default

### Testing

- **Typing test:** Send message, verify typing indicator shows
- **Phrase test:** Restart session, verify phrase variety
- **Refresh test:** Long operation, verify typing refreshes

## Future Extensions

- `/add-phrase <category> <phrase>` command for manual additions
- Hook into learning system (#7) to auto-promote successful phrases
- Track phrase effectiveness (user replies, reactions)
