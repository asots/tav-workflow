# TAV Workflow Implementation Guide

This guide covers operational details that go beyond the specification in `SKILL.md`. When this guide and `SKILL.md` disagree, `SKILL.md` wins. Command tables live in `references/verification-commands.md`; the phase-output schemas live only in `references/templates/`, while `SKILL.md` defines when they are required.

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
4. In a Spec-Driven project, copy the immutable workflow run ID, task-card/Issue ID, delivery-batch ID, and rollback boundary into `origin`. For standalone TAV work, leave every `origin` field null.

### Updates

- Update `current_phase`, `completed_steps`, and `last_update` at each phase transition.
- For hard bugs, keep `diagnosis.feedback_command`, the compact baseline result/reproduction rate, ranked hypothesis summaries, and current probe lifecycle (`planned|applied|removed|not_applicable`) recoverable. For test-first work, keep the chosen `tdd.test_seam` plus compact RED/GREEN command evidence. For review, persist separate `review_axes.standards` and `review_axes.spec` statuses and evidence pointers.
- Track repeated failures in `failure_counts.by_blocker` and `failure_counts.by_command`; the blocker key, consecutiveness, and re-plan reset rules are defined in `SKILL.md` § "Failure counting semantics" — two consecutive failures of the same key triggers `[ESCALATION-REPORT]`.
- Each map value uses the same compact entry shape: `{ "count": 2, "last_failed_at": "2026-07-28T08:00:00Z", "key_established": "iteration-1" }`. For example, `by_command["pnpm typecheck:TS2532"]` stores a gate-command failure, while `by_blocker["todo-2:missing-null-guard"]` stores a plan/structural failure. A successful comparable check removes or resets that key; a Thinker re-plan removes entries for superseded todos. Never prefix a `by_command` key with a todo ID.
- `phase_outputs` holds compact, recoverable state: the approved plan or next action, evidence pointers, and the verification plan/results needed to resume without chat history. Never duplicate the whole Thinker/Actor/Verifier report or full logs into state; they drift and waste space. Redact secrets, credentials, authorization data, private user data, and sensitive payloads before persisting any evidence pointer or result summary.

### Staleness and cleanup

- A state whose `last_update` is older than 7 days is stale: ask the user before resuming or replacing it.
- A state describing a different task: ask the user before replacing or archiving it.
- A non-null `origin.spec_run_id` must match the active non-tombstone MASTER and task card before resume. Treat any run/task/batch/rollback mismatch as different-task evidence.
- A MASTER containing `**Workflow State**: archived` is a tombstone, not an active plan. `Pending Operations: none` means run standalone/fresh; listed operations return to the Spec-Driven orchestrator with the archive pointer and next action.
- On completion, archive to `.tav/archive/` or delete the file only when it belongs to the completed workflow and the user has explicitly authorized cleanup. Otherwise leave `current_phase: complete` with `cleanup_status: awaiting_authorization`.

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

#### Hard-bug diagnostic mechanics

- Store the feedback-loop command and its first observed result in `evidence gathered`; carry the same command into the verification plan and `diagnosis.feedback_command` so the Verifier reruns the identical signal. The loop must target local, test, or explicitly authorized sandbox state; production mutations and external state changes are never diagnostic evidence.
- Treat a flaky reproduction rate as measured evidence. Record the loop count and observed failures before and after tightening rather than describing it as "sometimes".
- Minimize one dimension at a time and rerun after each reduction. The minimized case becomes the regression-test input when a correct seam exists.
- Hypotheses belong in the hard-bug evidence block, ranked with one falsifiable prediction each. A file-changing probe enters the diagnostic Actor micro-loop only after it maps to one prediction.
- The probe contract names exact files, one unique tag, the feedback command, and a cleanup check. The diagnostic Actor first records each probe path's VCS status/diff (including untracked or absent paths), applies the probe, captures the result, removes it, then proves the paths returned to that baseline and the tag is absent. It never retains a test or implements the fix.
- If cleanup fails, remain blocked in the probe micro-loop. Do not let temporary instrumentation leak into the normal Actor diff.
- For performance work, record the baseline metric and measurement command before proposing a fix.

### Actor

- Actor may read target files or snippets when required by the edit mechanism or to confirm exact context. Actor must not perform new requirement discovery.
- A diagnostic Actor is the same write-capable role under a narrower temporary contract. It may change only the named probe files, must remove all probe edits in the same micro-step, and always returns to Thinker rather than Verifier.
- Any structural mismatch between plan and code returns to Thinker with evidence.
- Output contract: `references/templates/actor-output.md`.

#### Test-driven slice mechanics

- Keep the red-green record compact: test/seam, red command result, minimal implementation, green command result.
- A vertical slice proves one externally visible capability through its public seam. Do not batch unrelated cases merely because they share a file.
- Mocks are acceptable at true external boundaries; do not mock the internal collaboration whose behavior the test is supposed to prove.
- If a test passes before implementation, stop: either the behavior already exists, the assertion is insensitive, or the wrong seam was selected. Return to Thinker when the task definition must change.
- If the planned seam cannot reproduce a hard bug's real caller pattern, do not force a shallow test. Return with the architecture evidence.

### Verifier

- Start from `git diff`, not from the Actor's summary.
- Pick verification commands only after inspecting project files; the evidence-to-command table is in `references/verification-commands.md`.
- Do not claim a check passed unless it ran and succeeded. Record unavailable commands under skipped checks.
- Flag consolidation candidates while reviewing — rework lessons and non-obvious root causes surface here, not in Phase 4. Evaluation and capture happen in Phase 4 against the signals in `SKILL.md`.
- Output contract: `references/templates/verifier-output.md`.

#### Two-axis review mechanics

- Run configured machine gates first so the review does not spend judgment on failures tooling already reports precisely.
- Standards evidence cites the repository rule or changed hunk. Generic smell findings are explicitly labeled heuristic and never override a documented project convention.
- Spec evidence cites the task definition or acceptance criterion and the changed hunk or missing behavior. Report missing/partial work, unauthorized scope, and semantically wrong implementations separately.
- Preserve the separation with explicit `Standards Review` and `Spec Review` sections in the Verifier output; do not hide either axis inside a generic verification row.
- For hard bugs, rerun both the minimized regression proof and the original feedback loop. Search for the instrumentation tag and verify that every diagnostic probe/harness was removed; any persistent regression proof must be a separately planned test in the normal Actor diff, never retained diagnostic residue.

## Knowledge Consolidation

The capture signals, never-capture list, and write-target resolution order are defined in `SKILL.md` Phase 4 and are not repeated here. This section covers the mechanics of writing a captured rule.

### Repo-local memory fallback layout

Use this layout only when `docs/memory/` is the project's declared or explicitly selected memory surface:

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
- Creating ad-hoc capture files (`LEARNINGS.md`, `NOTES.md`) outside the resolved memory surface. If no existing or explicitly selected surface accepts the rule, list the candidate in the final report instead.
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
