---
name: tav-workflow
description: Use for scoped code changes, bug fixes, configuration updates, feature adjustments, and local refactors that need evidence-based analysis, minimal execution, and verification. Use spec-driven-develop first for rewrites, migrations, architecture overhauls, or broad multi-module transformations.
version: 3.9.0
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

### L0 vs L1 boundary

Tier is about risk and blast radius, not just file count. Choose L1 when **any** of these hold; otherwise L0:

- The change touches a security-sensitive surface (auth, user input, DB queries, file paths, payments, secrets, external APIs).
- The change can affect runtime behavior beyond the edited file (shared state, public API, config consumed by other services).
- The fix needs a new or strengthened test to prove correctness.
- The diff will likely exceed ~30 lines or touch 2+ files.

A one-line typo or config-value change with an obvious, local effect stays L0 even if it edits a "scary" file. When unsure, choose the higher tier.

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

For L1 tasks, check for `.tav/state.json` in the target project root before any analysis or edits. If multiple L1 tasks are running concurrently in the same project, use a task-scoped state file named `.tav/state-<task_id>.json` instead, and resume only from the file whose `task_id` matches the current request.

- If it exists, matches the current task, and `last_update` is within 7 days, load it and resume from `current_phase`.
- If `last_update` is older than 7 days, treat the state as stale and ask the user before resuming or replacing it.
- If it describes a different task, ask the user before replacing or archiving it.
- If it does not exist, start fresh.

Also check for `docs/progress/MASTER.md` in the target project. If it exists and the current task belongs to that plan, this TAV cycle is operating inside a `spec-driven-develop` project: follow "Operating Inside a Spec-Driven Project" below for task intake, write-back, and state ownership.

Create `.tav/state.json` only when the work is likely to span sessions or needs multiple Actor-Verifier iterations. For ordinary single-session L1 tasks, the platform's native task tracker is sufficient.

Never let two TAV cycles write the same state file. `current_phase`, `todo_list`, and `failure_counts` belong to one task only and must not leak across parallel work.

Key state fields: `current_phase` (`thinker|actor|verifier|complete|blocked`), `task_tier` (`L0|L1|L2`), `current_risk_level` (`low|medium|high|critical`), `todo_list`, `completed_steps`, `verification_commands`, `diagnosis`, `tdd`, `review_axes`, `failure_counts`, `last_update`. Read `references/templates/state.json` before creating the file for the first time; keep field names exactly as the template defines them. Store compact commands, results, and evidence pointers — never full logs or duplicated phase reports.

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
6. Ask at most one focused clarification question if requirements are ambiguous. When the ambiguity is structural — competing interpretations that would change the todo list — run a grilling interview instead: one question at a time, each led by a recommended answer, until the plan-changing decisions are resolved. Use the `grilling` skill when the platform provides it; do not act on the plan until shared understanding is confirmed.

### Evidence rules

- Every conclusion must cite file paths, symbols, line ranges, logs, or command output.
- Prefer targeted reads and searches over broad file dumps.
- If the project has a memory index (`docs/memory/MEMORY.md`), read **only the index lines** (one hook per entry) and shortlist entries whose hook mentions the task's files, modules, or topic. Open only the shortlisted entry files, then use their `applies_to`/`tags` frontmatter to confirm relevance and discard mismatches — previously captured knowledge is first-class evidence, but loading every entry wastes context. If a recalled entry contradicts the current code or reality, flag it as a stale-entry candidate for Phase 4 (update or delete).
- If the project has a domain glossary (`CONTEXT.md`, or a `CONTEXT-MAP.md` pointing at per-context glossaries), read the entries relevant to the task and use the canonical terms in the diagnosis, todo items, and any new names. When the user's phrasing, the glossary, and the code disagree, surface the contradiction instead of silently picking one side; term resolution and decision recording route through the `domain-modeling` skill when available (write targets in Phase 4).
- If the project has CodeGraph available, use it before grep-style exploration.
- Do not invent file paths, commands, package managers, or test scripts.
- Stop exploring once the todo list can be written at file-level precision — evidence gathering serves the plan, not completeness.

### Hard-bug diagnosis branch

Use this branch when the failure resists an obvious first-pass explanation, is intermittent, is a performance regression, or the user explicitly asks for diagnosis/debugging. Ordinary scoped fixes keep the standard Thinker flow.

1. **Establish the feedback loop before theorizing.** Identify and run one existing command, script, trace replay, or debugger/REPL path that exercises the user's exact symptom. It must be red-capable, deterministic (or have a measured high reproduction rate for a flaky bug), as fast as practical, and agent-runnable. If a new harness or source instrumentation is required, design it here and use the diagnostic Actor micro-loop below instead of editing during Thinker.
2. **Reproduce and minimize.** Confirm the loop catches the reported failure, then remove inputs, callers, configuration, data, and steps one at a time until every remaining element is load-bearing.
3. **Rank falsifiable hypotheses.** Write 3-5 candidate causes before testing them. Each hypothesis states a prediction that one targeted probe can confirm or falsify. Share the ranking as a non-blocking checkpoint when user domain knowledge could materially reorder it.
4. **Probe one variable at a time.** Prefer read-only debugger/REPL inspection. When a file edit is required, specify one falsifying prediction, the exact probe files, a unique removable tag, and a cleanup check for the diagnostic Actor. Performance work starts from a measured baseline, profiler/query plan, or bisection signal rather than broad logging.
5. **Plan the regression proof at the correct seam.** The test must exercise the real bug pattern through a stable public boundary. If no correct seam exists, record that architecture limitation instead of adding a shallow test that cannot catch the original failure.
6. **Close the loop.** After diagnosis returns to normal TAV, the Actor applies the minimal fix; the Verifier reruns both the minimized regression proof and the original feedback command, and confirms all temporary instrumentation or harnesses are removed.

#### Diagnostic Actor micro-loop

This micro-loop preserves the Thinker read-only boundary when diagnosis needs temporary file changes:

1. Thinker records the probe's prediction, exact files, command, unique tag, and cleanup check. The probe must be disposable and narrower than the eventual fix.
2. A diagnostic Actor captures the pre-probe VCS status/diff for the named paths (including whether a path was untracked or absent), applies only that probe, runs the named feedback command, captures the observed result, removes every probe edit, and proves those paths match the pre-probe baseline with the unique tag absent.
3. Control returns to Thinker, which updates the hypothesis ranking from the observed signal. Repeat only for a materially different prediction.

The diagnostic Actor does not implement the fix or retain a regression test. Persistent tests and product changes belong to the normal Actor after the Thinker plan is complete. If baseline restoration cannot be proven, stop and report the residual diagnostic delta without touching pre-existing user changes.

If no usable feedback loop can be built, stop speculative diagnosis. Report the attempts and exact limitation, then request the missing environment access, captured artifact, or permission for temporary instrumentation.

### Design-prototype branch

Use this branch when a plan decision hinges on how a state model, interaction, or interface should behave and repository evidence cannot settle it — the question is "does this design feel right?", not "why does this fail?". Build a throwaway prototype that answers that single question: an interactive terminal harness for state/logic questions, or switchable UI variations for interface questions. Use the `prototype` skill when the platform provides it.

The prototype follows the diagnostic-probe discipline: explicitly marked as throwaway, no tests or polish, never part of the final diff, and removed once the question is answered (retain it only on explicit user request, outside the delivered change). Record the question, the run command, and the validated decision in the Thinker output; only the decision enters the todo list, and the Verifier confirms no prototype code remains in the delivered change.

### Required Thinker output

```markdown
**evidence gathered**:
- `path/to/file:line-range` - finding
- command/log evidence - finding

**analysis summary**:
- Root cause or implementation approach.

**hard-bug evidence** (when applicable):
- Feedback command + first observed result/reproduction rate.
- Ranked hypotheses with one falsifiable prediction each.
- Diagnostic probe plan/status: files, unique tag, pre-probe baseline, cleanup check, observed signal.
- Test seam for the planned regression proof, or explicit architecture limitation.

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
6. For long task cards (5+ todo items or an expected diff beyond ~300 lines), checkpoint proactively: after every 3-4 completed todos, persist progress (`.tav/state.json` when in use, otherwise the native task tracker) and run the cheapest relevant gate (syntax or type check) on the touched files before continuing. Recovery from a mid-task interruption must never depend on conversation memory.

### Actor boundaries

- Actor may read target files when the editing tool requires it or when confirming exact edit context.
- Actor must not perform new requirement exploration.
- If code structure contradicts the Thinker plan, stop and return to Thinker with the blocking evidence.
- Do not add comments, abstractions, dependencies, or formatting changes unless they are part of the plan.
- Do not silently improvise; deviations require a return to Thinker.

### TDD execution branch

Use test-driven execution when the Thinker plan requires new or strengthened automated tests, when the hard-bug branch produced a regression proof, or when the user explicitly requests test-first work.

- The Thinker names the **test seam**: the highest stable public boundary that can prove the required behavior. Prefer an existing seam. Ask the user only when competing seams materially change scope, architecture, or cost; otherwise choose from repository evidence and record the decision.
- Work in one vertical behavior slice at a time: write one test for externally observable behavior, run it red, add only enough implementation to make it green, then repeat.
- Expected values must come from an independent source of truth such as the confirmed requirement, a worked example, or known-good literal — never recompute the implementation inside the assertion.
- Avoid implementation-coupled mocks/private-method tests and horizontal "all tests first, all implementation later" batches.
- Refactor only after the slice is green and only when the refactor is already within the approved todo list; an unplanned structural need returns to Thinker.
- Record the red and green command evidence in progress so the Verifier can rerun it independently.

### Required Actor output

```markdown
**progress**:
1. Completed `path/to/file` - change made.
2. Completed `path/to/file` - change made.

**diagnostic probe evidence** (when this output is for a probe micro-step):
- Prediction, command/result, unique tag, cleanup command, and proof that probe paths returned to their pre-probe baseline.

**TDD evidence** (when applicable):
- Slice: RED command/result → GREEN command/result.

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
3. Treat Thinker's `verification plan` as candidate commands; confirm each still matches the project stack (re-read the evidence if unsure), run them, and add any stack-appropriate checks Thinker missed. Do not silently re-derive the whole list from scratch.
4. Add stack-appropriate checks if Thinker missed obvious project commands.
5. Check security-sensitive surfaces when relevant.
6. Perform the two-axis review below after machine checks; keep Standards and Spec findings separate.
7. Verify behavior, not just file presence.
8. Record pass/fail results in native task tracking (and `.tav/state.json` if it exists).
9. Flag knowledge consolidation candidates observed during review — rework lessons, non-obvious root causes, undocumented project commands — for evaluation in Phase 4.

### Verification command selection

Use project evidence before choosing commands. Read `references/verification-commands.md` when selecting application-stack or configuration/IaC gates; it contains the evidence-to-command table and external-state safety limits.

If no reliable command exists, state that explicitly under failed or unexecuted commands. Never claim verification passed without running or justifying the gate.

### Two-axis review

Machine gates prove that configured checks ran; they do not prove that the right change was made. Review the actual diff through two independent axes:

1. **Standards** — compare the diff with repository instruction and coding-standard sources. Project rules override generic heuristics. Where tooling does not already enforce the issue, look for judgment-call smells such as unclear naming, duplicated logic, misplaced responsibility, data clumps, repeated conditionals, shotgun/divergent change, speculative generality, long navigation chains, delegation-only middle layers, or inheritance that does not fit. Label heuristics as possible smells, not hard violations.
2. **Spec** — compare the diff with the task definition and acceptance criteria. Identify requested behavior that is missing or partial, behavior added without authorization, and implementation that appears present but does not satisfy the requirement.

Do not merge the axes into one score: a change can satisfy standards while implementing the wrong thing, or satisfy the spec while violating project rules. When independent reviewer agents are available and their cold-start cost is justified, the axes may run in parallel; otherwise the Verifier performs two explicit passes. This review supplements, never replaces, tests, type/lint checks, compatibility review, security review, and configuration/IaC validation.

### Security-sensitive branch

If the change touches authentication, authorization, user input, database queries, file system paths, external APIs, cryptography, payments, or secrets:

- Run an additional security review pass.
- Check for hardcoded secrets, injection, path traversal, unsafe error disclosure, missing validation, and authorization bypass.
- Block completion on critical issues.

### Verifier independence escalation

When the change touches a security-sensitive surface, or the same task has accumulated two or more rework iterations, run the Verifier as an independent reviewer agent when the platform provides one. A first rework iteration should trigger an explicit side-effect review and consider independent verification; the second consecutive failure requires it. The second failure escalates verification independence, not just the report — the agent that wrote a fix twice is the least likely to see what is still wrong with it.

### Required Verifier output

```markdown
**verification items**:
| Check | Status | Evidence |
|-------|--------|----------|
| Syntax/type safety | pass/fail/warn | ... |
| Tests/lint | pass/fail/warn | ... |
| Compatibility | pass/fail/warn | ... |
| Edge cases | pass/fail/warn | ... |
| Security | pass/fail/warn | ... |
| Side effects | pass/fail/warn | ... |

**Standards review**:
- pass/fail/warn — repository-rule or heuristic evidence.

**Spec review**:
- pass/fail/warn — acceptance evidence for missing/partial behavior, scope creep, or semantic mismatch.

**hard-bug closure** (when applicable):
- Minimized regression proof, original feedback command, tag search, and probe-path baseline-restoration evidence.

**result**:
- Pass and enter Complete, or return to Actor/Thinker with exact fixes.
```

---

## Phase 4: Completion

Only complete after verification gates pass or are explicitly documented as unavailable.

### Knowledge consolidation

Before writing the final report, evaluate whether this cycle produced durable engineering knowledge. Capture at most 1-3 concise rules per cycle; most tasks produce none — zero captures is the default outcome, not a failure. L0 tasks skip templated phase outputs but not the capture signals — a single-file patch can still hit a dependency gotcha or a user correction.

Capture only when at least one signal holds:

- The root cause was non-obvious (the surface symptom pointed elsewhere) and the pattern will recur.
- A project-specific command, script, or environment requirement was discovered that is recorded nowhere in the repo.
- A dependency, version, or platform gotcha cost a rework iteration.
- The same gate failed twice before the real fix was found — the lesson behind an `[ESCALATION-REPORT]`.
- The user corrected the approach mid-task, expressing a durable preference or constraint.
- A recalled memory entry proved stale or wrong during this cycle — updating or deleting it is a capture action and follows the same reporting rule.

Never capture:

- Anything the repo already records (code structure, existing `CLAUDE.md`/`AGENTS.md` rules, git history, README).
- Facts derivable by reading the code.
- Session-only context (this cycle's todo list, temporary decisions).

Write target — resolve the memory surface before choosing a file:

1. **Existing governance or declared project memory surface** — in a spec-driven project, `docs/progress/MASTER.md` "Governance Status" wins; otherwise use the project's already declared memory surface. Do not create a competing source.
2. **The platform's native project memory** — the default when no existing project declaration takes precedence and native memory is available.
3. **A repo-local fallback** (`docs/memory/`) — only when the project already declares it or the user explicitly selects it. When selected, use one entry per file plus a `MEMORY.md` index line; commit it with the repository.
4. **Domain surfaces** (`CONTEXT.md` glossary; the project's ADR directory) — confirmed canonical terms go to the glossary, and decisions that are costly to reverse, surprising without context, and the result of a genuine trade-off go to an ADR. Route these through the `domain-modeling` skill when available; do not duplicate them into general memory.
5. **An existing instruction surface** (`CLAUDE.md`, `AGENTS.md`, or an existing platform rule file) — high-bar exception, only for a rule that must be unconditionally present in every session. Add at most one line; link to the resolved memory surface for detail.

If the knowledge fits none of these, list the candidate in the final report. Do not create ad-hoc files outside the resolved memory surface. Directory layout and operational mechanics (entry format, dedupe, append discipline) are in `references/implementation-guide.md` § "Knowledge Consolidation".

### Final report

Use this final format when files were modified. Render all headings in the user's working language; the Chinese headings below are the reference layout.

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

In a spec-driven project (see "Operating Inside a Spec-Driven Project"), completion additionally requires a handoff. In orchestrator-direct execution, the orchestrator records authorized project-level progress and execution events; in a lane or delegated assignment, return the write-back payload and do not mark the project task complete yourself. Knowledge consolidation, when it fires, is returned as a candidate and routes through the governance surfaces resolved in MASTER.md.

Archive or remove `.tav/state.json` only after completion and only if it belongs to the completed workflow. Do not delete VCS metadata under any circumstance.

---

## Error Recovery and Escalation

| Failure | Detection | Action |
|---------|-----------|--------|
| Ambiguous requirement | Thinker | Ask one focused question, then update plan |
| Incomplete plan | Actor | Stop and return to Thinker with evidence |
| Quality gate failure | Verifier | Return to Actor with exact command output |
| Same blocker fails twice | Any phase | Emit `[ESCALATION-REPORT]` and escalate |
| Critical security issue | Verifier | Block completion and request explicit user decision |
| Token/context pressure | Any phase | Save state, summarize progress, pause |

### Risk level dynamics

Risk level is set in Thinker and may change as evidence accumulates. Escalate (never silently downgrade) when the Verifier surfaces new information:

| Level | Typical trigger | Required action |
|-------|-----------------|-----------------|
| low | Localized, obvious change, no security/data surface | Standard TAV |
| medium | Multi-file or behavior-affecting change, no sensitive surface | Standard TAV; Verifier checks side effects |
| high | Touches a security-sensitive surface, or first rework iteration | Explicit side-effect review; run Verifier as an independent reviewer agent when security-sensitive or already at the second consecutive failure |
| critical | Confirmed security issue, data-loss risk, or two+ rework iterations on a sensitive surface | Block completion; request explicit user decision before proceeding |

When risk escalates to high or critical mid-cycle, re-run the security-sensitive branch and consider promoting the Verifier to an independent reviewer agent. Downgrading requires fresh Thinker evidence that the original trigger no longer applies — record the reason in the Verifier output.

### Failure counting semantics

The "same blocker fails twice" rule needs a stable key so the count is meaningful:

- **Blocker key** = `todo_id` (or the verification command string when the failure is a gate command) + a normalized error signature. Normalize by keeping the stable part (error type/code, failing rule or test name) and stripping volatile parts (line numbers, file offsets, timestamps, memory addresses) — `TS2532`, not `TS2532-dashboard.ts:8`. Record the normalized key from the first failure; never widen a key after the fact to make two failures match. Store it under `failure_counts.by_blocker` for plan/structural failures and `failure_counts.by_command` for gate-command failures.
- **Consecutive**: only consecutive failures of the *same* key count. A success or a Thinker re-plan resets the counter for that key.
- **Two-strike trigger**: the second consecutive failure of the same key emits `[ESCALATION-REPORT]`. A third is not required — escalate on two.
- **Re-plan resets**: when the Thinker revises the todo list after a return, all `failure_counts` entries for the superseded todos are cleared, because the blocker key is no longer valid.

Never reset a counter to avoid escalation. If the same root cause keeps surfacing under different keys, treat that as a Thinker signal that the diagnosis is wrong.

### Escalation report format

```text
[ESCALATION-REPORT]
- 触发节点：[Agent Name / Current Phase Name]
- 失败次数：[Exact consecutive failure count]
- 核心瓶颈：[Precise technical blocker]
- 异常上下文：[Terminal traces, exception stack, or error block]
- 纠正性复盘：[Logic correction and next safe action]
```

---

## Operating Inside a Spec-Driven Project

When `docs/progress/MASTER.md` exists and the current task comes from a `spec-driven-develop` plan, one TAV cycle executes exactly one task card, while the enclosing delivery batch owns branches, integration validation, and the single batch PR. This is the execution half of the Handoff Contract defined in `spec-driven-develop` § "Boundary with TAV" — keep both sides in sync.

**Task intake (Thinker):**

- Take the task definition from the pending GitHub Issue or phase-file entry, not from a re-interpretation of the original user request.
- Treat the task card's acceptance criteria as the baseline of the verification plan; add stack-appropriate gates on top.
- Treat the task card's S.U.P.E.R design drivers as additional Verifier check items.
- Treat the task card's memory/governance impact field as pre-declared candidates for Phase 4 knowledge consolidation.

**Completion write-back (after Verifier passes):**

- Return `ready for batch integration` — do not create a task-level PR or use closing keywords. In orchestrator-direct execution, the orchestrator updates the Current Status and, after integrated validation plus the required authorization, performs closure through the batch PR's `Closes #N` line (or the LOCAL_ONLY checkbox). In a lane or delegated assignment, do not edit `MASTER.md`, an Issue, or a phase file.
- Return one execution-event payload from observed TAV signals: outcome, rework iterations, Thinker returns, files touched beyond the task card's "Affected Files" list, and the focused result for its declared S.U.P.E.R drivers. Only the orchestrator records it once according to `spec-driven-develop` `references/adaptive-control.md`.
- Return knowledge-consolidation candidates for the orchestrator to reconcile against "Governance Status" in MASTER.md. A lane or delegated TAV cycle never writes resolved memory or instruction surfaces directly.
- On `[ESCALATION-REPORT]` or a blocked state, return the event before pausing. Only the orchestrator records it in an authorized Issue comment or phase file and selects watch, replan, or rescope.

**State ownership:**

- `docs/progress/MASTER.md` (plus GitHub Issues) is the project-level authority; never duplicate project progress into `.tav/state.json`.
- `.tav/state.json` stays scoped to the single task in flight and is archived or deleted when that task completes. For concurrent L1 tasks, use `.tav/state-<task_id>.json` per task; never share writes between tasks.

---

## Tool and Agent Mapping

Role names are responsibilities, not hard dependencies on exact agent names.

| TAV role | Preferred implementation | Fallback |
|----------|--------------------------|----------|
| Thinker | Native plan mode, planning/exploration agent, read-only tools | Main agent read-only analysis |
| Diagnostic Actor | Actor role executing one disposable probe and cleanup micro-step | Main agent with the recorded probe contract |
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
- `references/verification-commands.md` - evidence-to-command selection for application stacks and configuration/IaC.
- `examples/bug-fix.md` - two-iteration loop where Verifier catches an incomplete fix.
- `examples/rate-limiting.md` - full L1 walkthrough including state file evolution.
- `examples/refactoring.md` - behavior-preserving extraction with plan-mismatch recovery.
- `CHANGELOG.md` - version history.

---

**End of TAV Workflow Skill**
