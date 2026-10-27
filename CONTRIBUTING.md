# Contributing to TAV Workflow

This repository is a skill specification (documentation), not a runtime library. Changes are edits to `SKILL.md`, the READMEs, templates, examples, and the implementation guide.

The installable skill lives in `skills/tav-workflow/` (`SKILL.md`, `references/`, `examples/`); the paths below are relative to it. Repository files (`README*`, `CHANGELOG.md`, `CONTRIBUTING.md`, `LICENSE`, `scripts/`, `tests/`) stay at the root and are not installed.

## Before you commit

1. **Single source of truth for the version.** The `metadata.version` field in `SKILL.md` frontmatter is authoritative. Every other version mention — `README.md`, `README.zh-CN.md` (both the `**Version**`/`**版本**` line and the footer `**TAV Workflow vX.Y.Z**`), and `references/templates/state.json` — must match it. Bump the version in `SKILL.md` first, then run the self-check.
2. **Run the self-check.**
   ```bash
   pwsh scripts/verify.ps1
   ```
   It fails the build if any version drifts, any internal link or cited section is broken, or a `references/` or `examples/` file is missing from or unnamed in `SKILL.md`. Do not commit with a failing self-check.
   Before a release, also run `pwsh scripts/verify.ps1` in the sibling `spec-driven-develop` repository — its cross-repo checks verify the shared contract from both sides (escalation signals, delivery-batch write-back fingerprints, section citations). Both repositories also check the decision-note contract against a sibling `write-notes-like-deepseek` checkout. A wording change here can break the fingerprint there.
3. **Keep the READMEs aligned.** `README.md` and `README.zh-CN.md` describe the same skill. If you change the structure, links, or section set in one, mirror it in the other. The self-check verifies links and versions in both; structural parity is a human review responsibility.
4. **SKILL.md wins.** When `SKILL.md` and `references/implementation-guide.md` disagree, `SKILL.md` is authoritative — fix the guide, not the spec.

## Scope of changes

- Spec/semantics changes belong in `SKILL.md`; operational mechanics belong in `references/implementation-guide.md`.
- Output contracts live in `references/templates/`. Keep field names exactly as defined.
- Add a `CHANGELOG.md` entry for any user-visible change, under a new version heading.

## Examples

When adding an example, cover a boundary the existing five do not — L0 lightweight flow, two-strike escalation, plan-mismatch recovery, etc. Full L1 walkthroughs must demonstrate every section in the canonical Thinker, Actor, and Verifier templates, marking non-applicable fields explicitly. Focused protocol examples may show only the relevant excerpt but must say they are not full phase-output walkthroughs. L0 examples demonstrate the lightweight non-templated flow defined by `SKILL.md`.
