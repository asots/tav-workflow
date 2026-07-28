# TAV Workflow - README

English | [简体中文](README.zh-CN.md)

## Overview

TAV (Think-Act-Verify) is a structured workflow for scoped software changes. It separates analysis, execution, and verification so that every non-trivial edit is evidence-based, minimal, and checked before completion.

**Version**: 3.11.0
**Status**: Stable

The authoritative specification lives in [SKILL.md](SKILL.md). This README is an overview for humans; schemas, command tables, and output contracts are defined once in the skill file and referenced from here.

## Quick Start

Use TAV when a request changes code, configuration, dependencies, tests, workflows, or deployment manifests.

```text
User request: "Fix the checkout validation bug"

TAV workflow:
1. Phase 0 checks `.tav/state.json` for resumable work (L1 only, skipped for L0).
2. Thinker gathers evidence and writes an atomic plan.
3. Actor applies only the planned changes.
4. Verifier reviews the real diff, runs stack-appropriate checks, and looks for side effects.
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
- Rewrites, migrations, architecture overhauls, or multi-phase transformations: run `spec-driven-develop` first, then use TAV for each scoped implementation task.

## Task Tiers

| Tier | Scope | Workflow |
|------|-------|----------|
| L0 | Micro change or obvious single-file patch | Single-pass lightweight TAV: evidence, edit, baseline check. No state file. |
| L1 | Standard bug fix or feature across multiple files | Full Thinker -> Actor -> Verifier workflow |
| L2 | Architecture, migration, schema, auth overhaul, distributed flow | `spec-driven-develop` first, then TAV per scoped task |

`L0/L1/L2` is the TAV task tier for scope and risk. It is independent from Spec-Driven Develop's `Tier 0/1/2` delivery-batch dispatch tier for direct, delegated, or parallel execution.

## Key Features

- **Role separation**: read-only Thinker, minimal-change Actor, independent Verifier that starts from `git diff`, not from the Actor's summary; security-sensitive or twice-reworked changes escalate to an independent reviewer agent.
- **Hard-bug diagnosis**: difficult, intermittent, and performance failures first get a red-capable feedback loop, minimized reproduction, and falsifiable hypotheses. When a probe needs file edits, a disposable diagnostic Actor applies and removes it before control returns to the read-only Thinker.
- **Planned-seam TDD**: behavior changes advance one vertical red-green slice at a time through the highest stable public seam selected during Thinker analysis.
- **Two-axis review**: after machine gates, Verifier reports repository Standards and task Spec findings separately so correctness on one axis cannot hide failure on the other.
- **State persistence**: `.tav/state.json` enables resuming interrupted L1 work; states older than 7 days are treated as stale. See [SKILL.md](SKILL.md) Phase 0 for the schema and [references/templates/state.json](references/templates/state.json) for the full template.
- **Independent authority gates**: branch/worktree, commit, push, PR, tracker writes, deployment, and local state cleanup each require explicit authorization; tier selection never grants permission.
- **Native task tracking**: progress maps to the platform's real task tools (in Claude Code: `TaskCreate` / `TaskUpdate`).
- **Stack-aware quality gates**: verification commands are chosen from repository evidence (lockfiles, `pyproject.toml`, `Cargo.toml`, `go.mod`, CI config). The full table is in [Verification Command Selection](references/verification-commands.md).
- **Error recovery**: plan mismatches return to Thinker, gate failures return to Actor, the same blocker failing twice triggers `[ESCALATION-REPORT]` escalation, and critical security issues block completion.
- **Knowledge consolidation**: after gates pass, durable lessons use the project's resolved memory surface: an existing declaration first, then native project memory, then `docs/memory/` only when it is already declared or explicitly selected. Glossaries/ADRs and instruction files are type-specific destinations, not competitors in that memory priority order. See [SKILL.md](SKILL.md) Phase 4.
- **Spec-driven interop**: inside a `spec-driven-develop` project, one TAV cycle executes one task card and returns progress plus the canonical Outcome/Rework/Plan returns/Unplanned dependencies/Focused S.U.P.E.R execution event to the orchestrator. See [SKILL.md](SKILL.md) "Operating Inside a Spec-Driven Project".

## Architecture

```text
User request
    |
Phase 0: Continuity Check (L1 only)
    |-- load `.tav/state.json` when relevant and fresh
    |
Phase 1: Thinker
    |-- evidence, diagnosis, hard-bug feedback loop when needed
    |-- todo list, risks, test seams, verification plan
    |
Phase 2: Actor
    |-- minimal planned edits; vertical red-green slices when required
    |
Phase 3: Verifier
    |-- git diff, machine gates, Standards/Spec review, security checks
    |
Phase 4: Completion
    |-- knowledge consolidation, final report, authorized state cleanup/archive
```

## State File

Location: `.tav/state.json` (created only when work may span sessions or iterations).

Recommended `.gitignore` entry:

```gitignore
.tav/
```

If `docs/memory/` is selected as the repository's memory surface, commit it with the repo — do **not** add it to `.gitignore`.

## Examples

- [examples/bug-fix.md](examples/bug-fix.md) - two-iteration loop where Verifier catches an incomplete fix.
- [examples/rate-limiting.md](examples/rate-limiting.md) - full L1 walkthrough including state file evolution.
- [examples/refactoring.md](examples/refactoring.md) - behavior-preserving extraction with plan-mismatch recovery.
- [examples/l0-quick-patch.md](examples/l0-quick-patch.md) - L0 lightweight single-pass flow with no state file.
- [examples/two-strike-escalation.md](examples/two-strike-escalation.md) - two-strike [ESCALATION-REPORT] with Verifier independence escalation.

## Documentation

- [SKILL.md](SKILL.md) - complete skill specification (single source of truth).
- [CHANGELOG.md](CHANGELOG.md) - version history.
- [Implementation Guide](references/implementation-guide.md) - operational guidance.
- [Verification Command Selection](references/verification-commands.md) - stack and IaC gate selection.
- [State Template](references/templates/state.json) - durable state schema.
- [Thinker Output](references/templates/thinker-output.md) / [Actor Output](references/templates/actor-output.md) / [Verifier Output](references/templates/verifier-output.md) - phase output formats.
- [CONTRIBUTING.md](CONTRIBUTING.md) - how to edit this skill and run the documentation self-check.

## License

MIT

---

**TAV Workflow v3.11.0**
*Think-Act-Verify: evidence-based change, minimal execution, verified completion.*
