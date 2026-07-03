# TAV Workflow Implementation Guide

This guide describes how to operate the TAV workflow in a real coding session. It is intentionally tool-mapped rather than tied to one exact platform API.

## Operating Model

```text
Phase 0: Continuity Check
Phase 1: Thinker  - read-only analysis and plan
Phase 2: Actor    - minimal planned edits
Phase 3: Verifier - independent checks and quality gates
Phase 4: Complete - final report and state cleanup/archive
```

## Phase 0: Continuity Check

1. Check the target project root for `.tav/state.json`.
2. If the file exists, read it before any other work.
3. Resume from `current_phase` when the state belongs to the current task.
4. If the state belongs to another task, ask the user before replacing or archiving it.
5. If no state exists, initialize one using `references/templates/state.json`.

Important state fields:

- `current_phase`: `thinker`, `actor`, `verifier`, `complete`, or `blocked`.
- `todo_list`: atomic implementation tasks.
- `completed_steps`: completed chunks and evidence.
- `current_risk_level`: `low`, `medium`, `high`, or `critical`.
- `verification_commands`: exact checks selected from project evidence.
- `failure_counts`: repeated blocker and command failure tracking.

## Phase 1: Thinker

Thinker is read-only.

### Responsibilities

- Determine task tier: L0, L1, or L2.
- Gather file, symbol, command, or log evidence.
- Diagnose the implementation target or root cause.
- Produce an atomic todo list.
- Identify risks and verification commands.
- Ask one focused clarification question only if necessary.

### Output contract

Use `references/templates/thinker-output.md`.

Each todo item should contain:

- Target file or symbol.
- Specific action.
- Risk level.
- Expected verification evidence.

If the task is L2, stop and route to `spec-driven-develop` before implementation.

## Phase 2: Actor

Actor executes only the planned todo list.

### Responsibilities

- Apply minimal edits.
- Preserve surrounding style and naming.
- Avoid speculative abstractions.
- Update `completed_steps` after each chunk.
- Stop when the plan no longer matches the code.

### Read boundary

Actor may read target files or snippets when required by the edit mechanism or to confirm exact context. Actor must not perform new requirement discovery. Any structural mismatch returns to Thinker.

### Output contract

Use `references/templates/actor-output.md`.

## Phase 3: Verifier

Verifier independently checks the result.

### Responsibilities

- Inspect changed sections.
- Check references and side effects.
- Run selected verification commands when available.
- Add obvious stack-specific checks if Thinker missed them.
- Run an additional security review for sensitive surfaces.
- Record pass, fail, or skipped status with evidence.

### Stack-aware command selection

Pick commands only after inspecting project files.

| Evidence | Candidate checks |
|----------|------------------|
| `package.json` + `pnpm-lock.yaml` | `pnpm lint`, `pnpm typecheck`, `pnpm test` if scripts exist |
| `package.json` + `package-lock.json` | `npm run lint`, `npm run typecheck`, `npm test` if scripts exist |
| `package.json` + `yarn.lock` | `yarn lint`, `yarn typecheck`, `yarn test` if scripts exist |
| `pyproject.toml` | `ruff check .`, `mypy .`, `pytest` when configured |
| `Cargo.toml` | `cargo fmt --check`, `cargo clippy`, `cargo test` |
| `go.mod` | `go test ./...`, `go vet ./...` when applicable |

Do not claim a check passed unless it ran and succeeded. If a command is unavailable, record it under skipped or unexecuted checks.

### Output contract

Use `references/templates/verifier-output.md`.

## Error Recovery

| Situation | Action |
|-----------|--------|
| Requirement unclear | Ask one focused clarification question |
| Actor finds plan mismatch | Return to Thinker with evidence |
| Lint/type/test failure | Return to Actor with exact output |
| Same blocker fails twice | Emit `[PUA-REPORT]` |
| Critical security issue | Block completion and ask user for decision |
| Context or token pressure | Save state and pause |

## PUA Escalation

Use this when the same blocker, error block, or verification command fails twice consecutively.

```text
[PUA-REPORT]
- 触发节点：[Agent Name / Current Phase Name]
- 失败次数：[Exact consecutive failure count]
- 核心瓶颈：[Precise technical blocker]
- 异常上下文：[Terminal traces, exception stack, or error block]
- 惩罚性反思：[Logic correction and next safe action]
```

## Native Task Tracking

Use whatever task tracker the current platform actually exposes.

For Claude Code:

- Create one workflow task with `TaskCreate` for non-trivial work.
- Mark it `in_progress` before implementation.
- Use `TaskUpdate` as phases complete.
- Keep `.tav/state.json` as the durable recovery state.

Do not write instructions that require unavailable tool names such as `TodoWrite` or `TodoUpdate`.

## Completion Report

When files are modified, report:

```markdown
## 变更摘要
- Summary of implementation.

## 涉及文件
- `path/to/file` (Modified): details.

## 验证结果
- [x] `command` passed.

## 失败或未执行的命令
- `command` - reason.

## 剩余风险
- Known risks.

## 后续建议
- Next steps.
```

## Safety Notes

- Never delete or modify `.git` or `.svn` metadata.
- Ask before destructive, external, or hard-to-reverse actions.
- Do not rollback changes without explicit user approval unless the platform provides a safe non-destructive mechanism and the user authorized it.
- Report skipped checks honestly.

---

**End of Implementation Guide**
