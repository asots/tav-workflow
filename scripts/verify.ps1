#requires -Version 5.1
# TAV Workflow documentation self-check (structural invariants only).
# Verifies version consistency (single source = SKILL.md frontmatter), README link
# integrity, required-file existence, state.json validity, regression-scenario citations,
# and the cross-repo spec-tav/v1 contract. The skill lives in skills/tav-workflow/.
# Run: pwsh scripts/verify.ps1 [-SpecPath <path-to-spec-driven-develop-repo>]

param(
  [string]$SpecPath = ''
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
if ($SpecPath -eq '') { $SpecPath = Join-Path (Split-Path -Parent $root) 'spec-driven-develop' }
$skillDir = Join-Path $root 'skills/tav-workflow'
$script:fail = 0

function Fail($msg) { Write-Host "FAIL: $msg" -ForegroundColor Red; $script:fail++ }
function Ok($msg)   { Write-Host "OK:   $msg" -ForegroundColor Green }
function Read-Text([string]$path) { Get-Content $path -Raw -Encoding UTF8 }

# 1. SKILL.md frontmatter metadata.version is the single source of truth
$skill = Read-Text (Join-Path $skillDir 'SKILL.md')
$frontmatter = if ($skill -match '(?s)^---\r?\n(.*?)\r?\n---') { $Matches[1] } else { '' }
$verMatch = [regex]::Match($frontmatter, '(?m)^metadata:[ \t]*\r?\n(?:[ \t]+.*\r?\n)*?[ \t]+version:[ \t]*(\S+)')
if (-not $verMatch.Success) { Fail 'SKILL.md frontmatter missing metadata.version'; $skillVer = '<none>' }
else { $skillVer = $verMatch.Groups[1].Value.Trim(); Ok "SKILL.md metadata.version = $skillVer (source of truth)" }
if ($frontmatter -match '(?m)^version:') { Fail 'SKILL.md frontmatter has a top-level version field; keep it in metadata.version' }

# 2. Every other version mention must match
# Non-ASCII pattern text is built from char codes so this script stays pure
# ASCII: Windows PowerShell 5.1 reads BOM-less scripts in the ANSI codepage and
# would otherwise mangle embedded CJK/em-dash literals under a GBK locale.
$zhVer = [string][char]0x7248 + [string][char]0x672C  # CJK word for "version"
$fwColon = [string][char]0xFF1A                        # fullwidth colon
$statePath = Join-Path $skillDir 'references/templates/state.json'
$checks = @(
  @{ file='README.md';       pat='\*\*Version\*\*:\s*(.+)'; label='**Version**' },
  @{ file='README.md';       pat='\*\*TAV Workflow v(.+?)\*\*'; label='footer v' },
  @{ file='README.zh-CN.md'; pat="\*\*$zhVer\*\*$fwColon\s*(.+)"; label="**$zhVer**" },
  @{ file='README.zh-CN.md'; pat='\*\*TAV Workflow v(.+?)\*\*'; label='footer v' },
  @{ file=$statePath;        pat='"version":\s*"(.+)"'; label='state.json version field' }
)
foreach ($c in $checks) {
  $t = Read-Text $c.file
  if ($t -match $c.pat) {
    $v = $Matches[1].Trim()
    if ($v -ne $skillVer) { Fail "$($c.label) = '$v' != SKILL.md '$skillVer'" }
    else { Ok "$($c.label) = $v" }
  } else { Fail "$($c.label) line not found" }
}

if ((Read-Text 'CHANGELOG.md') -notmatch ('(?m)^## Version ' + [regex]::Escape($skillVer) + ' \(')) {
  Fail "CHANGELOG.md has no entry for current version $skillVer"
} else { Ok "CHANGELOG.md records current version $skillVer" }

try {
  $null = Read-Text $statePath | ConvertFrom-Json
  Ok 'state.json template is valid JSON'
} catch {
  Fail "state.json template is invalid JSON: $($_.Exception.Message)"
}

# 2b. Example snippets that embed state JSON must not drift from the skill version
foreach ($example in Get-ChildItem (Join-Path $skillDir 'examples') -Filter '*.md') {
  foreach ($m in [regex]::Matches((Read-Text $example.FullName), '"version"\s*:\s*"([^"]+)"')) {
    $v = $m.Groups[1].Value.Trim()
    if ($v -ne $skillVer) { Fail "$($example.Name) embedded version = '$v' != SKILL.md '$skillVer'" }
    else { Ok "$($example.Name) embedded version = $v" }
  }
}

# 3. README relative links resolve to existing files
foreach ($r in 'README.md','README.zh-CN.md') {
  $failsBefore = $script:fail
  foreach ($m in [regex]::Matches((Read-Text $r), '\]\(([^)]+)\)')) {
    $target = $m.Groups[1].Value
    if ($target -match '^https?://' -or $target -match '^#') { continue }
    if (-not (Test-Path (Join-Path $root ($target -replace '#.*$','')))) { Fail "$r -> $target (missing)" }
  }
  if ($script:fail -eq $failsBefore) { Ok "$r internal links resolved" }
}

# 4. Files referenced from SKILL.md exist
$failsBefore = $script:fail
foreach ($req in 'references/branches.md','references/escalation.md','references/spec-driven-interop.md','references/templates/state.json','references/templates/thinker-output.md','references/templates/actor-output.md','references/templates/verifier-output.md','references/implementation-guide.md','references/verification-commands.md') {
  if (-not (Test-Path (Join-Path $skillDir $req))) { Fail "missing referenced file: $req" }
}
if ($script:fail -eq $failsBefore) { Ok 'referenced files exist' }

# 5. Every rule cited in tests/scenarios.md names a heading that still exists
$sect = [string][char]0x00A7  # section sign, kept out of literals for ANSI-codepage safety
$rows = [regex]::Matches((Read-Text 'tests/scenarios.md'), "(?m)\|\s*``([^``]+)``\s*$sect\s*""([^""]+)""\s*\|\s*$")
if ($rows.Count -eq 0) { Fail 'tests/scenarios.md has no rule citations' }
else {
  $failsBefore = $script:fail
  foreach ($row in $rows) {
    $file = Join-Path $skillDir $row.Groups[1].Value
    $heading = $row.Groups[2].Value
    if (-not (Test-Path $file)) { Fail "scenario cites missing file: $($row.Groups[1].Value)" }
    elseif ((Read-Text $file) -notmatch ('(?m)^#{1,6}\s+' + [regex]::Escape($heading) + '\s*$')) { Fail "scenario cites missing heading: $($row.Groups[1].Value) '$heading'" }
  }
  if ($script:fail -eq $failsBefore) { Ok "tests/scenarios.md: $($rows.Count) rule citations resolve" }
}

# 6. Cross-repo handoff contract with spec-driven-develop
$specSkillPath = Join-Path $SpecPath 'plugins/spec-driven-develop/skills/spec-driven-develop/SKILL.md'
if (-not (Test-Path $specSkillPath)) {
  $msg = "spec-driven-develop not found at '$SpecPath' - cross-repo contract checks skipped (pass -SpecPath to enable)"
  if ($env:CI -eq 'true') { Fail $msg } else { Write-Host "WARN: $msg" -ForegroundColor Yellow }
} else {
  $specSkill = Read-Text $specSkillPath
  $em = [string][char]0x2014  # em dash, kept out of literals for ANSI-codepage safety
  $fallback = "A refactor confined to one module $em however messy $em stays at L1 (TAV territory)."
  if ($skill -notlike "*$fallback*" -or $specSkill -notlike "*$fallback*") {
    Fail 'L2 fallback sentence is not verbatim-identical across repos'
  } else { Ok 'L2 fallback sentence is verbatim-identical across repos' }

  $interopPath = Join-Path $skillDir 'references/spec-driven-interop.md'
  $interop = if (Test-Path $interopPath) { Read-Text $interopPath } else { '' }
  $canonicalPayload = 'Outcome, Rework, Plan returns, Unplanned dependencies, and Focused S.U.P.E.R result'
  if ($interop -notlike "*$canonicalPayload*" -or $specSkill -notlike "*$canonicalPayload*") {
    Fail 'execution-event payload is not canonical on both sides of the handoff'
  } else { Ok 'execution-event payload is canonical on both sides of the handoff' }

  $statePattern = '(?ms)\*\*State ownership:\*\*\s*(.*?)(?:\n---|\z)'
  $tavStateMatch = [regex]::Match($interop, $statePattern)
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
