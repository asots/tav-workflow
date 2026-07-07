#requires -Version 5.1
# TAV Workflow documentation self-check.
# Verifies version consistency (single source = SKILL.md frontmatter) and internal link integrity.
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
foreach ($req in 'references/templates/state.json','references/templates/thinker-output.md','references/templates/actor-output.md','references/templates/verifier-output.md','references/implementation-guide.md','CHANGELOG.md') {
  if (-not (Test-Path $req)) { Fail "missing referenced file: $req" }
}
if ($script:fail -eq $failsBefore) { Ok "referenced files exist" }

if ($script:fail -gt 0) { Write-Host "`n$($script:fail) check(s) FAILED" -ForegroundColor Red; exit 1 }
Write-Host "`nAll checks passed" -ForegroundColor Green; exit 0
