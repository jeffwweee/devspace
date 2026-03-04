---
name: reviewer
description: Use after subagent completes to review work. Performs spec compliance check, code quality review, and confidence scoring.
---

# Reviewer

Two-stage review system with confidence check. Use after subagent completes.

## Review Flow

```
Subagent completes → Spec Compliance → Code Quality → Confidence (≥8/10?) → Notify
```

## Decision Matrix

| Spec | Quality | Confidence | Action |
|------|---------|------------|--------|
| FAIL | - | - | Spawn fix subagent |
| PASS | FAIL | - | Spawn fix subagent |
| PASS | PASS | < 8 | Request manual review |
| PASS | PASS | ≥ 8 | Ready to commit |

## Review Stages

**Stage 1: Spec Compliance** - See `references/spec-checklist.md`

**Stage 2: Code Quality** - See `references/quality-checklist.md`

**Stage 3: Confidence Score** - Rate 1-10, ≥8 to pass

## Notification

Use `scripts/reply.sh` with templates from `references/notification-templates.md`

## Fix Subagent

If review fails, spawn fix subagent with:
```
Task: Fix review issues
Prompt: {list of issues from review}
run_in_background: true
```
