---
name: tav-workflow
description: Use for scoped code changes, bug fixes, configuration updates, feature adjustments, and local refactors that need evidence-based analysis, minimal execution, and verification. Use spec-driven-develop first only when at least two L2 escalation signals hold; a bare rewrite, migration, or refactor keyword is not sufficient.
license: MIT
metadata:
  version: 3.20.0
compatibility:
  spec-driven-develop: ">=1.29.0"  # spec-tav/v1 handoff contract
  write-notes-like-deepseek: "*"    # Phase 4 knowledge consolidation
  open-code-review: ">=1.9.0"       # Verifier Standards axis (delegate mode optional, v1.10.0+)
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
- Full-project rewrites, migrations, framework rebuilds, schema overhauls, or broad transformations that satisfy at least two L2 escalation signals below. Use `spec-driven-develop` first, then apply TAV to each scoped task.

---

## Task Tiering

Choose the smallest workflow that is still safe. See `../../shared-references/change-classification.md` for detailed definitions aligned with WNLD and SDD.

| Tier | Scope | Required workflow |
|------|-------|-------------------|
| L0 | Micro change, localized single-file patch, simple config value | Lightweight TAV in a single pass: cite evidence, edit, run a baseline check. No state file, no templated phase outputs. |
| L1 | Standard bug fix or feature touching multiple files | Full TAV: Thinker plan, Actor implementation, quality gates, Verifier review. |
| L2 | Work satisfying at least two L2 escalation signals below; common examples include broad architecture, migration, auth, schema, or distributed-flow overhauls | Run `spec-driven-develop` first; then execute independent scoped tasks with TAV. |

`L0/L1/L2` is the TAV task tier for scope and risk. It is independent from Spec-Driven Develop's `Tier 0/1/2` delivery-batch dispatch tier for direct, delegated, or parallel execution.

### L0 vs L1 boundary

Tier is about risk and blast radius, not just file count. Choose L1 when **any** of these hold; otherwise L0:

- The change touches a security-sensitive surface (auth, user input, DB queries, file paths, payments, secrets, external APIs).
- The change can affect runtime behavior beyond the edited file (shared state, public API, config consumed by other services).
- The fix needs a new or strengthened test to prove correctness.
- The diff will likely exceed ~30 lines or touch 2+ files.

A one-line typo, display-text correction, or local metadata change stays L0 only when evidence proves it cannot change runtime, security, data, public-contract, or external-system behavior. The containing filename never creates an exception to the sensitive-surface rules. When unsure, choose the higher tier.

### L2 Escalation Signals

Keep this list in sync with `spec-driven-develop` § "Escalation Signals" and `../../shared-references/change-classification.md` — all workflows must apply the same test. Escalate to L2 only when **at least two** of these hold; otherwise stay at L0/L1:

- The change spans 3+ modules/subsystems, or breaks a public API/schema contract.
- The work will realistically span multiple sessions or exceed ~10 files.
- Architectural decisions are required (layering, dependency direction, technology selection).
- Acceptance criteria cannot be defined within a single Thinker-Actor-Verifier cycle.

A refactor confined to one module — however messy — stays at L1 (TAV territory).

When unsure between L0 and L1, choose L1. Do not choose L2 unless at least two escalation signals hold.

---

## Authority and External-State Contract

TAV tiering determines engineering rigor, not permission. Read-only inspection and user-requested local edits are allowed within scope; every action below requires its own explicit authorization and one permission never implies another:

- create or switch a branch/worktree;
- commit or amend;
- push or force-push;
- create, edit, merge, or close a PR;
- create or update Issues, Projects, milestones, labels, or other remote tracker state;
- deploy, publish, restart services, purchase, or mutate any external environment;
- archive, move, or delete local workflow state.

Without cleanup authorization, leave task state at `current_phase: complete`, set `cleanup_status: awaiting_authorization`, and report the pending cleanup. Never interpret README guidance such as "commit with the repo" as authorization to run Git commands.

---

## Phase 0: Continuity Check

Every tier, including L0, runs the `docs/progress/MASTER.md` check below. L0 skips only the state-file checks: it never creates or resumes `.tav/state.json`.

For L1 tasks, check for `.tav/state.json` in the target project root before any analysis or edits. If multiple L1 tasks are running concurrently in the same project, use a task-scoped state file named `.tav/state-<task_id>.json` instead, and resume only from the file whose `task_id` matches the current request.

- If it exists, matches the current task, and `last_update` is within 7 days, load it and resume from `current_phase`.
- If `last_update` is older than 7 days, treat the state as stale and ask the user before resuming or replacing it.
- If it describes a different task, ask the user before replacing or archiving it.
- If it does not exist, start fresh.

For every tier, also check for `docs/progress/MASTER.md` in the target project. If it contains the exact `**Workflow State**: archived` marker, it is a Spec-Driven tombstone rather than an active plan, and TAV never enters spec-driven task mode from it. When `Pending Operations` is `none`, the current request proceeds as a standalone TAV task. When pending operations are listed, they block only a request to continue or finish that archived run: return the archive pointer and exact next action to the Spec-Driven orchestrator, or, when no orchestrator is running, stop and tell the user to resume the run with `spec-driven-develop`; never perform the pending operations inside a TAV cycle. An unrelated request proceeds as a standalone TAV task and lists the pending operations in the final report. Otherwise, if MASTER exists and the current task belongs to that active plan, follow `references/spec-driven-interop.md` for task intake, write-back, and state ownership.

When a resumable TAV state has a non-null `origin.spec_run_id`, confirm that its run ID, task-card ID, delivery-batch ID, and rollback boundary still match the active MASTER/task card before resuming. A mismatch is different-task evidence: ask before replacing or archiving the state; never silently attach it to another plan.

Create `.tav/state.json` only when the work is likely to span sessions or needs multiple Actor-Verifier iterations. For ordinary single-session L1 tasks, the platform's native task tracker is sufficient.

Never let two TAV cycles write the same state file. `current_phase`, `todo_list`, and `failure_counts` belong to one task only and must not leak across parallel work.

Key state fields: `current_phase` (`thinker|actor|verifier|complete|blocked`), `task_tier` (`L0|L1|L2`), `origin`, `cleanup_status`, `current_risk_level` (`low|medium|high|critical`), `todo_list`, `completed_steps`, `verification_commands`, `diagnosis`, `tdd`, `review_axes`, `failure_counts`, `last_update`. Read `references/templates/state.json` before creating the file for the first time; keep field names exactly as the template defines them. Store compact commands, results, and evidence pointers — never full logs or duplicated phase reports.

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
- Redact secrets, credentials, cookies, authorization headers, connection strings, private user data, and sensitive payloads before placing evidence in state, reports, memory, or remote trackers. Keep full logs only in an approved local location and cite a compact pointer.
- Prefer targeted reads and searches over broad file dumps.
- If the project has a memory index (`docs/memory/MEMORY.md`), read **only the index lines** (one hook per entry) and shortlist entries whose hook mentions the task's files, modules, or topic. Open only the shortlisted entry files, then use their `applies_to`/`tags` frontmatter to confirm relevance and discard mismatches — previously captured knowledge is first-class evidence, but loading every entry wastes context. If a recalled entry contradicts the current code or reality, flag it as a stale-entry candidate for Phase 4 (update or delete).
- If the project has a domain glossary (`CONTEXT.md`, or a `CONTEXT-MAP.md` pointing at per-context glossaries), read the entries relevant to the task and use the canonical terms in the diagnosis, todo items, and any new names. When the user's phrasing, the glossary, and the code disagree, surface the contradiction instead of silently picking one side; term resolution routes through the `domain-modeling` skill when available, and decision recording follows the Phase 4 write targets. When that skill is unavailable, apply the same evidence-first terminology challenge directly and return any confirmed glossary or decision write-back candidate for Phase 4.
- If the project keeps decision records (decision notes under `.agents/notes/`, or an ADR directory such as `docs/adr/`), search them for the touched modules and mechanism names before planning; `.agents/` is hidden, so include hidden paths in the search (for example `rg --hidden`) and skip `.agents/notes/archived/`. Treat implemented notes and accepted ADRs as constraints, proposed notes for the touched modules as pending intent (when the task implements one, Phase 4 moves it to implemented), and rejected notes as approaches not to re-propose unless new evidence removes the reason they were rejected. When the requested change contradicts a recorded decision, surface the conflict instead of silently overriding it.
- If the project has CodeGraph available, use it before grep-style exploration.
- Do not invent file paths, commands, package managers, or test scripts.
- Stop exploring once the todo list can be written at file-level precision — evidence gathering serves the plan, not completeness.

### Hard-bug diagnosis branch

Use this branch when the failure resists an obvious first-pass explanation, is intermittent, is a performance regression, or the user explicitly asks for diagnosis/debugging. Ordinary scoped fixes keep the standard Thinker flow. Read `references/branches.md` § "Hard-bug diagnosis branch" and follow it: establish a red-capable feedback loop before theorizing, reproduce and minimize, rank falsifiable hypotheses, probe one variable at a time, plan the regression proof at the correct seam, and close the loop. File-changing probes run through the diagnostic Actor micro-loop defined there; the Thinker stays read-only, and diagnosis stops with a report when no usable feedback loop can be built.

### Design-prototype branch

Use this branch when a plan decision hinges on how a state model, interaction, or interface should behave and repository evidence cannot settle it — the question is "does this design feel right?", not "why does this fail?". Follow `references/branches.md` § "Design-prototype branch": build a throwaway prototype that answers that single question, record the question, run command, and validated decision in the Thinker output, and let the Verifier confirm no prototype code remains in the delivered change. Use the `prototype` skill when the platform provides it.

### Required Thinker output

For every L1 cycle, read and fill `references/templates/thinker-output.md`. That template is the canonical Thinker output schema; do not replace it with an abbreviated inline format. Mark non-applicable hard-bug, test-seam, and design-prototype fields explicitly rather than omitting them.

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
6. For long task cards (5+ todo items or an expected diff beyond ~300 lines), checkpoint proactively: after every 3-4 completed todos, persist progress (`.tav/state.json` when in use, otherwise the native task tracker) and run the cheapest relevant gate (syntax or type check) on the touched files before continuing. Recovery from a mid-task interruption must never depend on conversation memory. When the card came from a Spec-Driven plan, `XL` is invalid at task level; return it for decomposition into recoverable task cards instead of treating checkpointing as a reason to widen it.

### Actor boundaries

- Actor may read target files when the editing tool requires it or when confirming exact edit context.
- Actor must not perform new requirement exploration.
- If code structure contradicts the Thinker plan, stop and return to Thinker with the blocking evidence.
- Do not add comments, abstractions, dependencies, or formatting changes unless they are part of the plan.
- Do not silently improvise; deviations require a return to Thinker.

### TDD execution branch

Use test-driven execution when the Thinker plan requires new or strengthened automated tests, when the hard-bug branch produced a regression proof, or when the user explicitly requests test-first work. Read `references/branches.md` § "TDD execution branch" and follow it: the Thinker names the test seam (highest stable public boundary; ask only when competing seams materially change scope, architecture, or cost), work advances one vertical red-green behavior slice at a time, expected values come from an independent source of truth, unplanned structural needs return to Thinker, and red/green command evidence is recorded for the Verifier.

### Required Actor output

For every L1 cycle, read and fill `references/templates/actor-output.md`. That template is the canonical Actor output schema; mark diagnostic-probe and TDD sections as not applicable when unused.

---

## Phase 3: Verifier - Closed-Loop Quality Gate

Verifier checks the change independently. Do not rely on Actor's summary.

### Required actions

1. Run `git diff` and `git status --porcelain` (or the VCS equivalents) first and review the actual changes, not the reported ones. `git diff` does not show untracked files; read every new (`??`) file in full.
2. Check surrounding code and references affected by the change.
3. Treat Thinker's `verification plan` as candidate commands; confirm each still matches the project stack (re-read the evidence if unsure), run them, and add any stack-appropriate checks Thinker missed. Do not silently re-derive the whole list from scratch.
4. Check security-sensitive surfaces when relevant.
5. Perform the two-axis review below after machine checks; keep Standards and Spec findings separate.
6. Verify behavior, not just file presence.
7. Record pass/fail results in native task tracking (and `.tav/state.json` if it exists).
8. Flag knowledge consolidation candidates observed during review — rework lessons, non-obvious root causes, undocumented project commands — for evaluation in Phase 4.

### Verification command selection

Use project evidence before choosing commands. Read `references/verification-commands.md` when selecting application-stack or configuration/IaC gates; it contains the evidence-to-command table and external-state safety limits.

If no reliable command exists, state that explicitly under failed or unexecuted commands. Never claim verification passed without running or justifying the gate.

### Two-axis review

Machine gates prove that configured checks ran; they do not prove that the right change was made. Review the actual diff through two independent axes:

1. **Standards** — compare the diff with repository instruction and coding-standard sources. Project rules override generic heuristics. Where tooling does not already enforce the issue, look for judgment-call smells such as unclear naming, duplicated logic, misplaced responsibility, data clumps, repeated conditionals, shotgun/divergent change, speculative generality, long navigation chains, delegation-only middle layers, or inheritance that does not fit. Label heuristics as possible smells, not hard violations.
2. **Spec** — compare the diff with the task definition and acceptance criteria. Identify requested behavior that is missing or partial, behavior added without authorization, and implementation that appears present but does not satisfy the requirement. Flag a change that contradicts a recorded decision found during Phase 1 evidence gathering (an implemented note, accepted ADR, or rejected approach) unless the task explicitly supersedes it.

Do not merge the axes into one score: a change can satisfy standards while implementing the wrong thing, or satisfy the spec while violating project rules. When independent reviewer agents are available and their cold-start cost is justified, the axes may run in parallel; otherwise the Verifier performs two explicit passes. This review supplements, never replaces, tests, type/lint checks, compatibility review, security review, and configuration/IaC validation.

**OCR Integration for Standards Axis**:

When the `ocr` CLI (open-code-review v1.9.0+) is available, use it for the Standards axis:

```bash
# Extract context from Thinker output
context="Task: <task description>. Root cause: <diagnosis summary>"

# Run OCR with business context
ocr review --audience agent \
  --background "$context" \
  --output /tmp/ocr_standards.json
```

Filter OCR output by severity:
- `critical` → escalate TAV to critical risk, block completion
- `high` → must fix before Verifier approval
- `medium` → fix or document as known limitation
- `low` → discard as likely false positive

See `../../open-code-review/skills/open-code-review/SKILL.md` § "Integration with TAV and Spec-Driven Development" for detailed invocation patterns and the `references/implementation-guide.md` § "Two-axis review mechanics" for delegate mode usage (v1.10.0+).

### Security-sensitive branch

If the change touches authentication, authorization, user input, database queries, file system paths, external APIs, cryptography, payments, or secrets:

- Run an additional security review pass.
- Check for hardcoded secrets, injection, path traversal, unsafe error disclosure, missing validation, and authorization bypass.
- Block completion on critical issues.

### Verifier independence escalation

When the change touches a security-sensitive surface, or the same task has accumulated two or more rework iterations, run the Verifier as an independent reviewer agent when the platform provides one. A first rework iteration should trigger an explicit side-effect review and consider independent verification; the second consecutive failure requires it. The second failure escalates verification independence, not just the report — the agent that wrote a fix twice is the least likely to see what is still wrong with it.

### Required Verifier output

For every L1 cycle, read and fill `references/templates/verifier-output.md`. That template is the canonical Verifier output schema; it requires separate Standards and Spec axes even when both pass.

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

Write target — resolve the memory surface before choosing a file. Items 1-3 are the memory-resolution priority order; domain and instruction surfaces in items 4-5 are type-specific destinations and do not compete in that order:

1. **Existing governance or declared project memory surface** — in a spec-driven project, `docs/progress/MASTER.md` "Governance Status" wins; otherwise use the project's already declared memory surface. Do not create a competing source.
2. **The platform's native project memory** — the default when no existing project declaration takes precedence and native memory is available.
3. **A repo-local fallback** (`docs/memory/`) — only when the project already declares it or the user explicitly selects it. When selected, use one entry per file plus a `MEMORY.md` index line; commit it with the repository.
4. **Domain surfaces** (`CONTEXT.md` glossary; decision notes) — confirmed canonical terms go to the glossary through the `domain-modeling` skill when available. Decisions that are costly to reverse, surprising without context, and the result of a genuine trade-off go to a decision note through the `write-notes-like-deepseek` skill, which owns the note location, format, verification gate, and archival; when that skill is unavailable, list the decision as a final-report candidate instead of hand-writing a note. Do not duplicate terms or decisions into general memory. Inside a TAV cycle, the capture test above decides whether a decision note is written; `write-notes-like-deepseek` governs only where and how. The note is written in Phase 4, after the change exists (the Thinker stays read-only), and a change that implements an existing proposed note moves it to implemented in the same change.
5. **An existing instruction surface** (`CLAUDE.md`, `AGENTS.md`, or an existing platform rule file) — high-bar exception, only for a rule that must be unconditionally present in every session. Add at most one line; link to the resolved memory surface for detail.

If the knowledge fits none of these, list the candidate in the final report. Do not create ad-hoc files outside the resolved memory surface; decision notes written through the `write-notes-like-deepseek` skill are the sanctioned exception. Directory layout and operational mechanics (entry format, dedupe, append discipline) are in `references/implementation-guide.md` § "Knowledge Consolidation".

### Post-consolidation verification

When Phase 4 writes or updates a memory, instruction, glossary, or decision-note surface, rerun `git diff` and `git status --porcelain` after that write, inspect the newly changed hunk or file, and run the narrowest available documentation/static validation. Recheck the added material for secrets and sensitive evidence. The Phase 3 verdict covers the implementation diff; do not claim it automatically verifies documentation written afterwards.

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

Report only measurable facts. File and line counts come from `git diff --stat` plus the untracked (`??`) files in `git status --porcelain`; never estimate token usage or wall-clock duration.

In a spec-driven project (see `references/spec-driven-interop.md`), completion additionally requires a handoff. In orchestrator-direct execution, the orchestrator records authorized project-level progress and execution events; in a lane or delegated assignment, return the write-back payload and do not mark the project task complete yourself. Knowledge consolidation, when it fires, is returned as a candidate and routes through the governance surfaces resolved in MASTER.md.

Archive or remove `.tav/state.json` only after completion, only if it belongs to the completed workflow, and only with explicit cleanup authorization. Otherwise preserve it with `current_phase: complete` and `cleanup_status: awaiting_authorization`. Do not delete VCS metadata under any circumstance.

---

## Error Recovery and Escalation

| Failure | Detection | Action |
|---------|-----------|--------|
| Ambiguous requirement | Thinker | Ask one focused question, then update plan |
| Incomplete plan | Actor | Stop and return to Thinker with evidence |
| Quality gate failure | Verifier | Return to Actor with exact command output |
| Same blocker fails twice | Any phase | Emit `[ESCALATION-REPORT]`, run verification escalation, and re-plan before more implementation |
| Critical security issue | Verifier | Block completion and request explicit user decision |
| Token/context pressure | Any phase | Save state, summarize progress, pause |

### Risk level dynamics

Risk level is set in Thinker and may change as evidence accumulates. Escalate (never silently downgrade) when the Verifier surfaces new information:

| Level | Typical trigger | Required action |
|-------|-----------------|-----------------|
| low | Localized, obvious change, no security/data surface | Standard TAV |
| medium | Multi-file or behavior-affecting change, no sensitive surface | Standard TAV; Verifier checks side effects |
| high | Touches a security-sensitive surface or evidence shows materially wider blast radius | Explicit side-effect and relevant security review; use an independent Verifier when available |
| critical | Confirmed security issue, data-loss risk, irreversible operation, or authority/spec boundary crossing | Block completion; request explicit user decision before proceeding |

Risk escalation is independent from rework counting. A rework iteration can increase verification independence without changing risk; run the security-sensitive branch only when the affected surface warrants it. Downgrading requires fresh Thinker evidence that the original trigger no longer applies — record the reason in the Verifier output.

### Failure counting

The blocker key is `todo_id` (or the gate command) plus a normalized error signature: keep the stable part (error code, failing rule or test name) and strip volatile parts (line numbers, file offsets, timestamps), so record `TS2532`, not `TS2532-dashboard.ts:8`, from the first failure on. Only consecutive, unexpected, comparable failures of the same key count; expected TDD RED results, pre-change baseline failures, hypothesis probes, intentionally incomplete intermediate checks, and confirmed environment failures do not. The second consecutive failure emits `[ESCALATION-REPORT]`, requires an independent Verifier when available, and returns to Thinker for a re-plan, which clears the superseded keys. Never reset a counter to avoid escalation. When a failure first repeats, read `references/escalation.md` for the reset semantics and the report format.

---

## Operating Inside a Spec-Driven Project

When an active (non-tombstone) `docs/progress/MASTER.md` exists and the current task comes from a `spec-driven-develop` plan, one TAV cycle executes exactly one task card and the enclosing delivery batch owns branches, integration validation, and the single batch PR. This skill implements the execution half of the `spec-tav/v1` handoff contract defined in `spec-driven-develop` § "Boundary with TAV". Before task intake, read `references/spec-driven-interop.md`; it owns the task-intake, completion write-back, and state-ownership rules.

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

- `references/branches.md` - full contracts for the hard-bug diagnosis, diagnostic Actor micro-loop, design-prototype, and TDD execution branches; read when a branch trigger fires.
- `references/spec-driven-interop.md` - execution half of the `spec-tav/v1` handoff contract; read when an active MASTER.md is present.
- `references/escalation.md` - failure-counting rules and the `[ESCALATION-REPORT]` format; read when a failure first repeats.
- `references/templates/state.json` - read before creating `.tav/state.json` for the first time.
- `references/templates/thinker-output.md`, `actor-output.md`, `verifier-output.md` - canonical L1 phase-output schemas; read the matching template before producing each phase output.
- `references/implementation-guide.md` - operational details: state lifecycle, native task tracking, metrics rules, knowledge consolidation mechanics, safety notes.
- `references/verification-commands.md` - evidence-to-command selection for application stacks and configuration/IaC.
- `examples/bug-fix.md` - two-iteration loop where Verifier catches an incomplete fix.
- `examples/rate-limiting.md` - full L1 walkthrough including state file evolution.
- `examples/refactoring.md` - behavior-preserving extraction with plan-mismatch recovery.
- `examples/l0-quick-patch.md` - L0 single-pass patch without state or templated phase outputs.
- `examples/two-strike-escalation.md` - the second consecutive same-key failure and the escalation report.

---

**End of TAV Workflow Skill**
