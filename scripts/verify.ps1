#requires -Version 5.1
# TAV Workflow documentation self-check (structural invariants only).
# Verifies version consistency (single source = SKILL.md frontmatter), README link
# integrity, two-way SKILL.md file references, state.json validity, section citations,
# the cross-repo spec-tav/v1 contract, and the decision-note contract shared with
# write-notes-like-deepseek. The skill lives in skills/tav-workflow/.
# Run: pwsh scripts/verify.ps1 [-SpecPath <spec-driven-develop-repo>] [-DshPath <write-notes-like-deepseek-repo>]

param(
  [string]$SpecPath = '',
  [string]$DshPath = ''
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
if ($SpecPath -eq '') { $SpecPath = Join-Path (Split-Path -Parent $root) 'spec-driven-develop' }
if ($DshPath -eq '') { $DshPath = Join-Path (Split-Path -Parent $root) 'write-notes-like-deepseek' }
$skillDir = Join-Path $root 'skills/tav-workflow'
$script:fail = 0

function Fail($msg) { Write-Host "FAIL: $msg" -ForegroundColor Red; $script:fail++ }
function Ok($msg)   { Write-Host "OK:   $msg" -ForegroundColor Green }
function Read-Text([string]$path) { Get-Content $path -Raw -Encoding UTF8 }

# True when $text has a heading named exactly $anchor (optionally followed by a
# parenthetical qualifier), or a line-leading label, plain or bold, then ':' or '('.
function Test-Anchor([string]$text, [string]$anchor) {
  $a = [regex]::Escape($anchor)
  if ($text -match ('(?m)^#{1,6}\s+' + $a + '(\s+\([^)]*\))?\s*$')) { return $true }
  return ($text -match ('(?m)^\s*(?:[-*]\s+|\d+\.\s+)?(?:\*\*)?' + $a + '(?:\*\*)?\s*[:(]'))
}

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

# 4. SKILL.md and the references/ + examples/ trees agree in both directions: every
# named file exists, and every file on disk is named (an unnamed file is unreachable)
$failsBefore = $script:fail
$named = @([regex]::Matches($skill, '(?:references|examples)/[\w\-./]+\.(?:md|json)') | ForEach-Object { $_.Value } | Sort-Object -Unique)
foreach ($n in $named) {
  if (-not (Test-Path (Join-Path $skillDir $n))) { Fail "SKILL.md names missing file: $n" }
}
$base = (Resolve-Path $skillDir).Path.TrimEnd('\', '/')
foreach ($f in Get-ChildItem -Path @((Join-Path $skillDir 'references'), (Join-Path $skillDir 'examples')) -Recurse -File) {
  $rel = $f.FullName.Substring($base.Length + 1) -replace '\\', '/'
  if ($named -notcontains $rel) { Fail "file not named in SKILL.md: $rel" }
}
if ($script:fail -eq $failsBefore) { Ok "SKILL.md names all $($named.Count) references/examples files, and all exist" }

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
    elseif (-not (Test-Anchor (Read-Text $file) $heading)) { Fail "scenario cites missing heading: $($row.Groups[1].Value) '$heading'" }
  }
  if ($script:fail -eq $failsBefore) { Ok "tests/scenarios.md: $($rows.Count) rule citations resolve" }
}

# 5b. Every quoted section citation inside the skill resolves: `references/x.md` "Name"
# or `SKILL.md` <section sign> "Name" (several names may follow one path, joined by and/or/commas)
$cite = '`((?:references|examples)/[\w\-./]+\.md|SKILL\.md)`\s*(?:' + $sect + '\s*)?((?:"[^"\r\n]+"(?:\s*(?:,|and|or)\s*)?)+)'
$docs = @(Get-Item (Join-Path $skillDir 'SKILL.md')) + @(Get-ChildItem -Path @((Join-Path $skillDir 'references'), (Join-Path $skillDir 'examples')) -Recurse -Filter '*.md')
$failsBefore = $script:fail
$citeCount = 0
foreach ($doc in $docs) {
  foreach ($m in [regex]::Matches((Read-Text $doc.FullName), $cite)) {
    $target = Join-Path $skillDir $m.Groups[1].Value
    if (-not (Test-Path $target)) { Fail "$($doc.Name) cites missing file: $($m.Groups[1].Value)"; continue }
    $targetText = Read-Text $target
    foreach ($q in [regex]::Matches($m.Groups[2].Value, '"([^"]+)"')) {
      $citeCount++
      if (-not (Test-Anchor $targetText $q.Groups[1].Value)) { Fail "$($doc.Name) cites missing section: $($m.Groups[1].Value) '$($q.Groups[1].Value)'" }
    }
  }
}
if ($script:fail -eq $failsBefore) { Ok "$citeCount section citations in SKILL.md, references/, and examples/ resolve" }

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

  # L2 needs at least two signals: the routing descriptions and both signal sentences
  $specFront = if ($specSkill -match '(?s)^---\r?\n(.*?)\r?\n---') { $Matches[1] } else { '' }
  $failsBefore = $script:fail
  if (-not $frontmatter.Contains('at least two')) { Fail 'tav description lost the at-least-two L2 threshold' }
  if (-not $specFront.Contains('at least two')) { Fail 'spec description lost the at-least-two L2 threshold' }
  if (-not $skill.Contains('Escalate to L2 only when **at least two** of these hold')) { Fail 'tav L2 signal sentence lost its at-least-two threshold' }
  if (-not $specSkill.Contains('only when **at least two** of these hold')) { Fail 'spec L2 signal sentence lost its at-least-two threshold' }
  if ($script:fail -eq $failsBefore) { Ok 'at-least-two L2 threshold holds in both descriptions and signal sentences' }

  # Phase 0 must name the tombstone fields that spec's progress template defines
  $phase0 = [regex]::Match($skill, '(?ms)^## Phase 0: Continuity Check.*?(?=^## )').Value
  $progressPath = Join-Path $SpecPath 'plugins/spec-driven-develop/skills/spec-driven-develop/references/templates/progress.md'
  $progress = if (Test-Path $progressPath) { Read-Text $progressPath } else { '' }
  $failsBefore = $script:fail
  foreach ($fp in '**Workflow State**: archived', 'Pending Operations') {
    if (-not $phase0.Contains($fp)) { Fail "tav Phase 0 missing tombstone fingerprint: '$fp'" }
    if (-not $progress.Contains($fp)) { Fail "spec progress template missing tombstone fingerprint: '$fp'" }
  }
  if ($script:fail -eq $failsBefore) { Ok 'tombstone fields match between tav Phase 0 and the spec progress template' }
}

# 7. Decision-note contract with write-notes-like-deepseek: every .agents/notes/<folder>/
# this skill names must be a lifecycle (or the archive) that DSH's tree gate accepts
$dshSkillDir = Join-Path $DshPath 'skills/write-notes-like-deepseek'
$dshTreePath = Join-Path $dshSkillDir 'scripts/agent-note-tree.ts'
if (-not (Test-Path $dshTreePath)) {
  $msg = "write-notes-like-deepseek not found at '$DshPath' - decision-note contract checks skipped (pass -DshPath to enable)"
  if ($env:CI -eq 'true') { Fail $msg } else { Write-Host "WARN: $msg" -ForegroundColor Yellow }
} else {
  $tree = Read-Text $dshTreePath
  $failsBefore = $script:fail
  if ((Read-Text (Join-Path $dshSkillDir 'SKILL.md')) -notmatch '(?m)^name:\s*write-notes-like-deepseek\s*$') { Fail 'DSH SKILL.md name is no longer write-notes-like-deepseek' }
  if (-not $tree.Contains("'.agents/notes'")) { Fail 'DSH tree gate no longer defaults to .agents/notes' }
  $life = [regex]::Match($tree, 'AGENT_NOTE_LIFECYCLES\s*=\s*\[([^\]]*)\]')
  $arch = [regex]::Match($tree, 'AGENT_NOTE_ARCHIVE\s*=\s*''([^'']+)''')
  if (-not $life.Success -or -not $arch.Success) { Fail 'DSH tree gate lifecycle or archive constant not found' }
  else {
    $allowed = @([regex]::Matches($life.Groups[1].Value, '''([^'']+)''') | ForEach-Object { $_.Groups[1].Value }) + $arch.Groups[1].Value
    foreach ($l in 'proposed', 'implemented', 'rejected', 'archived') {
      if ($allowed -notcontains $l) { Fail "DSH tree gate no longer accepts '$l', which the TAV decision-record rules name" }
    }
    foreach ($doc in $docs) {
      foreach ($m in [regex]::Matches((Read-Text $doc.FullName), '\.agents/notes/([a-z-]+)/')) {
        if ($allowed -notcontains $m.Groups[1].Value) { Fail "$($doc.Name) names unknown decision-note folder: .agents/notes/$($m.Groups[1].Value)/" }
      }
    }
  }
  if ($script:fail -eq $failsBefore) { Ok 'decision-note folders and lifecycles match the write-notes-like-deepseek tree gate' }
}

if ($script:fail -gt 0) { Write-Host "`n$($script:fail) check(s) FAILED" -ForegroundColor Red; exit 1 }
Write-Host "`nAll checks passed" -ForegroundColor Green; exit 0
