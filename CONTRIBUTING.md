# Contributing to TAV Workflow

This repository is a skill specification (documentation), not a runtime library. Changes are edits to `SKILL.md`, the READMEs, templates, examples, and the implementation guide.

## Before you commit

1. **Single source of truth for the version.** The `version:` field in `SKILL.md` frontmatter is authoritative. Every other version mention — `README.md`, `README.zh-CN.md` (both the `**Version**`/`**版本**` line and the footer `**TAV Workflow vX.Y.Z**`), and `references/templates/state.json` — must match it. Bump the version in `SKILL.md` first, then run the self-check.
2. **Run the self-check.**
   ```bash
   pwsh scripts/verify.ps1
   ```
   It fails the build if any version drifts or any internal link is broken. Do not commit with a failing self-check.
3. **Keep the READMEs aligned.** `README.md` and `README.zh-CN.md` describe the same skill. If you change the structure, links, or section set in one, mirror it in the other. The self-check verifies links and versions in both; structural parity is a human review responsibility.
4. **SKILL.md wins.** When `SKILL.md` and `references/implementation-guide.md` disagree, `SKILL.md` is authoritative — fix the guide, not the spec.

## Scope of changes

- Spec/semantics changes belong in `SKILL.md`; operational mechanics belong in `references/implementation-guide.md`.
- Output contracts live in `references/templates/`. Keep field names exactly as defined.
- Add a `CHANGELOG.md` entry for any user-visible change, under a new version heading.

## Examples

When adding an example, cover a boundary the existing three do not — L0 lightweight flow, PUA escalation, plan-mismatch recovery, etc. Examples must demonstrate the output contracts defined in the templates.
