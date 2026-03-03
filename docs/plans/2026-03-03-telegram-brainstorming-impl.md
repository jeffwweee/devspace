# Telegram Mode for Brainstorming Skill - Implementation Plan

> **For Claude:** Use `subagent-driven-development` skill to implement this plan task-by-task.

**Goal:** Add Telegram-specific question handling to brainstorming skill using reply.sh instead of AskUserQuestion.

**Architecture:** Add a "Telegram Mode" section to the existing brainstorming skill file that instructs Claude how to ask questions via Telegram.

**Tech Stack:** Markdown skill file, Bash reply.sh script

---

## Task 1: Add Telegram Mode section to brainstorming skill

**Files:**
- Modify: `.claude/skills/brainstorming/SKILL.md`

**Step 1: Read current skill file**

Run: `cat .claude/skills/brainstorming/SKILL.md`
Note: Find the line after "## The Process" section ends (around line 77)

**Step 2: Add Telegram Mode section**

Insert after line 77 (after "Be ready to go back and clarify if something doesn't make sense"):

```markdown

## Telegram Mode

When running in Commander context (Telegram), use Telegram-specific question handling:

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

**Step 3: Verify the change**

Run: `grep -A 30 "## Telegram Mode" .claude/skills/brainstorming/SKILL.md`
Expected: Shows the new section content

**Step 4: Commit**

```bash
git add .claude/skills/brainstorming/SKILL.md
git commit -m "feat(brainstorming): add Telegram mode for question handling

Add Telegram-specific section that instructs Claude to use reply.sh
instead of AskUserQuestion when running in Commander context.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 2: Verify the skill works in Commander context

**Files:**
- None (verification only)

**Step 1: Verify skill file syntax**

Run: `head -30 .claude/skills/brainstorming/SKILL.md`
Expected: Shows frontmatter and overview without syntax errors

**Step 2: Verify Telegram Mode section exists**

Run: `grep -c "Telegram Mode" .claude/skills/brainstorming/SKILL.md`
Expected: 1 (or more if mentioned elsewhere)

**Step 3: Verify AskUserQuestion warning exists**

Run: `grep -c "DO NOT use AskUserQuestion" .claude/skills/brainstorming/SKILL.md`
Expected: 1

---

## Summary

After all tasks complete:
- Brainstorming skill has Telegram Mode section
- Claude will use reply.sh for questions in Commander context
- No interactive UI blocking in Telegram flow
