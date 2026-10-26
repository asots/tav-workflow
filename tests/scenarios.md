# TAV Regression Scenarios

Fixed situations with the outcome the current rules require. When you change tiering, escalation, authority, continuity, or interop rules, walk every row against the changed text. A row whose expected outcome no longer follows from its cited rule is either a regression or a deliberate change; a deliberate change updates this table in the same commit.

Rule cells cite a file under `skills/tav-workflow/` and a heading in it. `scripts/verify.ps1` checks that every cited heading still exists; whether the outcome still follows is a human review step.

| # | Situation | Expected outcome | Rule |
|---|-----------|------------------|------|
| 1 | Fix a typo in a README heading; no code, config, or contract changes. | L0: cite evidence, edit, run a baseline check; no state file and no templated phase outputs. | `SKILL.md` § "L0 vs L1 boundary" |
| 2 | One-line change to the input-validation regex in a login handler. | L1 despite the size: the change touches a security-sensitive surface. | `SKILL.md` § "L0 vs L1 boundary" |
| 3 | Refactor one messy module across 6 files; no public API change. | L1: only one escalation signal can hold, and L2 needs at least two. | `SKILL.md` § "L2 Escalation Signals" |
| 4 | Migrate authentication across 4 modules, breaking the session API, over several sessions. | L2: run `spec-driven-develop` first, then one TAV cycle per task card. | `SKILL.md` § "L2 Escalation Signals" |
| 5 | The request says "refactor the whole project", but evidence shows one module is affected. | Stays L1: a rewrite or refactor keyword alone does not escalate. | `SKILL.md` § "L2 Escalation Signals" |
| 6 | `tsc` fails twice in a row with TS2532, on different lines of the same file. | Same normalized key (`TS2532`); the second failure emits `[ESCALATION-REPORT]`, requires an independent Verifier when available, and returns to Thinker. | `references/escalation.md` § "Failure counting semantics" |
| 7 | A new test fails during the TDD RED step. | Expected RED: it does not increment the failure counter. | `references/escalation.md` § "Failure counting semantics" |
| 8 | The fix is verified; the user never asked for a commit. | No branch, commit, push, or PR; report the result instead. | `SKILL.md` § "Authority and External-State Contract" |
| 9 | TAV runs as a lane inside an active spec-driven plan, and the Verifier passes. | Return `ready for batch integration` plus one execution-event payload; do not edit `MASTER.md`, Issues, or phase files. | `references/spec-driven-interop.md` § "Operating Inside a Spec-Driven Project" |
| 10 | `docs/progress/MASTER.md` carries `**Workflow State**: archived` and `Pending Operations` is `none`. | Archived tombstone: do not enter spec-driven task mode. | `SKILL.md` § "Phase 0: Continuity Check" |
| 11 | `.tav/state.json` for the same task was last updated 10 days ago. | Stale state: ask the user before resuming or replacing it. | `SKILL.md` § "Phase 0: Continuity Check" |
| 12 | A rejected decision note covers the approach the plan is about to propose. | Do not re-propose it without new evidence; surface the conflict. | `SKILL.md` § "Evidence rules" |
| 13 | The cycle produced a decision worth recording, and `write-notes-like-deepseek` is not installed. | List it as a final-report candidate; do not hand-write a note. | `SKILL.md` § "Knowledge consolidation" |
| 14 | An intermittent failure with no obvious cause. | Hard-bug branch: build a red-capable feedback loop before theorizing. | `references/branches.md` § "Hard-bug diagnosis branch" |
| 15 | Diagnosis needs temporary instrumentation in a source file. | Diagnostic Actor micro-loop: apply the probe, run it, remove it, and prove the baseline is restored; the Thinker stays read-only. | `references/branches.md` § "Diagnostic Actor micro-loop" |
