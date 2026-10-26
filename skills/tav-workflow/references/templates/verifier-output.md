**[Verifier - Review]**
Phase 3 -> Reviewing

### Diff Reviewed

- `git diff` (or VCS equivalent) inspected first: summary of actual changes observed.

### Verification Items

| Check | Status | Evidence |
|-------|--------|----------|
| Syntax/type safety | pass/fail/warn | ... |
| Tests/lint | pass/fail/warn | ... |
| Compatibility | pass/fail/warn | ... |
| Edge cases | pass/fail/warn | ... |
| Security | pass/fail/warn | ... |
| Side effects | pass/fail/warn | ... |

### Standards Review

- Status: pass / fail / warn
- Repository-rule evidence or explicitly labeled heuristic finding: ...

### Spec Review

- Status: pass / fail / warn
- Acceptance evidence for missing/partial behavior, scope creep, or semantic mismatch: ...

### Hard-Bug Closure

<!-- Use when the hard-bug branch applies; otherwise write Not applicable. -->
- Minimized regression proof: `command` - result.
- Original feedback command: `command` - result.
- Diagnostic residue check: tag search plus proof that named probe paths match their pre-probe VCS baseline.

### Commands Run

- `command` - passed/failed, important output summary.

### Failed or Skipped Commands

- `command` - reason or failure summary.

### Issue Details

- `file:line` - issue description, or `None`.

### Suggested Fix

- Specific fix action, or `None`.

### Consolidation Candidates

- Candidate rule + supporting evidence, or `None`. (Evaluated in Phase 4 against the capture signals in `SKILL.md`.)

### Review Result

- Pass only when machine gates and both Standards/Spec axes permit completion; otherwise return to Actor/Thinker with exact reason.

### Change Summary

- Files modified: N (from `git diff --stat`)
- Lines changed: +X -Y (from `git diff --stat`)
- Scope: brief description
