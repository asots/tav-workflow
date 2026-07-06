---
name: tav-workflow
description: Use for scoped code changes, bug fixes, configuration updates, feature adjustments, and local refactors that need evidence-based analysis, minimal execution, and verification. Use spec-driven-develop first for rewrites, migrations, architecture overhauls, or broad multi-module transformations.
version: 3.2.0
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

When unsure, choose the higher tier.

---

## Phase 0: Continuity Check

Skip this phase entirely for L0 tasks.

For L1 tasks, check for `.tav/state.json` in the target project root before any analysis or edits.

- If it exists, matches the current task, and `last_update` is within 7 days, load it and resume from `current_phase`.
- If `last_update` is older than 7 days, treat the state as stale and ask the user before resuming or replacing it.
- If it describes a different task, ask the user before replacing or archiving it.
- If it does not exist, start fresh.

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

Use this final format when files were modified:

```markdown
## 变更摘要
- What changed and why.

## 涉及文件
- `path/to/file` (Modified): summary.

## 验证结果
- [x] `command` passed, or exact observed result.

## 失败或未执行的命令
- `command` - reason.

## 剩余风险
- Known limitations or edge cases.

## 后续建议
- Practical next steps.
```

Report only measurable facts. File and line counts come from `git diff --stat`; never estimate token usage or wall-clock duration.

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
- `references/implementation-guide.md` - operational details: state lifecycle, native task tracking, metrics rules, safety notes.
- `examples/bug-fix.md` - two-iteration loop where Verifier catches an incomplete fix.
- `examples/rate-limiting.md` - full L1 walkthrough including state file evolution.
- `examples/refactoring.md` - behavior-preserving extraction with plan-mismatch recovery.
- `CHANGELOG.md` - version history.

---

**End of TAV Workflow Skill**
