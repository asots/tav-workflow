# Example: L0 Quick Patch

Demonstrates the lightweight single-pass TAV for an obvious, localized single-file change. No state file, no templated phase outputs — just evidence, edit, baseline check. L0 is the smallest workflow that is still safe.

## User Request

"The retry count in the HTTP client defaults to 0, so every transient error fails immediately. Set it to 3."

## Tier Decision

L0: a single constant in one file, no security or data surface, no behavior beyond the edited line. Risk: low. Per the L0 vs L1 boundary, none of the L1 triggers apply (no sensitive surface, no cross-file effect, no new test needed, diff well under ~30 lines).

## Thinker (inline, not templated)

L0 skips the full templated Thinker block, but evidence is still required:

- `src/http/client.ts:12` - `const RETRY = 0;` confirmed; the value is consumed only by the retry loop at `src/http/client.ts:40`.
- Plan: change `0` to `3` on line 12. Searched `RETRY` - no other call sites.
- Verification plan (candidate): `npm test` - the existing `tests/http/client.test.ts` asserts retry behavior.

## Actor

Single edit applied:

```typescript
// src/http/client.ts:12
const RETRY = 3;
```

## Verifier

- `git diff`: one one-line change, matches the plan exactly.
- `npm test`: PASS (12 passing). The retry test now exercises 3 attempts and still passes.
- No security-sensitive surface touched; no side effects on other call sites.

## Completion

Lightweight report (L0 uses the standard final-report shape, but no templated phase-output blocks and no `.tav/state.json`):

```markdown
## Summary
- Set the HTTP client default retry from 0 to 3 in `src/http/client.ts:12`.

## Files Changed
- `src/http/client.ts` (Modified): RETRY constant 0 -> 3.

## Verification
- ✅ `npm test` passed (12 passing)

## Failed or Skipped Commands
- None.

## Residual Risks
- None.

## Next Steps
- None.
```

No knowledge consolidation: the change is obvious and already recorded in the code. Zero captures is the default outcome, not a failure.

## Key Takeaways

1. **L0 skips ceremony.** No `.tav/state.json`, no full Thinker/Actor/Verifier templated blocks — evidence, edit, baseline check in one pass.
2. **Evidence is still required.** Even an obvious change cites the line and confirms the blast radius before editing.
3. **The baseline check is not optional.** A one-line change still runs the test suite; "obvious" does not mean "unverified".
