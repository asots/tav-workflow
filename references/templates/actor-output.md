**[Actor - Execution]**
Phase 2 -> Executing

### Progress
1. Completed `file/path` - change made.
2. Completed `file/path` - change made.
3. Completed `file/path` - change made.

### Completed Steps
- Todo ID: summary of edit/write and affected file.

### Diagnostic Probe Evidence
<!-- Use only for a diagnostic Actor micro-step; otherwise write Not applicable. -->
- Prediction and unique tag: ...
- Feedback command/result: `command` - observed signal.
- Cleanup check: `command` - passed/failed.
- Probe-path baseline restoration: matched / exact remaining diagnostic delta (remaining residue blocks continuation; preserve unrelated pre-existing changes).

### TDD Evidence
<!-- Use when test-first execution applies; otherwise write Not applicable. -->
| Slice | RED Command / Result | GREEN Command / Result |
|:------|:---------------------|:-----------------------|
| Observable behavior | `command` - expected failure | `command` - pass |

### Blocked Items
- None, or exact blocker with evidence.

### Notes
- Any required deviation from the Thinker plan. If there is a deviation, stop and return to Thinker.

-> A diagnostic probe always returns to Phase 1 after cleanup. Normal implementation enters Phase 3, or returns to Phase 1 if the plan is incomplete.
