# TAV Specialist Branches

This file owns the full contracts and recording rules for the low-frequency specialist branches. `SKILL.md` keeps only the compact triggers and points here, so these details are loaded only when a branch actually fires. The `.tav/state.json` lifecycle and failure keys live in `references/implementation-guide.md`; the phase-output fields live in `references/templates/`.

## Hard-bug diagnosis branch

Use this branch when the failure resists an obvious first-pass explanation, is intermittent, is a performance regression, or the user explicitly asks for diagnosis/debugging. Ordinary scoped fixes keep the standard Thinker flow.

1. **Establish the feedback loop before theorizing.** Identify and run one existing command, script, trace replay, or debugger/REPL path that exercises the user's exact symptom. It must be red-capable, deterministic (or have a measured high reproduction rate for a flaky bug), as fast as practical, agent-runnable, and confined to local, test, or explicitly authorized sandbox state. Never use a production mutation, external message, payment, deployment, or resource creation as a diagnostic feedback loop. If a new harness or source instrumentation is required, design it here and use the diagnostic Actor micro-loop below instead of editing during Thinker.
2. **Reproduce and minimize.** Confirm the loop catches the reported failure, then remove inputs, callers, configuration, data, and steps one at a time until every remaining element is load-bearing.
3. **Rank falsifiable hypotheses.** Write 3-5 candidate causes before testing them. Each hypothesis states a prediction that one targeted probe can confirm or falsify. Share the ranking as a non-blocking checkpoint when user domain knowledge could materially reorder it.
4. **Probe one variable at a time.** Prefer read-only debugger/REPL inspection. When a file edit is required, specify one falsifying prediction, the exact probe files, a unique removable tag, and a cleanup check for the diagnostic Actor. Performance work starts from a measured baseline, profiler/query plan, or bisection signal rather than broad logging.
5. **Plan the regression proof at the correct seam.** The test must exercise the real bug pattern through a stable public boundary. If no correct seam exists, record that architecture limitation instead of adding a shallow test that cannot catch the original failure.
6. **Close the loop.** After diagnosis returns to normal TAV, the Actor applies the minimal fix; the Verifier reruns both the minimized regression proof and the original feedback command, and confirms all temporary instrumentation or harnesses are removed.

Recording:

- Store the feedback command and its first observed result in the Thinker evidence, the verification plan, and `diagnosis.feedback_command`, so the Verifier reruns the identical signal.
- Treat a flaky reproduction rate as measured evidence: record the loop count and observed failures before and after tightening rather than describing it as "sometimes".
- Minimize one dimension at a time and rerun after each reduction; the minimized case becomes the regression-test input when a correct seam exists.
- For performance work, record the baseline metric and measurement command before proposing a fix.

### Diagnostic Actor micro-loop

This micro-loop preserves the Thinker read-only boundary when diagnosis needs temporary file changes:

1. Thinker records the probe's prediction, exact files, command, unique tag, and cleanup check. The probe must be disposable and narrower than the eventual fix.
2. A diagnostic Actor captures the pre-probe VCS status/diff for the named paths (including whether a path was untracked or absent), applies only that probe, runs the named feedback command, captures the observed result, removes every probe edit, and proves those paths match the pre-probe baseline with the unique tag absent.
3. Control returns to Thinker, which updates the hypothesis ranking from the observed signal. Repeat only for a materially different prediction.

The diagnostic Actor does not implement the fix or retain a regression test. Persistent tests and product changes belong to the normal Actor after the Thinker plan is complete. If baseline restoration cannot be proven, stop and report the residual diagnostic delta without touching pre-existing user changes.

If no usable feedback loop can be built, stop speculative diagnosis. Report the attempts and exact limitation, then request the missing environment access, captured artifact, or permission for temporary instrumentation.

## Design-prototype branch

Use this branch when a plan decision hinges on how a state model, interaction, or interface should behave and repository evidence cannot settle it — the question is "does this design feel right?", not "why does this fail?". Build a throwaway prototype that answers that single question: an interactive terminal harness for state/logic questions, or switchable UI variations for interface questions. Use the `prototype` skill when the platform provides it.

The prototype follows the diagnostic-probe discipline: explicitly marked as throwaway, no tests or polish, never part of the final diff, and removed once the question is answered (retain it only on explicit user request, outside the delivered change). Record the question, the run command, and the validated decision in the Thinker output; only the decision enters the todo list, and the Verifier confirms no prototype code remains in the delivered change.

## TDD execution branch

Use test-driven execution when the Thinker plan requires new or strengthened automated tests, when the hard-bug branch produced a regression proof, or when the user explicitly requests test-first work.

- The Thinker names the **test seam**: the highest stable public boundary that can prove the required behavior. Prefer an existing seam. Ask the user only when competing seams materially change scope, architecture, or cost; otherwise choose from repository evidence and record the decision.
- Work in one vertical behavior slice at a time: write one test for externally observable behavior, run it red, add only enough implementation to make it green, then repeat.
- Expected values must come from an independent source of truth such as the confirmed requirement, a worked example, or known-good literal — never recompute the implementation inside the assertion.
- Avoid implementation-coupled mocks/private-method tests and horizontal "all tests first, all implementation later" batches.
- Refactor only after the slice is green and only when the refactor is already within the approved todo list; an unplanned structural need returns to Thinker.
- Record the red and green command evidence in progress so the Verifier can rerun it independently. Keep that record compact: test/seam, red command result, minimal implementation, green command result.
- A slice proves one externally visible capability; do not batch unrelated cases merely because they share a file.
- Mocks are acceptable at true external boundaries; do not mock the internal collaboration whose behavior the test is supposed to prove.
- If a test passes before implementation, stop: the behavior already exists, the assertion is insensitive, or the wrong seam was selected. Return to Thinker when the task definition must change.
