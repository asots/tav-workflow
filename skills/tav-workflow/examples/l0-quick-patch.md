# Example: L0 Quick Patch

Demonstrates lightweight single-pass TAV for an obvious documentation typo. No state file or templated phase outputs are needed.

## User Request

"The CLI usage page spells `--output` as `--ouput`. Correct the typo."

## Tier Decision

L0: one display-text correction in one Markdown file. Evidence confirms the text is not generated, parsed, copied into runtime configuration, or used as a command example by automated tests. No sensitive surface, public contract, or cross-file runtime effect is involved.

## Thinker (inline, not templated)

- `docs/cli.md:18` contains `--ouput` in explanatory prose.
- `rg -n -- '--ouput' docs README.md` returns only that line.
- Plan: replace the misspelling and run the repository's Markdown/static check if configured, plus `git diff --check`.

## Actor

Changed `--ouput` to `--output` in `docs/cli.md:18`; no other text or formatting changed.

## Verifier

- `git diff -- docs/cli.md`: one word changed and matches the request.
- `rg -n -- '--ouput' docs README.md`: no matches.
- `git diff --check`: pass.
- No runtime, security, data, public-contract, or external-system behavior changed.

## Completion

```markdown
## Summary
- Corrected the `--output` spelling in `docs/cli.md`.

## Files Changed
- `docs/cli.md` (Modified): corrected one documentation typo.

## Verification
- ✅ `rg -n -- '--ouput' docs README.md` returned no matches.
- ✅ `git diff --check` passed.

## Failed or Skipped Commands
- Repository Markdown check not run: no configured command was found.

## Residual Risks
- None identified for the documentation-only change.

## Next Steps
- None.
```

No knowledge consolidation: the correction is obvious and already represented by the updated documentation.

## Key Takeaways

1. L0 is based on proven behavior and risk, not only line count.
2. A filename never overrides sensitive-surface rules.
3. Even a typo receives evidence, an exact diff review, and the cheapest available gate.
