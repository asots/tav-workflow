#requires -Version 5.1
# TAV Workflow documentation self-check.
# Verifies version consistency (single source = SKILL.md frontmatter), internal link
# integrity, and specialist-discipline section fingerprints.
# Run: pwsh scripts/verify.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$script:fail = 0

function Fail($msg) { Write-Host "FAIL: $msg" -ForegroundColor Red; $script:fail++ }
function Ok($msg)   { Write-Host "OK:   $msg" -ForegroundColor Green }

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
  elseif ($null -eq $state.phase_outputs.thinker.approved_plan -or $null -eq $state.phase_outputs.thinker.evidence_pointers -or $null -eq $state.phase_outputs.thinker.verification_plan -or $null -eq $state.phase_outputs.verifier.results) { Fail 'state template lacks compact recoverable plan, evidence, or verification fields' }
  else { Ok 'state template carries diagnosis, TDD, two-axis review, and compact resumable phase state' }
}

$eventTexts = @('SKILL.md','README.md','README.zh-CN.md','references/implementation-guide.md','examples/pua-escalation.md') | ForEach-Object { Get-Content $_ -Raw -Encoding UTF8 }
$eventText = $eventTexts -join "`n"
if ($eventText.Contains('[PUA-REPORT]')) { Fail 'current workflow surfaces still use the obsolete [PUA-REPORT] tag' }
elseif (-not $eventText.Contains('[ESCALATION-REPORT]')) { Fail 'current workflow surfaces do not define the [ESCALATION-REPORT] tag' }
else { Ok 'current workflow surfaces use the neutral escalation-event tag' }

if ($script:fail -gt 0) { Write-Host "`n$($script:fail) check(s) FAILED" -ForegroundColor Red; exit 1 }
Write-Host "`nAll checks passed" -ForegroundColor Green; exit 0
