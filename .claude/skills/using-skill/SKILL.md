---
name: using-skill
description: Use when starting any conversation - establishes how to find and use skills. If you think there is even a 1% chance a skill might apply, invoke it BEFORE any response including clarifying questions. This skill is ALWAYS relevant - check it before doing anything else.
---

# Using Skills

## The Rule

Invoke relevant or requested skills BEFORE any response or action. Even a 1% chance a skill might apply means you should invoke the skill to check.

**IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.**

This is not negotiable. This is not optional. You cannot rationalize your way out of this.

If an invoked skill turns out to be wrong for the situation, you don't need to use it.

---

## Decision Flow

Follow this sequence before responding to any user message:

```
1. User message received
   ↓
2. About to EnterPlanMode?
   │
   ├─ YES → Have you already done brainstorming/planning?
   │         │
   │         ├─ NO → Invoke brainstorming skill first
   │         │
   │         └─ YES → Continue to step 3
   │
   └─ NO → Continue to step 3
   ↓
3. MIGHT any skill apply? (even 1% chance)
   │
   ├─ YES → Invoke the Skill tool NOW
   │         ↓
   │         Announce: "Using [skill] to [purpose]"
   │         ↓
   │         Does the skill have a checklist?
   │         │
   │         ├─ YES → Create a todo item for each checklist item
   │         │
   │         └─ NO → Follow the skill instructions exactly
   │
   └─ NO → You may now respond (including clarifying questions)
```

---

## Dev Workspace Workflow Skills

When implementing features or making changes, follow this workflow:

| Order | Skill | When to Use |
|-------|-------|-------------|
| 1 | `brainstorming` | Before ANY implementation - explores requirements, proposes approaches |
| 2 | `writing-plans` | After design approved - creates bite-sized tasks |
| 3 | `subagent-driven-development` | When delegating implementation - fresh subagent per task + reviews |
| 4 | `verification-before-completion` | Before claiming completion - run verification commands |

**Workflow:**
```
Brainstorm → Design → Plan → Delegate → Spec Check → Quality Check → Complete
```

---

## Red Flags - Stop and Check

If you catch yourself thinking any of these, STOP. You're rationalizing. Check for skills instead.

| Thought | Reality |
|---------|---------|
| "This is just a simple question" | Questions are tasks. Check for skills. |
| "I need more context first" | Skill check comes BEFORE clarifying questions. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first. |
| "I can check git/files quickly" | Files lack conversation context. Check for skills. |
| "Let me gather information first" | Skills tell you HOW to gather information. |
| "This doesn't need a formal skill" | If a skill exists, use it. |
| "I remember this skill" | Skills evolve. Read current version. |
| "This doesn't count as a task" | Action = task. Check for skills. |
| "The skill is overkill" | Simple things become complex. Use it. |
| "I'll just do this one thing first" | Check BEFORE doing anything. |
| "This feels productive" | Undisciplined action wastes time. Skills prevent this. |
| "I know what that means" | Knowing the concept ≠ using the skill. Invoke it. |

---

## Skill Priority

When multiple skills could apply, use this order:

1. **Workflow skills first** (brainstorming, writing-plans, subagent-driven-development, verification-before-completion) - these determine HOW to approach the task
2. **Process skills second** (debugging, systematic-debugging) - these guide problem-solving
3. **Implementation skills third** (nodejs-backend-typescript, telegram-bot-grammy) - these guide execution

Examples:
- "Let's build X" → brainstorming first, then writing-plans, then implementation
- "Fix this bug" → systematic-debugging first, then domain-specific skills
- "Implement this plan" → subagent-driven-development, then verification-before-completion

---

## Skill Types

| Type | Approach |
|------|----------|
| **Rigid** (TDD, debugging) | Follow exactly. Don't adapt away discipline. |
| **Flexible** (patterns) | Adapt principles to context. |

The skill itself tells you which type it is.

---

## User Instructions

Instructions say WHAT, not HOW. "Add X" or "Fix Y" doesn't mean skip workflows. Always check for relevant skills first.
