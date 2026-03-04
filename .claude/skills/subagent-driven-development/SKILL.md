---
name: subagent-driven-development
description: Use when executing implementation plans with independent tasks in the current session
---

# Subagent-Driven Development

Execute plans by dispatching fresh subagent per task, with two-stage review.

## Core Principle

Fresh subagent per task + two-stage review = high quality, fast iteration

**Why fresh subagents?**
- No context pollution from previous tasks
- Clean mental model per task
- Faster iteration (no baggage)

## Process

```
Read plan → Create TodoWrite → For each task:
  Dispatch implementer → Spec review → Quality review → Mark complete
```

See `references/flow.md` for detailed workflow.

## Review Stages

**Stage 1: Spec Compliance** - Did we build what was asked?
**Stage 2: Code Quality** - Is it well-built?

See `references/review.md` for review details.

## Task Tool Template

```
Task:
  subagent_type: general-purpose
  model: sonnet
  description: "Task name"
  prompt: "[Full task text with context]"
```

## Critical Rules

- Never skip reviews (spec OR quality)
- Spec compliance MUST pass before quality review
- Reviewer finds issues → implementer fixes → re-review
- Don't parallel dispatch (causes conflicts)

## Integration

Integrates: writing-plans, reviewer, verification-before-completion

## When NOT to Use

- Single-line changes
- Purely informational tasks
- Tasks requiring deep session context
