#requires -Version 5.1
# TAV Workflow documentation self-check (structural invariants only).
# Verifies version consistency (single source = SKILL.md frontmatter), README link
# integrity, required-file existence, state.json validity, and the cross-repo
# spec-tav/v1 contract. Per-section text fingerprints were removed in 3.13.0.
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

# 1. SKILL.md frontmatter version is the single source of truth
$skill = Get-Content SKILL.md -Raw -Encoding UTF8
if ($skill -notmatch '(?m)^version:\s*(.+)$') { Fail 'SKILL.md frontmatter missing version'; $skillVer = '<none>' }
else { $skillVer = $Matches[1].Trim(); Ok "SKILL.md version = $skillVer (source of truth)" }

# 2. Every other version mention must match
# Non-ASCII pattern text is built from char codes so this script stays pure
# ASCII: Windows PowerShell 5.1 reads BOM-less scripts in the ANSI codepage and
# would otherwise mangle embedded CJK/em-dash literals under a GBK locale.
$zhVer = [string][char]0x7248 + [string][char]0x672C  # CJK word for "version"
$fwColon = [string][char]0xFF1A                        # fullwidth colon
$checks = @(
  @{ file='README.md';                      pat='\*\*Version\*\*:\s*(.+)'; label='**Version**' },
  @{ file='README.md';                      pat='\*\*TAV Workflow v(.+?)\*\*'; label='footer v' },
  @{ file='README.zh-CN.md';                pat="\*\*$zhVer\*\*$fwColon\s*(.+)"; label="**$zhVer**" },
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
foreach ($req in 'references/branches.md','references/templates/state.json','references/templates/thinker-output.md','references/templates/actor-output.md','references/templates/verifier-output.md','references/implementation-guide.md','references/verification-commands.md','CHANGELOG.md') {
  if (-not (Test-Path $req)) { Fail "missing referenced file: $req" }
}
if ($script:fail -eq $failsBefore) { Ok "referenced files exist" }

# 5. Cross-repo handoff contract with spec-driven-develop
$specSkillPath = Join-Path $SpecPath 'plugins/spec-driven-develop/skills/spec-driven-develop/SKILL.md'
if (-not (Test-Path $specSkillPath)) {
  Write-Host "WARN: spec-driven-develop not found at '$SpecPath' - cross-repo contract checks skipped (pass -SpecPath to enable)" -ForegroundColor Yellow
} else {
  $specSkill = Get-Content $specSkillPath -Raw -Encoding UTF8
  $em = [string][char]0x2014  # em dash, kept out of literals for ANSI-codepage safety
  $fallback = "A refactor confined to one module $em however messy $em stays at L1 (TAV territory)."
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
