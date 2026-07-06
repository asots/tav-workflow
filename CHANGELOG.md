# TAV Workflow Changelog

## Version 3.4.0 (2026-07-06)

### Knowledge Consolidation

- **Added**: Phase 4 "Knowledge consolidation" step — after gates pass, evaluate five capture signals (non-obvious root cause, undocumented project command, dependency/platform gotcha costing a rework, twice-failed gate lesson, durable user correction) and write at most 1-3 concise rules to an existing memory or instruction surface. An explicit never-capture list (repo-recorded content, code-derivable facts, session-only context) keeps surfaces clean; zero captures is the stated default outcome.
- **Added**: Write-target routing by knowledge nature — project memory directory (`docs/memory/`, the committed default for engineering knowledge) → existing instruction surface (high-bar exception for rules that must be present in every session, one line max) → platform native memory (personal/machine-specific facts) → spec-driven governance surfaces. No ad-hoc capture files; unresolvable candidates are listed in the final report instead.
- **Added**: Recall loop — Thinker evidence rules read `docs/memory/MEMORY.md` when present and pull task-relevant entries, closing the capture → index → recall cycle.
- **Added**: Verifier required action 8 — flag consolidation candidates during review (rework lessons surface there, not in Phase 4); optional "Consolidation Candidates" section in the Verifier output template.
- **Added**: Conditional "## 知识沉淀" report section — appended only when a surface was actually written, so reports without captures stay identical to the global standard format (no changes required in the three examples).
- **Added**: Spec-driven interop — consolidation routes through the surfaces recorded under "Governance Status" in MASTER.md, fulfilling the governance write-back that `spec-driven-develop` Phase 5b step 4 already requires; the task card's "memory/governance impact" field feeds Phase 4 as pre-declared candidates. Mirrored in `spec-driven-develop` 1.14.1's Handoff Contract (input + write-back governance rows).
- **Added**: Implementation guide § "Knowledge Consolidation" — entry format (rule / why / apply), write rules (dedupe before append, preserve user content, one batched write per surface), and anti-patterns.

## Version 3.3.0 (2026-07-06)

### Spec-Driven Interop

- **Added**: "L2 Escalation Signals" — a quantified two-of-four test (3+ modules, multi-session or ~10+ files, architectural decisions, acceptance criteria beyond one cycle) shared verbatim with `spec-driven-develop` § "Escalation Signals", so both skills route borderline refactors the same way.
- **Added**: "Operating Inside a Spec-Driven Project" section — task intake from Issue/phase-file task cards, completion write-back (progress plus post-task telemetry derived from TAV execution signals), and explicit state ownership: `docs/progress/MASTER.md` owns project-level progress while `.tav/state.json` stays scoped to a single task.
- **Added**: Phase 0 now also detects `docs/progress/MASTER.md` and switches to spec-driven interop behavior when the current task belongs to that plan.
- **Added**: Completion phase requires the spec-driven write-back (progress + telemetry) before a task counts as done.

### Counterpart Changes (spec-driven-develop 1.14.0)

- Trigger description narrowed: bare "重构/refactor" no longer pulls single-module or local refactors away from TAV.
- "When Not to Use" + "Escalation Signals" and a per-task "Boundary with TAV" Handoff Contract (input mapping, write-back mapping, state ownership) added to the core SKILL.
- Adaptive-control effort scale converted from wall-clock time to TAV-observable execution signals (rework iterations, plan returns, unplanned files), consistent with this skill's metrics rules.
- The `task-executor` agent prompt now runs each task as one TAV cycle and reports an "Execution Signals" section (rework iterations, plan returns, unplanned files) that feeds the adaptive-control telemetry.

## Version 3.2.0 (2026-07-06)

### Consistency Fixes

- **Fixed**: All three examples rewritten to match the v3.1+ contracts they claimed to follow:
  - `state.json` snippets now use snake_case fields and lowercase phase enums (previously camelCase `taskId`/`userRequest`/`phases` with capitalized phases).
  - Thinker outputs now include `Task Classification` and `Verification Plan` sections.
  - Verifier tables now use `pass/fail/warn` instead of check-mark symbols.
- **Fixed**: Verifier checklist unified to one 7-item table (Requirement met, Syntax/type safety, Tests/lint, Compatibility, Edge cases, Security, Side effects) across `SKILL.md` and the output template.
- **Fixed**: Stack command table unified (added `yarn.lock` row, normalized `go vet ./...`, added an "other stacks: infer from CI/README/Makefile" fallback row); the table now lives only in `SKILL.md`.

### Workflow Improvements

- **Added**: L0 tasks explicitly skip Phase 0, the state file, and templated phase outputs (single-pass lightweight TAV).
- **Added**: State staleness rule - `last_update` older than 7 days requires user confirmation before resuming.
- **Added**: `.tav/state.json` creation is now conditional (cross-session or multi-iteration work only); native task tracking is the default.
- **Added**: Verifier's first required action is reviewing the real `git diff`, not the Actor's summary.
- **Added**: Thinker phase maps to Claude Code native plan mode when active.

### Anti-Hallucination

- **Removed**: `total_token_usage` from the state schema and all token/duration figures from examples and reports. Metrics are restricted to values measurable via `git diff --stat` and iteration counts.

### Documentation Structure

- **Changed**: `SKILL.md` is the single source of truth; `README.md` and `references/implementation-guide.md` no longer duplicate schemas, command tables, or report formats.
- **Changed**: References section now uses on-demand progressive disclosure (when to read each file).
- **Removed**: Version history section from `SKILL.md` body (this changelog is authoritative).
- **Removed**: Platform-API-shaped agent invocation pseudo-code from examples.

## Version 3.1.0 (2026-07-03)

### Alignment Improvements

- **Changed**: Durable state schema now uses TAV-global snake_case fields:
  - `current_phase`
  - `todo_list`
  - `completed_steps`
  - `current_risk_level`
  - `verification_commands`
  - `failure_counts`
- **Changed**: Replaced fixed `TodoWrite` / `TodoUpdate` assumptions with platform-native task tracking guidance.
- **Changed**: Updated version references in `SKILL.md`, `README.md`, templates, and implementation guide.

### Workflow Improvements

- **Added**: L0/L1/L2 task tiering.
- **Added**: Clear `spec-driven-develop` escalation for migrations, rewrites, architecture overhauls, and broad transformations.
- **Added**: Actor read-boundary clarification: Actor may read target context required for editing but must not perform new exploration.
- **Added**: Stack-aware verification command selection for Node, Python, Rust, and Go projects.
- **Added**: Security-sensitive verification branch for auth, user input, database, filesystem, external API, crypto, payments, and secrets.
- **Added**: Two-failure `[PUA-REPORT]` escalation protocol.

### Documentation Improvements

- **Simplified**: Reduced pseudo-code that looked like directly executable platform API calls.
- **Clarified**: Role names are responsibilities, not hard dependencies on exact agent names.
- **Clarified**: Final report must include modified files, verification results, failed or skipped commands, residual risks, and next steps.
- **Clarified**: Cleanup and rollback must avoid destructive VCS operations and require explicit user approval for hard-to-reverse actions.

## Version 3.0.0 (2026-05-19)

### Major Features

#### 1. Automated Agent Orchestration

- **Added**: Agent-based execution for all three phases:
  - Thinker: planning/exploration role for analysis.
  - Actor: coding/execution role for changes.
  - Verifier: review/verification role for independent validation.
- **Benefit**: Workflow can be executed consistently instead of relying on informal manual interpretation.

#### 2. State Persistence

- **Added**: `.tav/state.json` for cross-conversation continuity.
- **Added**: State archiving to `.tav/archive/` on completion.
- **Added**: Continuity check at workflow start.
- **Benefit**: Interrupted workflows can resume without losing progress.

#### 3. Native Tool Integration

- **Added**: Native progress tracking guidance.
- **Added**: Optional platform-specific workflow progress integration.
- **Benefit**: Real-time progress visibility in supported environments.

#### 4. Quality Gates

- **Added**: Automated lint, type-check, and test execution after Actor phase.
- **Added**: Quality gate failure handling.
- **Benefit**: Errors are caught before final verification.

#### 5. Error Recovery Protocol

- **Added**: Structured error recovery with retry limits.
- **Added**: Recovery decision tree for different error types.
- **Added**: Automatic escalation when retry limits are exceeded.
- **Benefit**: Robust error handling without infinite loops.

#### 6. Performance Optimization

- **Added**: Token budget tracking per phase.
- **Added**: Efficiency rules for each role.
- **Added**: Performance metrics in state file.
- **Benefit**: Predictable token usage and faster execution.

#### 7. Complete Examples

- **Added**: `examples/rate-limiting.md` - API rate limiting implementation.
- **Added**: `examples/bug-fix.md` - Bug fix with iteration.
- **Added**: `examples/refactoring.md` - Local refactoring example.

#### 8. Skill Composition Patterns

- **Added**: Integration patterns with other skills:
  - Deep-Discuss -> TAV.
  - TAV -> Review.
  - Spec-Dev -> TAV.
  - TAV -> Smart-Commit.

### Documentation

#### New Files

- `references/implementation-guide.md` - Complete implementation guide.
- `references/templates/state.json` - State file template.
- `references/templates/thinker-output.md` - Thinker output template.
- `references/templates/actor-output.md` - Actor output template.
- `references/templates/verifier-output.md` - Verifier output template.
- `examples/rate-limiting.md` - Complete rate limiting example.
- `examples/bug-fix.md` - Bug fix with iteration example.
- `examples/refactoring.md` - Refactoring example.

#### Updated Files

- `SKILL.md` - Complete rewrite with automated workflow features.

### Notes

- v3.0.0 introduced the production version of the automated TAV workflow.
- v3.1.0 refines the workflow to better match current Claude Code tools and global TAV execution rules.

---

**License**: MIT
