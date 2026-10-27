# Example: L1 Cycle with OCR Delegate and a Decision Note

Demonstrates a standard L1 change where the Verifier uses
`open-code-review-delegate` for the Standards axis and Phase 4 records a
decision note through `write-notes-like-deepseek`. The change is a public HTTP
behavior change, so the note is required by that skill's red line rather than
by TAV's memory-capture signals.

## User Request

"Add a `Retry-After` header to the rate-limit response and cover it with a
test."

## Thinker (inline summary)

### Tier and evidence

- L1: the change alters a public HTTP contract, touches two files, and needs a
  new test.
- `src/http/rate-limit.ts:42` builds the 429 response and currently returns no
  retry hint.
- `src/http/__tests__/rate-limit.test.ts:18` already covers the 429 status but
  does not assert response headers.
- `package.json` exposes `npm test`, `npm run typecheck`, and `npm run lint`.

### Plan

1. Compute the retry delay from the existing limiter window.
2. Add `Retry-After` to the 429 response only; leave 200 responses unchanged.
3. Extend the existing rate-limit test to assert the header on 429 and its
   absence on 200.
4. Run the targeted test, typecheck, and `git diff --check`.

### Verification plan

- `npm test -- rate-limit`
- `npm run typecheck`
- `git diff --check`

## Actor

- `src/http/rate-limit.ts`: the 429 branch now sets `Retry-After` from the
  remaining window in seconds.
- `src/http/__tests__/rate-limit.test.ts`: added assertions for the 429 header
  and for the absence of the header on a successful response.
- No unrelated edits.

## Verifier

### Machine gates

- `npm test -- rate-limit` — PASS.
- `npm run typecheck` — PASS.
- `git diff --check` — PASS.

### Standards axis with OCR delegate

The repository has the `ocr` CLI on PATH, so the Standards axis uses delegation
mode rather than OCR's own LLM review path.

```bash
ocr --version
# open-code-review v1.13.3 ...
ocr delegate --help
# Delegation Mode ...
ocr delegate preview --format json
# reviewable_files: rate-limit.ts, rate-limit.test.ts
ocr delegate rule --format json src/http/rate-limit.ts src/http/__tests__/rate-limit.test.ts
# one rule group: HTTP response construction and test coverage
```

Both reviewable files were reviewed against the returned rule group. One medium
finding was raised: the new header value was computed with `Math.floor`, which
could advertise `Retry-After: 0` when the remaining window was under a second.
The Actor changed it to `Math.max(1, Math.ceil(...))` and the targeted test was
rerun. The second Standards pass found no further issues.

### Spec axis

- The 429 response now includes `Retry-After`; the acceptance criterion is met.
- The 200 response is unchanged; no unauthorized behavior was added.
- The test covers both the positive and negative case.
- No existing decision note or ADR contradicts the change.

## Phase 4: Decision Note and Report

### Why a note is required

The change modifies a public HTTP contract, so it is non-trivial under the
`write-notes-like-deepseek` red line. TAV's capture signals did not fire — there
was no non-obvious root cause, no new project command, and no user correction —
but that does not suppress the note.

### Note

Path: `.agents/notes/implemented/feature/2026-10-27-retry-after-header.md`

```markdown
# Agent Note: Retry-After header for rate-limited responses

Status: implemented

## Problem

Clients that receive a 429 response cannot tell when retrying is safe. They
either retry immediately or apply an arbitrary backoff.

## Decision

Rate-limited 429 responses include `Retry-After` in seconds. The value is the
remaining limiter window, with a minimum of one second. Successful responses do
not include the header.

## Alternatives considered

- **Return a JSON `retry_after_ms` field** — structured for API clients, but it
  adds a body contract and does not help generic HTTP clients. Rejected because
  `Retry-After` is the standard mechanism.
- **Return 429 without a retry hint** — simplest, but preserves the client
  thundering-herd problem. Rejected.

## Consequences

- **Benefit**: generic HTTP clients can honor the retry delay without parsing
  the body.
- **Cost and limits**: the header is advisory; clients that ignore it still
  retry immediately. Revisit if the limiter changes to a sliding window that
  cannot be expressed in whole seconds.

## Verification

`npm test -- rate-limit` asserts the header on 429 and its absence on 200.
```

### Note gate

Run from the host project root:

```bash
npx tsx <write-notes-skill-dir>/scripts/verify-agent-note-tree.ts
npx tsx <write-notes-skill-dir>/scripts/verify-agent-note-format.ts
npx tsx <write-notes-skill-dir>/scripts/verify-archived-agent-notes.ts
```

All three passed. If the host configures the composite script, `npm run
verify-notes` is equivalent.

### Final report

```markdown
## 变更摘要
- Added `Retry-After` to 429 responses and covered both 429 and 200 behavior.
- Adjusted the retry calculation to avoid `Retry-After: 0` after the Standards review.

## 涉及文件
- `src/http/rate-limit.ts` (Modified): set the retry hint on 429.
- `src/http/__tests__/rate-limit.test.ts` (Modified): added header assertions.
- `.agents/notes/implemented/feature/2026-10-27-retry-after-header.md` (Added): decision record.

## 验证结果
- `npm test -- rate-limit` passed.
- `npm run typecheck` passed.
- `git diff --check` passed.
- `verify-agent-note-tree`, `verify-agent-note-format`, `verify-archived-agent-notes` passed.

## 失败或未执行的命令
- None.

## 剩余风险
- The header is advisory; clients may ignore it.
- A future sliding-window limiter may need a finer-grained value.

## 后续建议
- Document the header in the API reference.
- Revisit if the limiter window becomes configurable per route.

## 知识沉淀
- `.agents/notes/implemented/feature/2026-10-27-retry-after-header.md` - decision captured: standard `Retry-After` over a body field.
```

## Key Takeaways

1. OCR delegation is not OCR's LLM review. The Verifier keeps judgment, the
   Spec axis, machine gates, and security review.
2. The decision note was required by the write-notes red line, not by TAV's
   memory-capture signals.
3. If a later change renames the header or changes its unit, update this note in
   place rather than creating a second note.
