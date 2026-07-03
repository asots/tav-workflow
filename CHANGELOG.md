# TAV Workflow Changelog

## Version 3.1.0 (2026-07-03)

### Alignment Improvements

- **Changed**: Durable state schema now uses TAV-global snake_case fields:
  - `current_phase`
  - `todo_list`
  - `completed_steps`
  - `current_risk_level`
  - `verification_commands`
  - `failure_counts`
- **Changed**: Replaced fixed `TodoWrite` / `TodoUpdate` assumptions with platform-native task tracking guidance.
- **Changed**: Updated version references in `SKILL.md`, `README.md`, templates, and implementation guide.

### Workflow Improvements

- **Added**: L0/L1/L2 task tiering.
- **Added**: Clear `spec-driven-develop` escalation for migrations, rewrites, architecture overhauls, and broad transformations.
- **Added**: Actor read-boundary clarification: Actor may read target context required for editing but must not perform new exploration.
- **Added**: Stack-aware verification command selection for Node, Python, Rust, and Go projects.
- **Added**: Security-sensitive verification branch for auth, user input, database, filesystem, external API, crypto, payments, and secrets.
- **Added**: Two-failure `[PUA-REPORT]` escalation protocol.

### Documentation Improvements

- **Simplified**: Reduced pseudo-code that looked like directly executable platform API calls.
- **Clarified**: Role names are responsibilities, not hard dependencies on exact agent names.
- **Clarified**: Final report must include modified files, verification results, failed or skipped commands, residual risks, and next steps.
- **Clarified**: Cleanup and rollback must avoid destructive VCS operations and require explicit user approval for hard-to-reverse actions.

## Version 3.0.0 (2026-05-19)

### Major Features

#### 1. Automated Agent Orchestration

- **Added**: Agent-based execution for all three phases:
  - Thinker: planning/exploration role for analysis.
  - Actor: coding/execution role for changes.
  - Verifier: review/verification role for independent validation.
- **Benefit**: Workflow can be executed consistently instead of relying on informal manual interpretation.

#### 2. State Persistence

- **Added**: `.tav/state.json` for cross-conversation continuity.
- **Added**: State archiving to `.tav/archive/` on completion.
- **Added**: Continuity check at workflow start.
- **Benefit**: Interrupted workflows can resume without losing progress.

#### 3. Native Tool Integration

- **Added**: Native progress tracking guidance.
- **Added**: Optional platform-specific workflow progress integration.
- **Benefit**: Real-time progress visibility in supported environments.

#### 4. Quality Gates

- **Added**: Automated lint, type-check, and test execution after Actor phase.
- **Added**: Quality gate failure handling.
- **Benefit**: Errors are caught before final verification.

#### 5. Error Recovery Protocol

- **Added**: Structured error recovery with retry limits.
- **Added**: Recovery decision tree for different error types.
- **Added**: Automatic escalation when retry limits are exceeded.
- **Benefit**: Robust error handling without infinite loops.

#### 6. Performance Optimization

- **Added**: Token budget tracking per phase.
- **Added**: Efficiency rules for each role.
- **Added**: Performance metrics in state file.
- **Benefit**: Predictable token usage and faster execution.

#### 7. Complete Examples

- **Added**: `examples/rate-limiting.md` - API rate limiting implementation.
- **Added**: `examples/bug-fix.md` - Bug fix with iteration.
- **Added**: `examples/refactoring.md` - Local refactoring example.

#### 8. Skill Composition Patterns

- **Added**: Integration patterns with other skills:
  - Deep-Discuss -> TAV.
  - TAV -> Review.
  - Spec-Dev -> TAV.
  - TAV -> Smart-Commit.

### Documentation

#### New Files

- `references/implementation-guide.md` - Complete implementation guide.
- `references/templates/state.json` - State file template.
- `references/templates/thinker-output.md` - Thinker output template.
- `references/templates/actor-output.md` - Actor output template.
- `references/templates/verifier-output.md` - Verifier output template.
- `examples/rate-limiting.md` - Complete rate limiting example.
- `examples/bug-fix.md` - Bug fix with iteration example.
- `examples/refactoring.md` - Refactoring example.

#### Updated Files

- `SKILL.md` - Complete rewrite with automated workflow features.

### Notes

- v3.0.0 introduced the production version of the automated TAV workflow.
- v3.1.0 refines the workflow to better match current Claude Code tools and global TAV execution rules.

---

**License**: MIT
