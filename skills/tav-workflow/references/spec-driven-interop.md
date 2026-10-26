# Operating Inside a Spec-Driven Project

`SKILL.md` keeps the trigger and points here; this file owns the task-intake, completion write-back, and state-ownership rules.

When an active (non-tombstone) `docs/progress/MASTER.md` exists and the current task comes from a `spec-driven-develop` plan, one TAV cycle executes exactly one task card, while the enclosing delivery batch owns branches, integration validation, and the single batch PR. Spec Phases 0-6 and TAV Phases 0-4 are independent numbering systems. This is the execution half of the Handoff Contract defined in `spec-driven-develop` § "Boundary with TAV" — keep both sides in sync.

**Handoff contract ID**: `spec-tav/v1` (mirrors the canonical Spec-Driven contract).

**Task intake (Thinker):**

- Take the task definition from the pending GitHub Issue or phase-file entry, not from a re-interpretation of the original user request.
- Treat the task card's acceptance criteria and explicit test expectation as the baseline of the verification plan; add stack-appropriate gates on top.
- Treat the task card's S.U.P.E.R design drivers as additional Verifier check items.
- Treat the task card's relevant/affected files and dependencies as starting points for Thinker evidence gathering, not as permission to skip affected callers or checks.
- Treat the task card's delivery-batch ID, delivery shape, and rollback boundary as fixed execution constraints. If a LOCAL_ONLY entry lacks them, return the incomplete task-card evidence to the orchestrator instead of inferring them from the original user request.
- Treat the task card's memory/governance impact field as pre-declared candidates for Phase 4 knowledge consolidation.
- If `.tav/state.json` is created, populate `origin.spec_run_id`, `origin.task_card_id`, `origin.delivery_batch_id`, and `origin.rollback_boundary` from the active MASTER and task card; standalone TAV cycles leave these fields null.

**Completion write-back (after Verifier passes):**

- Return `ready for batch integration` — do not create a task-level PR or use closing keywords. In orchestrator-direct execution, the orchestrator updates the Current Status and, after integrated validation plus the required authorization, performs closure through the batch PR's `Closes #N` line (or the LOCAL_ONLY checkbox). In a lane or delegated assignment, do not edit `MASTER.md`, an Issue, or a phase file.
- Return one execution-event payload from observed TAV signals: Outcome, Rework, Plan returns, Unplanned dependencies, and Focused S.U.P.E.R result. Only the orchestrator records it once according to `spec-driven-develop` `references/adaptive-control.md`.
- Return knowledge-consolidation candidates for the orchestrator to reconcile against "Governance Status" in MASTER.md. A lane or delegated TAV cycle never writes resolved memory or instruction surfaces directly.
- On `[ESCALATION-REPORT]` or a blocked state, return the event before pausing. Only the orchestrator records it in an authorized Issue comment or phase file and selects watch, replan, or rescope.

**State ownership:**

- `docs/progress/MASTER.md` is the project-level lightweight status authority.
- GitHub Issues (GitHub modes) or phase-file task entries (LOCAL_ONLY) are the authoritative task-event records.
- `.tav/state.json` is scoped to one task: it is created only when that single task needs cross-session recovery, it is archived or deleted with explicit cleanup authorization when the task completes, and it never carries project-level progress.
