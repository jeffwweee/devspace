# Telegram Mode for Brainstorming Skill

> **For Claude:** Design approved. Use `writing-plans` skill to create implementation plan.

**Goal:** Enable brainstorming skill to work with Telegram flow by using reply.sh instead of AskUserQuestion.

**Architecture:** Add a "Telegram Mode" section to existing brainstorming skill that specifies how to ask questions via Telegram.

**Tech Stack:** Markdown skill file, Bash reply.sh script

---

## Problem

The brainstorming skill instructs Claude to "ask questions one at a time" but doesn't specify HOW. When running in Commander context (Telegram), Claude defaults to using AskUserQuestion which creates an interactive UI that Telegram users cannot see or interact with.

## Solution

Add a "Telegram Mode" section to the brainstorming skill that explicitly tells Claude to:
1. Use `reply.sh` to send questions to Telegram
2. Format questions with lettered options (A, B, C)
3. Wait for the next tmux injection for the user's response

## Design Details

### New Section: "Telegram Mode"

Location: After "The Process" section in brainstorming/SKILL.md

Content:
```markdown
## Telegram Mode

When running in Commander context ( Telegram), use Telegram-specific question handling:

**DO NOT use AskUserQuestion** - the interactive UI is not visible to Telegram users.

**Instead, use reply.sh:**
```bash
$PROJECT_ROOT/scripts/reply.sh $BOT_ID $CHAT_ID "Your question here

A) Option one
B) Option two
C) Option three

Reply A, B, or C" $MSG_ID
```

**Format for multiple choice:**
- Letter each option (A, B, C)
- One line per option
- End with "Reply X, Y, or Z"

**Wait for response:**
- Response comes via tmux injection
- Parse the next `[TG:...]` message for the user's answer
- Continue brainstorming flow

**Open-ended questions:**
- Just ask the question without options
- Wait for tmux injection with response
```

### Changes Summary

| File | Change |
|------|--------|
| `.claude/skills/brainstorming/SKILL.md` | Add "Telegram Mode" section (~20 lines) |

## Question Format Examples

**Multiple choice:**
```
Which approach?
A) Add Telegram-specific section
B) Create wrapper skill
C) Add channel detection

Reply A, B, or C
```

**Open-ended:**
```
What's the main use case for this feature?
```

## Success Criteria

- [ ] Brainstorming skill has Telegram Mode section
- [ ] Questions are sent via reply.sh in Commander context
- [ ] Claude waits for tmux injection for responses
- [ ] No AskUserQuestion used in Telegram flow

---

## Approved

- Date: 2026-03-03
- User: Jeff
- Chat ID: 195061634
