**[Thinker - Analysis]**
Phase 1 -> Analyzing

### Task Classification
- Tier: L0 / L1 / L2
- Risk level: low / medium / high / critical
- Escalation: use `spec-driven-develop` first? yes / no

### Evidence Gathered
- `path/to/file:line-range` - finding
- Search or command evidence - finding
- Related dependencies or affected modules - finding

### Analysis Summary
- Root cause or implementation approach in 2-3 concise sentences.

### Hard-Bug Evidence
<!-- Use when the hard-bug branch applies; otherwise write Not applicable. -->
- Feedback command: `command`
- First observed result / reproduction rate: exact compact evidence.
- Ranked hypotheses:
  1. Cause — falsifiable prediction.
  2. Cause — falsifiable prediction.
- Diagnostic probe: not needed / planned / completed and removed.
  - Prediction, exact files, unique tag, feedback command, pre-probe baseline, cleanup check, observed signal.

### Test Seam
- Highest stable public boundary that proves the behavior, or explicit reason no correct seam exists.

### Todo List
1. `file/path` - specific action, expected outcome, risk level.
2. `file/path` - specific action, expected outcome, risk level.
3. `file/path` - specific action, expected outcome, risk level.

### Risks
- Regression, compatibility, security, or operational risks.

### Verification Plan
- Candidate `command` - why this validates the change. (Verifier confirms each still matches the project stack and may add stack-appropriate checks Thinker missed.)
- Original feedback command and minimized regression proof for hard bugs.
- Skipped or unavailable checks - reason.

-> Enter Phase 2: Actor, or stop for clarification/escalation.
