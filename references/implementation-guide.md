# TAV Workflow Implementation Guide

This guide covers operational details that go beyond the specification in `SKILL.md`. When this guide and `SKILL.md` disagree, `SKILL.md` wins. Command tables, output contracts, and the escalation format are defined there and are not repeated here.

## Operating Model

```text
Phase 0: Continuity Check - L1 only; resume or initialize durable state
Phase 1: Thinker  - read-only analysis and plan
Phase 2: Actor    - minimal planned edits
Phase 3: Verifier - diff review, independent checks, quality gates
Phase 4: Complete - final report and state cleanup/archive
```

## State Lifecycle

### When to create `.tav/state.json`

Create the file only when at least one of these holds:

- The task will likely span more than one session.
- The task needs multiple Actor-Verifier iterations.
- The user explicitly asks for resumable progress.

Otherwise rely on the platform's native task tracker. L0 tasks never create state.

### Creation

1. Read `references/templates/state.json`.
2. Copy the schema exactly - snake_case field names, lowercase phase enums (`thinker|actor|verifier|complete|blocked`).
3. Fill `task_id` as `tav-YYYYMMDD-HHMMSS`, set `start_time` and `last_update` to the current UTC time.

### Updates

- Update `current_phase`, `completed_steps`, and `last_update` at each phase transition.
- Track repeated failures in `failure_counts.by_blocker` and `failure_counts.by_command`; the blocker key, consecutiveness, and re-plan reset rules are defined in `SKILL.md` § "Failure counting semantics" — two consecutive failures of the same key triggers `[PUA-REPORT]`.
- `phase_outputs` holds status plus a short pointer/summary only (e.g. `thinker.status`, an evidence count) — the authoritative phase output is the templated block produced in the session, not a full copy in state. Never duplicate the whole Thinker/Actor/Verifier output into state; it drifts and wastes space.

### Staleness and cleanup

- A state whose `last_update` is older than 7 days is stale: ask the user before resuming or replacing it.
- A state describing a different task: ask the user before replacing or archiving it.
- On completion, archive to `.tav/archive/` or delete the file - only if it belongs to the completed workflow.

### Concurrent tasks

`.tav/state.json` tracks a single task. If two L1 tasks run concurrently in the same project, give each its own state file named `.tav/state-<task_id>.json` and resume from the matching file in Phase 0. Never let two cycles write the same state file — the `failure_counts` and `current_phase` of one task must not leak into another.

## Metrics Rules

Report only measurable facts:

- `files_modified`, `files_created`, `lines_added`, `lines_removed`: take from `git diff --stat` (or the VCS equivalent).
- `iterations`: count of Actor-Verifier loops actually executed.
- Never estimate or invent token usage, cost, or wall-clock duration. These are not observable from inside the session and must not appear in state files or reports.

## Phase Notes

### Thinker

- Determine the tier first; L2 stops here and routes to `spec-driven-develop`.
- In Claude Code, native plan mode can host the Thinker phase; the approved plan is the todo list.
- Each todo item carries: target file or symbol, specific action, risk level, expected verification evidence.
- Output contract: `references/templates/thinker-output.md`.

### Actor

- Actor may read target files or snippets when required by the edit mechanism or to confirm exact context. Actor must not perform new requirement discovery.
- Any structural mismatch between plan and code returns to Thinker with evidence.
- Output contract: `references/templates/actor-output.md`.

### Verifier

- Start from `git diff`, not from the Actor's summary.
- Pick verification commands only after inspecting project files; the evidence-to-command table is in `SKILL.md` Phase 3.
- Do not claim a check passed unless it ran and succeeded. Record unavailable commands under skipped checks.
- Flag consolidation candidates while reviewing — rework lessons and non-obvious root causes surface here, not in Phase 4. Evaluation and capture happen in Phase 4 against the signals in `SKILL.md`.
- Output contract: `references/templates/verifier-output.md`.

## Knowledge Consolidation

The capture signals, never-capture list, and write-target resolution order are defined in `SKILL.md` Phase 4 and are not repeated here. This section covers the mechanics of writing a captured rule.

### Project memory directory layout

The default write target is the project memory directory:

```text
docs/memory/
  MEMORY.md          # index: one line per entry - [title](file.md) - one-line hook
  <topic-slug>.md    # one entry per file: short frontmatter + the rule
```

Entry file frontmatter keeps five fields (`name`, `description`, `type`, `tags`, `applies_to`); the body carries the rule in the entry format below. `tags` is a list of free-form keywords; `applies_to` is a list of file-path globs or module names the rule concerns. Thinker shortlists entries by their `MEMORY.md` index-line hook, opens only the shortlisted files, and uses `tags`/`applies_to` to confirm relevance — so keep the index hook specific enough to shortlist by. On every capture, add or update the entry file and its `MEMORY.md` index line in the same edit batch. The directory is committed with the repo — do not add it to `.gitignore`.

### Entry format

One rule per entry, with frontmatter plus a short body:

```markdown
---
name: null-guard-at-source
description: Guard nullable values once at the owning call site.
type: rule
tags: [typescript, null-safety]
applies_to: ["src/dashboard/**", "src/api/user.ts"]
---

- <the rule> — Why: <evidence from this cycle>. Apply: <when/how it changes future behavior>.
```

### Write rules

- Check the target surface for an equivalent rule first; update the existing entry instead of appending a duplicate.
- Append or update in place — never rewrite or reorder surrounding content, and never touch user-written sections.
- Match the target surface's existing structure and language (a `CLAUDE.md` rules list, a native memory file's frontmatter conventions, an `AGENTS.md` section layout).
- One write per surface per cycle; batch multiple rules into a single edit.
- Stale-entry maintenance (updating or deleting a recalled entry that no longer holds) follows the same batch-edit rule and is reported like any other capture.

### Anti-patterns

- Capturing to prove the workflow ran — zero captures is the normal outcome.
- Long prose entries; if a rule needs more than ~2 lines, it is probably session context, not durable knowledge.
- Creating ad-hoc capture files (`LEARNINGS.md`, `NOTES.md`) outside the memory directory — the workflow-defined `docs/memory/` layout is the only sanctioned new-file target; anything unresolvable goes into the final report instead.
- Restating what a linter, type-checker, or the language itself already enforces.

## Native Task Tracking

Use whatever task tracker the current platform actually exposes.

For Claude Code:

- Create one workflow task with `TaskCreate` for non-trivial work.
- Mark it `in_progress` before implementation.
- Use `TaskUpdate` as phases complete.
- Keep `.tav/state.json` as the durable recovery state only when the lifecycle rules above call for it.

Do not write instructions that require unavailable tool names such as `TodoWrite` or `TodoUpdate`.

## Safety Notes

- Never delete or modify `.git` or `.svn` metadata.
- Ask before destructive, external, or hard-to-reverse actions.
- Do not roll back changes without explicit user approval unless the platform provides a safe non-destructive mechanism and the user authorized it.
- Report skipped checks honestly.

---

**End of Implementation Guide**
