---
name: tav-workflow
description: Use for scoped code changes, bug fixes, configuration updates, feature adjustments, and local refactors that need evidence-based analysis, minimal execution, and verification. Use spec-driven-develop first for rewrites, migrations, architecture overhauls, or broad multi-module transformations.
version: 3.1.0
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
- Trivial single-step edits that need no analysis.
- Full-project rewrites, migrations, framework rebuilds, schema overhauls, or broad transformations. Use `spec-driven-develop` first, then apply TAV to each scoped task.

---

## Task Tiering

Choose the smallest workflow that is still safe.

| Tier | Scope | Required workflow |
|------|-------|-------------------|
| L0 | Micro change, localized single-file patch, simple config value | Lightweight TAV: evidence, edit, baseline verification |
| L1 | Standard bug fix or feature touching multiple files | Full TAV: Thinker plan, Actor implementation, quality gates, Verifier review |
| L2 | Architecture, migration, auth overhaul, database schema, distributed flow | Run `spec-driven-develop` first; then execute independent scoped tasks with TAV |

When unsure, choose the higher tier.

---

## Phase 0: Continuity Check

Before any analysis or edits, check for `.tav/state.json` in the target project root.

- If it exists and is relevant to the current task, load it and resume from `current_phase`.
- If it exists but describes a different task, ask the user before replacing or archiving it.
- If it does not exist, start a fresh workflow.

Use this durable state schema:

```json
{
  "version": "3.1.0",
  "task_id": "tav-YYYYMMDD-HHMMSS",
  "user_request": "Original user request",
  "task_tier": "L0|L1|L2",
  "current_phase": "thinker|actor|verifier|complete|blocked",
  "current_risk_level": "low|medium|high|critical",
  "todo_list": [],
  "completed_steps": [],
  "verification_commands": [],
  "failure_counts": {},
  "phase_outputs": {},
  "metrics": {}
}
```

Use the platform's native task tracker when available. In Claude Code, map workflow progress to `TaskCreate`, `TaskUpdate`, `TaskList`, and `TaskGet`. Do not assume `TodoWrite` or `TodoUpdate` exists.

---

## Phase 1: Thinker - Analysis and Scoping

Thinker is read-only. Do not edit files in this phase.

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

After Thinker completes, update `.tav/state.json` and native task tracking.

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

1. Inspect changed files or changed sections.
2. Check surrounding code and references affected by the change.
3. Run the verification commands selected by Thinker when possible.
4. Add stack-appropriate checks if Thinker missed obvious project commands.
5. Check security-sensitive surfaces when relevant.
6. Record pass/fail results in `.tav/state.json`.

### Stack-aware verification command selection

Use evidence from project files before choosing commands.

| Evidence | Typical commands |
|----------|------------------|
| `package.json` + `pnpm-lock.yaml` | `pnpm lint`, `pnpm typecheck`, `pnpm test` if scripts exist |
| `package.json` + `package-lock.json` | `npm run lint`, `npm run typecheck`, `npm test` if scripts exist |
| `pyproject.toml` | `ruff check .`, `mypy .`, `pytest` when configured |
| `Cargo.toml` | `cargo fmt --check`, `cargo clippy`, `cargo test` |
| `go.mod` | `go test ./...`, `gofmt`/`go vet` when applicable |

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
| Thinker | Planning/exploration agent, read-only tools | Main agent read-only analysis |
| Actor | Coding/execution agent or main agent edits | Main agent with strict todo list |
| Verifier | Reviewer agent, test tools, security reviewer when needed | Main agent independent verification |
| Progress tracking | `TaskCreate` / `TaskUpdate` / native todo tool | `.tav/state.json` only |

For independent read-only analysis, use parallel agents when helpful. For edits, avoid uncontrolled parallel modification unless isolated worktrees are explicitly requested or provided.

---

## Best Practices

### Thinker

- See evidence before deciding.
- Keep todo items atomic and executable.
- Include exact verification commands.
- Escalate L2 work to `spec-driven-develop`.

### Actor

- Change only what the todo list requires.
- Keep edits small and complete.
- Do not silently improvise.
- Preserve style and naming conventions.

### Verifier

- Verify behavior, not just file presence.
- Run project-appropriate checks.
- Report failed or skipped checks honestly.
- Reopen Actor or Thinker when evidence contradicts the plan.

---

## References

- `README.md` - overview and quick start.
- `references/implementation-guide.md` - operational guide.
- `references/templates/state.json` - state schema template.
- `references/templates/thinker-output.md` - Thinker output template.
- `references/templates/actor-output.md` - Actor output template.
- `references/templates/verifier-output.md` - Verifier output template.
- `examples/` - walkthrough examples.

---

## Version History

### 3.1.0 (2026-07-03)

- Aligned state schema with `current_phase`, `todo_list`, `completed_steps`, and `current_risk_level`.
- Replaced hard-coded `TodoWrite` assumptions with platform-native task tracking guidance.
- Added L0/L1/L2 task tiering and `spec-driven-develop` escalation.
- Added stack-aware verification command selection.
- Clarified Actor read boundaries and incomplete-plan handling.
- Added security-sensitive verification branch and two-failure PUA escalation.
- Replaced shell-specific cleanup guidance with platform-neutral safety rules.

### 3.0.0 (2026-05-19)

- Added automated role orchestration, state persistence, quality gates, and examples.

### 2.0.0 (Previous)

- Initial three-role workflow definition.

---

**End of TAV Workflow Skill**
