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
- Track repeated failures in `failure_counts.by_blocker` and `failure_counts.by_command`; two consecutive failures of the same entry triggers `[PUA-REPORT]` (format in `SKILL.md`).

### Staleness and cleanup

- A state whose `last_update` is older than 7 days is stale: ask the user before resuming or replacing it.
- A state describing a different task: ask the user before replacing or archiving it.
- On completion, archive to `.tav/archive/` or delete the file - only if it belongs to the completed workflow.

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
- Output contract: `references/templates/verifier-output.md`.

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
