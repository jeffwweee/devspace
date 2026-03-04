---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."
---

# Brainstorming

Turn ideas into designs through collaborative dialogue.

## HARD-GATE

**DO NOT write code or implement until design is approved.** Every project, every issue, every bugfix. Even "simple" ones.

## Process

1. Explore project context (files, docs, commits)
2. Ask clarifying questions (one at a time)
3. Propose 2-3 approaches with trade-offs
4. Present design section-by-section, get approval
5. Write design doc → commit
6. Invoke `writing-plans` skill

## Telegram Mode

**DO NOT use AskUserQuestion** - not visible in Telegram.

Use `scripts/reply.sh` with lettered options. See `references/telegram-format.md` for examples.

## After Design Approved

Design doc (WHAT) → Implementation plan (HOW) → Execution

1. Save design to `docs/plans/YYYY-MM-DD-<topic>-design.md`
2. Send via `scripts/send-file.sh` for review
3. If approved → invoke `writing-plans` skill
4. If changes → revise and resend

**Approval signals:** "approved", "looks good", "yes proceed", "LGTM"

## Key Principles

- One question at a time
- Multiple choice preferred
- YAGNI ruthlessly
- Explore 2-3 approaches
- Incremental validation
