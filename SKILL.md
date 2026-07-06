---
name: tav-workflow
description: Use for scoped code changes, bug fixes, configuration updates, feature adjustments, and local refactors that need evidence-based analysis, minimal execution, and verification. Use spec-driven-develop first for rewrites, migrations, architecture overhauls, or broad multi-module transformations.
version: 3.4.0
---

# TAV Workflow - Think, Act, Verify

TAV is a disciplined workflow for changing software safely. It separates three responsibilities:

1. **Thinker** - gather evidence, diagnose, and plan.
2. **Actor** - make only the planned changes.
3. **Verifier** - independently check correctness, side effects, and quality gates.

Use this skill to prevent unplanned edits, hidden assumptions, and unverified completion claims.

---

## Trigger Conditions

### Use this skill for

- Bug fixes.
- Scoped feature implementation.
- Configuration updates.
- Local refactors with a known target.
- Dependency or workflow adjustments.
- User requests such as "fix", "change", "implement", "add", "update", or equivalent Chinese phrasing.

### Do not use this skill for

- Pure read-only explanations or repository searches.
- Full-project rewrites, migrations, framework rebuilds, schema overhauls, or broad transformations. Use `spec-driven-develop` first, then apply TAV to each scoped task.

---

## Task Tiering

Choose the smallest workflow that is still safe.

| Tier | Scope | Required workflow |
|------|-------|-------------------|
| L0 | Micro change, localized single-file patch, simple config value | Lightweight TAV in a single pass: cite evidence, edit, run a baseline check. No state file, no templated phase outputs. |
| L1 | Standard bug fix or feature touching multiple files | Full TAV: Thinker plan, Actor implementation, quality gates, Verifier review. |
| L2 | Architecture, migration, auth overhaul, database schema, distributed flow | Run `spec-driven-develop` first; then execute independent scoped tasks with TAV. |

### L2 Escalation Signals

Keep this list in sync with `spec-driven-develop` § "Escalation Signals" — both skills must apply the same test. Escalate to L2 only when **at least two** of these hold; otherwise stay at L0/L1:

- The change spans 3+ modules/subsystems, or breaks a public API/schema contract.
- The work will realistically span multiple sessions or exceed ~10 files.
- Architectural decisions are required (layering, dependency direction, technology selection).
- Acceptance criteria cannot be defined within a single Thinker-Actor-Verifier cycle.

A refactor confined to one module — however messy — stays at L1.

When unsure, choose the higher tier.

---

## Phase 0: Continuity Check

Skip this phase entirely for L0 tasks.

For L1 tasks, check for `.tav/state.json` in the target project root before any analysis or edits.

- If it exists, matches the current task, and `last_update` is within 7 days, load it and resume from `current_phase`.
- If `last_update` is older than 7 days, treat the state as stale and ask the user before resuming or replacing it.
- If it describes a different task, ask the user before replacing or archiving it.
- If it does not exist, start fresh.

Also check for `docs/progress/MASTER.md` in the target project. If it exists and the current task belongs to that plan, this TAV cycle is operating inside a `spec-driven-develop` project: follow "Operating Inside a Spec-Driven Project" below for task intake, write-back, and state ownership.

Create `.tav/state.json` only when the work is likely to span sessions or needs multiple Actor-Verifier iterations. For ordinary single-session L1 tasks, the platform's native task tracker is sufficient.

Key state fields: `current_phase` (`thinker|actor|verifier|complete|blocked`), `task_tier` (`L0|L1|L2`), `current_risk_level` (`low|medium|high|critical`), `todo_list`, `completed_steps`, `verification_commands`, `failure_counts`, `last_update`. Read `references/templates/state.json` before creating the file for the first time; keep field names exactly as the template defines them.

Use the platform's native task tracker when available. In Claude Code, map workflow progress to `TaskCreate` and `TaskUpdate`. Do not assume `TodoWrite` or `TodoUpdate` exists.

---

## Phase 1: Thinker - Analysis and Scoping

Thinker is read-only. Do not edit files in this phase.

In Claude Code, when native plan mode is active, run the Thinker phase inside it: the approved plan becomes the todo list. Do not duplicate the analysis afterwards.

### Required actions

1. Identify task tier and risk level.
2. Gather direct evidence from files, searches, diagnostics, or logs.
3. Diagnose the root cause or implementation target.
4. Produce atomic todo items with file-level or symbol-level specificity.
5. Select verification commands based on the project stack.
6. Ask at most one focused clarification question if requirements are ambiguous.

### Evidence rules

- Every conclusion must cite file paths, symbols, line ranges, logs, or command output.
- Prefer targeted reads and searches over broad file dumps.
- If the project has a memory index (`docs/memory/MEMORY.md`), read it and pull entries relevant to the task — previously captured knowledge is first-class evidence.
- If the project has CodeGraph available, use it before grep-style exploration.
- Do not invent file paths, commands, package managers, or test scripts.

### Required Thinker output

```markdown
**evidence gathered**:
- `path/to/file:line-range` - finding
- command/log evidence - finding

**analysis summary**:
- Root cause or implementation approach.

**todo list**:
1. `path/to/file` - exact planned change.
2. `path/to/file` - exact planned change.

**risks**:
- Regression, compatibility, security, or operational risks.

**verification plan**:
- Exact commands to run, or explicit reason if no command is available.
```

After Thinker completes, update native task tracking (and `.tav/state.json` if it exists).

---

## Phase 2: Actor - Atomic Implementation

Actor executes the approved todo list. Do not perform unrelated refactors.

### Required actions

1. Complete todo items in order unless dependencies require otherwise.
2. Use minimal edits that match surrounding style.
3. Prefer editing existing files over creating new ones.
4. Keep changes cohesive and small enough to avoid truncation.
5. Update `completed_steps` after each meaningful chunk.

### Actor boundaries

- Actor may read target files when the editing tool requires it or when confirming exact edit context.
- Actor must not perform new requirement exploration.
- If code structure contradicts the Thinker plan, stop and return to Thinker with the blocking evidence.
- Do not add comments, abstractions, dependencies, or formatting changes unless they are part of the plan.
- Do not silently improvise; deviations require a return to Thinker.

### Required Actor output

```markdown
**progress**:
1. Completed `path/to/file` - change made.
2. Completed `path/to/file` - change made.

**blocked items**:
- None, or exact blocker with evidence.

**next phase**:
- Enter Verifier, or return to Thinker because the plan is incomplete.
```

---

## Phase 3: Verifier - Closed-Loop Quality Gate

Verifier checks the change independently. Do not rely on Actor's summary.

### Required actions

1. Run `git diff` (or the VCS equivalent) first and review the actual changes, not the reported ones.
2. Check surrounding code and references affected by the change.
3. Run the verification commands selected by Thinker when possible.
4. Add stack-appropriate checks if Thinker missed obvious project commands.
5. Check security-sensitive surfaces when relevant.
6. Verify behavior, not just file presence.
7. Record pass/fail results in native task tracking (and `.tav/state.json` if it exists).
8. Flag knowledge consolidation candidates observed during review — rework lessons, non-obvious root causes, undocumented project commands — for evaluation in Phase 4.

### Stack-aware verification command selection

Use evidence from project files before choosing commands.

| Evidence | Typical commands |
|----------|------------------|
| `package.json` + `pnpm-lock.yaml` | `pnpm lint`, `pnpm typecheck`, `pnpm test` if scripts exist |
| `package.json` + `package-lock.json` | `npm run lint`, `npm run typecheck`, `npm test` if scripts exist |
| `package.json` + `yarn.lock` | `yarn lint`, `yarn typecheck`, `yarn test` if scripts exist |
| `pyproject.toml` | `ruff check .`, `mypy .`, `pytest` when configured |
| `Cargo.toml` | `cargo fmt --check`, `cargo clippy`, `cargo test` |
| `go.mod` | `go test ./...`, `go vet ./...` when applicable |
| Other stacks | Infer from CI config, README, Makefile, or project scripts; never invent commands |

If no reliable command exists, state that explicitly under failed or unexecuted commands. Never claim verification passed without running or justifying the gate.

### Security-sensitive branch

If the change touches authentication, authorization, user input, database queries, file system paths, external APIs, cryptography, payments, or secrets:

- Run an additional security review pass.
- Check for hardcoded secrets, injection, path traversal, unsafe error disclosure, missing validation, and authorization bypass.
- Block completion on critical issues.

### Required Verifier output

```markdown
**verification items**:
| Check | Status | Evidence |
|-------|--------|----------|
| Requirement met | pass/fail/warn | ... |
| Syntax/type safety | pass/fail/warn | ... |
| Tests/lint | pass/fail/warn | ... |
| Compatibility | pass/fail/warn | ... |
| Edge cases | pass/fail/warn | ... |
| Security | pass/fail/warn | ... |
| Side effects | pass/fail/warn | ... |

**result**:
- Pass and enter Complete, or return to Actor/Thinker with exact fixes.
```

---

## Phase 4: Completion

Only complete after verification gates pass or are explicitly documented as unavailable.

### Knowledge consolidation

Before writing the final report, evaluate whether this cycle produced durable engineering knowledge. Capture at most 1-3 concise rules per cycle; most tasks produce none — zero captures is the default outcome, not a failure.

Capture only when at least one signal holds:

- The root cause was non-obvious (the surface symptom pointed elsewhere) and the pattern will recur.
- A project-specific command, script, or environment requirement was discovered that is recorded nowhere in the repo.
- A dependency, version, or platform gotcha cost a rework iteration.
- The same gate failed twice before the real fix was found — the lesson behind a `[PUA-REPORT]`.
- The user corrected the approach mid-task, expressing a durable preference or constraint.

Never capture:

- Anything the repo already records (code structure, existing `CLAUDE.md`/`AGENTS.md` rules, git history, README).
- Facts derivable by reading the code.
- Session-only context (this cycle's todo list, temporary decisions).

Write target — route by the nature of the knowledge, not by surface availability:

1. **Project memory directory** (`docs/memory/`) — the default for project engineering knowledge: root-cause patterns, commands, gotchas, invariants. One entry per file plus a `MEMORY.md` index line; committed with the repo so the knowledge is versioned, reviewable, and shared. Creating this directory on first capture is part of this workflow, not a new-truth-source violation.
2. **An existing instruction surface** (`CLAUDE.md`, `AGENTS.md`, or an existing platform rule file) — high-bar exception, only for a rule that must be unconditionally present in every session (a hard behavioral constraint). Add at most one line; link to the memory entry for detail.
3. **The platform's native project memory** — personal or machine-specific facts that do not belong in the repo (local paths, personal workflow).
4. **In a spec-driven project** — follow the surfaces already recorded under "Governance Status" in `docs/progress/MASTER.md`; once the project memory directory is registered there, it is the preferred memory surface.

If the knowledge fits none of these, list the candidate in the final report. Do not create ad-hoc files outside the memory directory. Directory layout and operational mechanics (entry format, dedupe, append discipline) are in `references/implementation-guide.md` § "Knowledge Consolidation".

### Final report

Use this final format when files were modified:

```markdown
## 变更摘要
- What changed and why.

## 涉及文件
- `path/to/file` (Modified): summary.

## 验证结果
- ✅ `command` passed, or exact observed result.

## 失败或未执行的命令
- `command` - reason.

## 剩余风险
- Known limitations or edge cases.

## 后续建议
- Practical next steps.
```

When knowledge consolidation wrote to a memory or instruction surface, append this section to the report. Omit it entirely when nothing was captured, keeping the report identical to the global standard format:

```markdown
## 知识沉淀
- `surface or file` - rule captured, one line per rule.
```

Report only measurable facts. File and line counts come from `git diff --stat`; never estimate token usage or wall-clock duration.

In a spec-driven project (see "Operating Inside a Spec-Driven Project"), completion additionally requires the write-back: progress update (Issue/checkbox + MASTER.md) plus post-task telemetry. The task is not complete until both are recorded. Knowledge consolidation, when it fires, routes through the governance surfaces resolved in MASTER.md.

Archive or remove `.tav/state.json` only after completion and only if it belongs to the completed workflow. Do not delete VCS metadata under any circumstance.

---

## Error Recovery and Escalation

| Failure | Detection | Action |
|---------|-----------|--------|
| Ambiguous requirement | Thinker | Ask one focused question, then update plan |
| Incomplete plan | Actor | Stop and return to Thinker with evidence |
| Quality gate failure | Verifier | Return to Actor with exact command output |
| Same blocker fails twice | Any phase | Emit `[PUA-REPORT]` and escalate |
| Critical security issue | Verifier | Block completion and request explicit user decision |
| Token/context pressure | Any phase | Save state, summarize progress, pause |

### PUA escalation format

```text
[PUA-REPORT]
- 触发节点：[Agent Name / Current Phase Name]
- 失败次数：[Exact consecutive failure count]
- 核心瓶颈：[Precise technical blocker]
- 异常上下文：[Terminal traces, exception stack, or error block]
- 惩罚性反思：[Logic correction and next safe action]
```

---

## Operating Inside a Spec-Driven Project

When `docs/progress/MASTER.md` exists and the current task comes from a `spec-driven-develop` plan, one TAV cycle executes exactly one task card. This is the execution half of the Handoff Contract defined in `spec-driven-develop` § "Boundary with TAV" — keep both sides in sync.

**Task intake (Thinker):**

- Take the task definition from the pending GitHub Issue or phase-file entry, not from a re-interpretation of the original user request.
- Treat the task card's acceptance criteria as the baseline of the verification plan; add stack-appropriate gates on top.
- Treat the task card's S.U.P.E.R design drivers as additional Verifier check items.
- Treat the task card's memory/governance impact field as pre-declared candidates for Phase 4 knowledge consolidation.

**Completion write-back (after Verifier passes):**

- Close the Issue via PR (`closes #N`) or check the checkbox in the phase file, and update the "Current Status" section of MASTER.md.
- Report post-task telemetry from observed TAV signals: effort level derived from rework iterations and Thinker returns, plus the count of files touched beyond the task card's "Affected Files" list. The scale and storage protocol live in `spec-driven-develop` `references/adaptive-control.md` § 1.
- Route knowledge consolidation through the surfaces recorded under "Governance Status" in MASTER.md — durable facts to the resolved memory surface, agent-behavior rules to the resolved instruction surfaces. This fulfills the governance write-back that `spec-driven-develop` Phase 5b step 4 already requires and is mirrored in its Handoff Contract write-back table.
- On `[PUA-REPORT]` or a blocked state, record it on the Issue or phase file before pausing — the spec-driven drift controller needs that signal.

**State ownership:**

- `docs/progress/MASTER.md` (plus GitHub Issues) is the project-level authority; never duplicate project progress into `.tav/state.json`.
- `.tav/state.json` stays scoped to the single task in flight and is archived or deleted when that task completes.

---

## Tool and Agent Mapping

Role names are responsibilities, not hard dependencies on exact agent names.

| TAV role | Preferred implementation | Fallback |
|----------|--------------------------|----------|
| Thinker | Native plan mode, planning/exploration agent, read-only tools | Main agent read-only analysis |
| Actor | Coding/execution agent or main agent edits | Main agent with strict todo list |
| Verifier | Reviewer agent, test tools, security reviewer when needed | Main agent independent verification |
| Progress tracking | `TaskCreate` / `TaskUpdate` / native todo tool | `.tav/state.json` only |

For independent read-only analysis, use parallel agents when helpful. For edits, avoid uncontrolled parallel modification unless isolated worktrees are explicitly requested or provided.

---

## References

Read these on demand, not upfront:

- `references/templates/state.json` - read before creating `.tav/state.json` for the first time.
- `references/templates/thinker-output.md`, `actor-output.md`, `verifier-output.md` - read before producing a phase output when the inline format above is not detailed enough.
- `references/implementation-guide.md` - operational details: state lifecycle, native task tracking, metrics rules, knowledge consolidation mechanics, safety notes.
- `examples/bug-fix.md` - two-iteration loop where Verifier catches an incomplete fix.
- `examples/rate-limiting.md` - full L1 walkthrough including state file evolution.
- `examples/refactoring.md` - behavior-preserving extraction with plan-mismatch recovery.
- `CHANGELOG.md` - version history.

---

**End of TAV Workflow Skill**
