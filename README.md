# TAV Workflow - README

## Overview

TAV (Think-Act-Verify) is a structured workflow for scoped software changes. It separates analysis, execution, and verification so that every non-trivial edit is evidence-based, minimal, and checked before completion.

**Version**: 3.1.0
**Status**: Stable

## Quick Start

Use TAV when a request changes code, configuration, dependencies, tests, workflows, or deployment manifests.

```text
User request: "Fix the checkout validation bug"

TAV workflow:
1. Phase 0 checks `.tav/state.json` for resumable work.
2. Thinker gathers evidence and writes an atomic plan.
3. Actor applies only the planned changes.
4. Verifier runs stack-appropriate checks and reviews side effects.
5. Completion reports modified files, verification results, skipped checks, and residual risks.
```

## When to Use

### Use TAV for

- Bug fixes.
- Scoped feature implementation.
- Local refactors with known target behavior.
- Configuration updates.
- Dependency or workflow changes.

### Use something else for

- Pure read-only questions: answer directly.
- Trivial one-step edits: use lightweight TAV only.
- Rewrites, migrations, architecture overhauls, or multi-phase transformations: run `spec-driven-develop` first, then use TAV for each scoped implementation task.

## Task Tiers

| Tier | Scope | Workflow |
|------|-------|----------|
| L0 | Micro change or obvious single-file patch | Lightweight evidence, edit, baseline verification |
| L1 | Standard bug fix or feature across multiple files | Full Thinker -> Actor -> Verifier workflow |
| L2 | Architecture, migration, schema, auth overhaul, distributed flow | `spec-driven-develop` first, then TAV per scoped task |

## Key Features

### Role Separation

- **Thinker**: read-only evidence gathering, diagnosis, todo list, risk assessment.
- **Actor**: minimal implementation of the approved todo list.
- **Verifier**: independent review, tests/lint/type checks, security and side-effect checks.

### State Persistence

- Durable state lives at `.tav/state.json`.
- Interrupted workflows resume from `current_phase`.
- The state records `todo_list`, `completed_steps`, `current_risk_level`, verification commands, failures, and metrics.

### Native Task Tracking

- Use the current platform's real task tools.
- In Claude Code, map progress to `TaskCreate`, `TaskUpdate`, `TaskList`, and `TaskGet`.
- Do not assume `TodoWrite` or `TodoUpdate` exists.

### Stack-Aware Quality Gates

TAV chooses verification commands from repository evidence:

| Project evidence | Typical checks |
|------------------|----------------|
| `package.json` + `pnpm-lock.yaml` | `pnpm lint`, `pnpm typecheck`, `pnpm test` when scripts exist |
| `package.json` + `package-lock.json` | `npm run lint`, `npm run typecheck`, `npm test` when scripts exist |
| `pyproject.toml` | `ruff check .`, `mypy .`, `pytest` when configured |
| `Cargo.toml` | `cargo fmt --check`, `cargo clippy`, `cargo test` |
| `go.mod` | `go test ./...`, `go vet ./...` when applicable |

If no reliable command exists, the final report must say which checks were not run and why.

### Error Recovery

- Incomplete Actor plan returns to Thinker.
- Quality gate failure returns to Actor with exact command output.
- Critical security issues block completion.
- The same blocker failing twice triggers `[PUA-REPORT]` escalation.

## Architecture

```text
User request
    |
Phase 0: Continuity Check
    |-- load `.tav/state.json` when relevant
    |
Phase 1: Thinker
    |-- evidence, diagnosis, todo list, risks, verification plan
    |
Phase 2: Actor
    |-- minimal planned edits only
    |
Phase 3: Verifier
    |-- changed-code review, tests/lint/typecheck, security checks
    |
Phase 4: Completion
    |-- final report and state cleanup/archive
```

## State File

Location: `.tav/state.json`

Recommended `.gitignore` entry:

```gitignore
.tav/
```

Core schema:

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

See [references/templates/state.json](references/templates/state.json) for the complete template.

## Final Report Format

When files are modified, completion must include:

```markdown
## 变更摘要
- What changed and why.

## 涉及文件
- `path/to/file` (Modified): summary.

## 验证结果
- [x] `command` passed.

## 失败或未执行的命令
- `command` - reason.

## 剩余风险
- Known limitations.

## 后续建议
- Practical next steps.
```

## Examples

- [examples/rate-limiting.md](examples/rate-limiting.md) - API rate limiting walkthrough.
- [examples/bug-fix.md](examples/bug-fix.md) - Bug fix with iteration.
- [examples/refactoring.md](examples/refactoring.md) - Local refactor walkthrough.

## Documentation

- [SKILL.md](SKILL.md) - Complete skill specification.
- [CHANGELOG.md](CHANGELOG.md) - Version history.
- [Implementation Guide](references/implementation-guide.md) - Operational guidance.
- [State Template](references/templates/state.json) - Durable state schema.
- [Thinker Output](references/templates/thinker-output.md) - Thinker output format.
- [Actor Output](references/templates/actor-output.md) - Actor output format.
- [Verifier Output](references/templates/verifier-output.md) - Verifier output format.

## Version History

### v3.1.0 (2026-07-03)

- Aligned durable state with snake_case TAV fields.
- Replaced conceptual todo tool names with platform-native task tracking guidance.
- Added L0/L1/L2 task tiering.
- Added stack-aware verification command selection.
- Added Actor read-boundary clarification.
- Added security-sensitive verification branch and two-failure PUA escalation.

### v3.0.0 (2026-05-19)

- Automated role orchestration.
- State persistence.
- Native progress integration.
- Quality gates.
- Error recovery.
- Examples and templates.

## License

MIT

---

**TAV Workflow v3.1.0**
*Think-Act-Verify: evidence-based change, minimal execution, verified completion.*
