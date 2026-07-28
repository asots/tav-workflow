#requires -Version 5.1
# TAV Workflow documentation self-check.
# Verifies version consistency (single source = SKILL.md frontmatter), internal link
# integrity, specialist-discipline/example fingerprints, and the shared Spec/TAV contract.
# Run: pwsh scripts/verify.ps1 [-SpecPath <path-to-spec-driven-develop-repo>]

param(
  [string]$SpecPath = ''
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
if ($SpecPath -eq '') { $SpecPath = Join-Path (Split-Path -Parent $root) 'spec-driven-develop' }
$script:fail = 0

function Fail($msg) { Write-Host "FAIL: $msg" -ForegroundColor Red; $script:fail++ }
function Ok($msg)   { Write-Host "OK:   $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "WARN: $msg" -ForegroundColor Yellow }

function Get-RoleBlocks([string]$text, [string]$role) {
  $pattern = '(?ms)```markdown\s+\*\*\[' + [regex]::Escape($role) + '[^\n]*\n.*?```'
  @([regex]::Matches($text, $pattern) | ForEach-Object { $_.Value })
}

# 1. SKILL.md frontmatter version is the single source of truth
$skill = Get-Content SKILL.md -Raw -Encoding UTF8
if ($skill -notmatch '(?m)^version:\s*(.+)$') { Fail 'SKILL.md frontmatter missing version'; $skillVer = '<none>' }
else { $skillVer = $Matches[1].Trim(); Ok "SKILL.md version = $skillVer (source of truth)" }

# 2. Every other version mention must match
$checks = @(
  @{ file='README.md';                      pat='\*\*Version\*\*:\s*(.+)'; label='**Version**' },
  @{ file='README.md';                      pat='\*\*TAV Workflow v(.+?)\*\*'; label='footer v' },
  @{ file='README.zh-CN.md';                pat='\*\*版本\*\*：\s*(.+)'; label='**版本**' },
  @{ file='README.zh-CN.md';                pat='\*\*TAV Workflow v(.+?)\*\*'; label='footer v' },
  @{ file='references/templates/state.json';pat='"version":\s*"(.+)"'; label='version field' }
)
foreach ($c in $checks) {
  $t = Get-Content $c.file -Raw -Encoding UTF8
  if ($t -match $c.pat) {
    $v = $Matches[1].Trim()
    if ($v -ne $skillVer) { Fail "$($c.file) $($c.label) = '$v' != SKILL.md '$skillVer'" }
    else { Ok "$($c.file) $($c.label) = $v" }
  } else { Fail "$($c.file) $($c.label) line not found" }
}

$changelog = Get-Content 'CHANGELOG.md' -Raw -Encoding UTF8
if ($changelog -notmatch ('(?m)^## Version ' + [regex]::Escape($skillVer) + ' \(')) {
  Fail "CHANGELOG.md has no entry for current version $skillVer"
} else { Ok "CHANGELOG.md records current version $skillVer" }

$stateText = Get-Content 'references/templates/state.json' -Raw -Encoding UTF8
try {
  $state = $stateText | ConvertFrom-Json
  Ok 'references/templates/state.json is valid JSON'
} catch {
  Fail "references/templates/state.json is invalid JSON: $($_.Exception.Message)"
  $state = $null
}

# 2b. Example snippets that embed state JSON must not drift from the skill version
foreach ($example in Get-ChildItem examples -Filter '*.md') {
  $t = Get-Content $example.FullName -Raw -Encoding UTF8
  foreach ($m in [regex]::Matches($t, '"version"\s*:\s*"([^"]+)"')) {
    $v = $m.Groups[1].Value.Trim()
    if ($v -ne $skillVer) { Fail "$($example.FullName) embedded version = '$v' != SKILL.md '$skillVer'" }
    else { Ok "$($example.Name) embedded version = $v" }
  }
}

# 3. README relative links resolve to existing files
foreach ($r in 'README.md','README.zh-CN.md') {
  $failsBefore = $script:fail
  $t = Get-Content $r -Raw -Encoding UTF8
  foreach ($m in [regex]::Matches($t, '\]\(([^)]+)\)')) {
    $target = $m.Groups[1].Value
    if ($target -match '^https?://') { continue }
    if ($target -match '^#') { continue }
    $p = Join-Path $root ($target -replace '#.*$','')
    if (-not (Test-Path $p)) { Fail "$r -> $target (missing)" }
  }
  if ($script:fail -eq $failsBefore) { Ok "$r internal links resolved" }
}

# 4. Files referenced from SKILL.md exist
$failsBefore = $script:fail
foreach ($req in 'references/templates/state.json','references/templates/thinker-output.md','references/templates/actor-output.md','references/templates/verifier-output.md','references/implementation-guide.md','references/verification-commands.md','CHANGELOG.md') {
  if (-not (Test-Path $req)) { Fail "missing referenced file: $req" }
}
if ($script:fail -eq $failsBefore) { Ok "referenced files exist" }

# 5. Specialist discipline contracts must remain present in their canonical surfaces
$semanticChecks = @(
  @{ file='SKILL.md'; pat='(?m)^### Hard-bug diagnosis branch\s*$'; label='hard-bug diagnosis branch' },
  @{ file='SKILL.md'; pat='(?m)^#### Diagnostic Actor micro-loop\s*$'; label='diagnostic Actor micro-loop' },
  @{ file='SKILL.md'; pat='(?m)^### TDD execution branch\s*$'; label='TDD execution branch' },
  @{ file='SKILL.md'; pat='(?m)^### Two-axis review\s*$'; label='two-axis review' },
  @{ file='references/implementation-guide.md'; pat='(?m)^#### Hard-bug diagnostic mechanics\s*$'; label='hard-bug mechanics' },
  @{ file='references/implementation-guide.md'; pat='(?m)^#### Test-driven slice mechanics\s*$'; label='TDD mechanics' },
  @{ file='references/implementation-guide.md'; pat='(?m)^#### Two-axis review mechanics\s*$'; label='two-axis mechanics' },
  @{ file='references/templates/thinker-output.md'; pat='(?m)^### Hard-Bug Evidence\s*$'; label='Thinker hard-bug evidence fields' },
  @{ file='references/templates/thinker-output.md'; pat='(?m)^### Test Seam\s*$'; label='Thinker test seam field' },
  @{ file='references/templates/actor-output.md'; pat='(?m)^### Diagnostic Probe Evidence\s*$'; label='Actor diagnostic probe evidence' },
  @{ file='references/templates/actor-output.md'; pat='(?m)^### TDD Evidence\s*$'; label='Actor RED/GREEN evidence' },
  @{ file='references/templates/verifier-output.md'; pat='(?m)^### Standards Review\s*$'; label='Verifier Standards axis' },
  @{ file='references/templates/verifier-output.md'; pat='(?m)^### Spec Review\s*$'; label='Verifier Spec axis' },
  @{ file='references/templates/verifier-output.md'; pat='(?m)^### Hard-Bug Closure\s*$'; label='Verifier hard-bug closure evidence' },
  @{ file='README.md'; pat='Hard-bug diagnosis'; label='English README discipline summary' },
  @{ file='README.zh-CN.md'; pat='困难故障诊断'; label='Chinese README discipline summary' }
)
foreach ($c in $semanticChecks) {
  $t = Get-Content $c.file -Raw -Encoding UTF8
  if ($t -match $c.pat) { Ok "$($c.file) carries $($c.label)" }
  else { Fail "$($c.file) missing $($c.label)" }
}

if ($skill -notlike '*Thinker is read-only*' -or $skill -notlike '*pre-probe VCS status/diff*' -or $skill -notlike '*without touching pre-existing user changes*') {
  Fail 'SKILL.md does not preserve the read-only Thinker -> disposable diagnostic Actor -> Thinker loop'
} else { Ok 'SKILL.md preserves the diagnostic probe boundary and cleanup proof' }

if ($null -ne $state) {
  $missingStateFields = @()
  foreach ($field in 'diagnosis', 'tdd', 'review_axes') {
    if ($null -eq $state.PSObject.Properties[$field]) { $missingStateFields += $field }
  }
  if ($missingStateFields.Count -gt 0) { Fail "state template missing recovery fields: $($missingStateFields -join ', ')" }
  elseif ($null -eq $state.review_axes.standards -or $null -eq $state.review_axes.spec) { Fail 'state template does not keep Standards and Spec review axes separate' }
  elseif ($state.metrics.iterations -ne 0) { Fail 'state template metrics.iterations must start at 0 before an Actor-Verifier loop runs' }
  elseif ($null -eq $state.phase_outputs.thinker.approved_plan -or $null -eq $state.phase_outputs.thinker.evidence_pointers -or $null -eq $state.phase_outputs.thinker.verification_plan -or $null -eq $state.phase_outputs.verifier.results) { Fail 'state template lacks compact recoverable plan, evidence, or verification fields' }
  else { Ok 'state template carries diagnosis, TDD, two-axis review, and compact resumable phase state' }
}

$eventTexts = @('SKILL.md','README.md','README.zh-CN.md','references/implementation-guide.md','examples/two-strike-escalation.md') | ForEach-Object { Get-Content $_ -Raw -Encoding UTF8 }
$eventText = $eventTexts -join "`n"
if ($eventText.Contains('[PUA-REPORT]')) { Fail 'current workflow surfaces still use the obsolete [PUA-REPORT] tag' }
elseif (-not $eventText.Contains('[ESCALATION-REPORT]')) { Fail 'current workflow surfaces do not define the [ESCALATION-REPORT] tag' }
else { Ok 'current workflow surfaces use the neutral escalation-event tag' }

if ($skill -notlike '*## Authority and External-State Contract*' -or $skill -notlike '*cleanup_status: awaiting_authorization*') {
  Fail 'SKILL.md lacks the standalone authority and deferred-cleanup contract'
} else { Ok 'SKILL.md carries independent authority gates and deferred cleanup' }

if ($skill -notlike '*expected TDD RED results*' -or $skill -notlike '*pre-change baseline failures*' -or $skill -notlike '*Risk escalation is independent from rework counting*') {
  Fail 'SKILL.md does not separate expected failures, risk, and two-strike escalation'
} else { Ok 'two-strike counting excludes expected failures and stays independent from risk' }

if ($null -ne $state) {
  $missingOriginFields = @()
  if ($null -eq $state.origin) {
    $missingOriginFields = @('origin')
  } else {
    foreach ($field in 'spec_run_id', 'task_card_id', 'delivery_batch_id', 'rollback_boundary') {
      if ($null -eq $state.origin.PSObject.Properties[$field]) { $missingOriginFields += $field }
    }
  }
  if ($missingOriginFields.Count -gt 0) {
    Fail 'state template lacks spec-driven origin fields'
  } elseif ($state.cleanup_status -ne 'not_requested') {
    Fail 'state template cleanup_status must start at not_requested'
  } else { Ok 'state template carries spec-driven origin and cleanup status' }
}

$implementationGuide = Get-Content 'references/implementation-guide.md' -Raw -Encoding UTF8
if (-not $implementationGuide.Contains('explicitly authorized cleanup')) {
  Fail 'implementation guide lacks explicit cleanup authorization'
} elseif (-not $implementationGuide.Contains('pnpm typecheck:TS2532') -or -not $implementationGuide.Contains('Never prefix a `by_command` key with a todo ID')) {
  Fail 'implementation guide lacks the failure-count entry schema or command-key boundary'
} else { Ok 'implementation guide carries cleanup authority and failure-count entry semantics' }

$walkthroughSchemas = @{
  'Thinker - Analysis' = @('Task Classification','Evidence Gathered','Analysis Summary','Hard-Bug Evidence','Test Seam','Todo List','Risks','Verification Plan')
  'Actor - Execution' = @('Progress','Completed Steps','Diagnostic Probe Evidence','TDD Evidence','Blocked Items','Notes')
  'Verifier - Review' = @('Diff Reviewed','Verification Items','Standards Review','Spec Review','Hard-Bug Closure','Commands Run','Failed or Skipped Commands','Issue Details','Suggested Fix','Consolidation Candidates','Review Result','Change Summary')
}
$failsBefore = $script:fail
foreach ($file in 'examples/bug-fix.md','examples/refactoring.md','examples/rate-limiting.md') {
  $text = Get-Content $file -Raw -Encoding UTF8
  foreach ($role in $walkthroughSchemas.Keys) {
    $blocks = @(Get-RoleBlocks $text $role)
    if ($blocks.Count -eq 0) {
      Fail "$file has no canonical $role block"
      continue
    }
    for ($i = 0; $i -lt $blocks.Count; $i++) {
      foreach ($heading in $walkthroughSchemas[$role]) {
        if ($blocks[$i] -notmatch ('(?m)^### ' + [regex]::Escape($heading) + '\s*$')) {
          Fail "$file $role block $($i + 1) missing heading '$heading'"
        }
      }
    }
  }
}
if ($script:fail -eq $failsBefore) { Ok 'full L1 walkthroughs carry canonical Thinker/Actor/Verifier sections' }

$rateExample = Get-Content 'examples/rate-limiting.md' -Raw -Encoding UTF8
if ($rateExample -notlike '*after explicit cleanup authorization*' -or $rateExample -notlike '*cleanup_status: awaiting_authorization*') {
  Fail 'rate-limiting example lacks deferred-cleanup authorization semantics'
} else { Ok 'rate-limiting example preserves state without cleanup authorization' }

$strikeExample = Get-Content 'examples/two-strike-escalation.md' -Raw -Encoding UTF8
if ($strikeExample -like '*todo-2:pnpm typecheck:TS2532*') {
  Fail 'two-strike example still prefixes a by_command key with todo_id'
} elseif ($strikeExample -notlike '*pnpm typecheck:TS2532*') {
  Fail 'two-strike example lacks the canonical command blocker key'
} else { Ok 'two-strike example uses command + normalized signature only' }

$failsBefore = $script:fail
foreach ($file in Get-ChildItem examples -Filter '*.md') {
  $text = Get-Content $file.FullName -Raw -Encoding UTF8
  if ($text -match '(?m)^## 变更摘要\s*$') { Fail "$($file.Name) uses Chinese final headings for an English user request" }
  elseif ($text -notmatch '(?m)^## Summary\s*$') { Fail "$($file.Name) lacks the English Summary heading" }
}
if ($script:fail -eq $failsBefore) { Ok 'example final-report headings follow the English working language' }

$l0 = Get-Content 'examples/l0-quick-patch.md' -Raw -Encoding UTF8
if ($l0 -match 'HTTP client|external API|RETRY') { Fail 'L0 example still changes runtime or external-API behavior' }
elseif ($l0 -notmatch 'documentation typo' -or $l0 -notmatch 'git diff --check') { Fail 'L0 example does not demonstrate a verified non-runtime patch' }
else { Ok 'L0 example is a verified documentation-only patch' }

$exampleText = @('examples/bug-fix.md','examples/refactoring.md','examples/two-strike-escalation.md') | ForEach-Object { Get-Content $_ -Raw -Encoding UTF8 } | Out-String
if ($exampleText -match '(?m)^type:\s+project\s*$') { Fail 'examples use a memory type outside fact|rule|decision|gotcha' }
elseif ($exampleText -notmatch 'Failed or Skipped Commands') { Fail 'examples do not demonstrate the required final-report command section' }
else { Ok 'examples use canonical memory types and final-report command sections' }

if ($changelog -notlike '*examples/pua-escalation.md*' -or $changelog -notlike '*examples/two-strike-escalation.md*' -or $changelog -notlike '*historical 3.6.0 entry remains unchanged*') {
  Fail 'CHANGELOG.md does not document the pua-escalation -> two-strike-escalation rename without rewriting history'
} else { Ok 'CHANGELOG.md documents the current example name while preserving historical release text' }

# 6. Cross-repo handoff contract with spec-driven-develop
$specSkillPath = Join-Path $SpecPath 'plugins/spec-driven-develop/skills/spec-driven-develop/SKILL.md'
if (-not (Test-Path $specSkillPath)) {
  Warn "spec-driven-develop not found at '$SpecPath' - cross-repo contract checks skipped (pass -SpecPath to enable)"
} else {
  $specSkill = Get-Content $specSkillPath -Raw -Encoding UTF8
  $fallback = 'A refactor confined to one module — however messy — stays at L1 (TAV territory).'
  if ($skill -notlike "*$fallback*" -or $specSkill -notlike "*$fallback*") {
    Fail 'L2 fallback sentence is not verbatim-identical across repos'
  } else { Ok 'L2 fallback sentence is verbatim-identical across repos' }

  $canonicalPayload = 'Outcome, Rework, Plan returns, Unplanned dependencies, and Focused S.U.P.E.R result'
  if ($skill -notlike "*$canonicalPayload*" -or $specSkill -notlike "*$canonicalPayload*") {
    Fail 'execution-event payload is not canonical on both sides of the handoff'
  } else { Ok 'execution-event payload is canonical on both sides of the handoff' }

  $statePattern = '(?ms)\*\*State ownership:\*\*\s*(.*?)(?:\n---|\z)'
  $tavStateMatch = [regex]::Match($skill, $statePattern)
  $specStateMatch = [regex]::Match($specSkill, $statePattern)
  if (-not $tavStateMatch.Success -or -not $specStateMatch.Success) {
    Fail 'state ownership block missing from one side of the handoff'
  } else {
    $tavState = ($tavStateMatch.Groups[1].Value -replace "`r", '').Trim()
    $specState = ($specStateMatch.Groups[1].Value -replace "`r", '').Trim()
    if ($tavState -ne $specState) { Fail 'state ownership block differs across repos' }
    else { Ok 'three-layer state ownership block is mirrored across repos' }
  }
}

if ($script:fail -gt 0) { Write-Host "`n$($script:fail) check(s) FAILED" -ForegroundColor Red; exit 1 }
Write-Host "`nAll checks passed" -ForegroundColor Green; exit 0
