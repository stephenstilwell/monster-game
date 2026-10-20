param(
 [Parameter(Mandatory = $true)][string]$Godot,
 [switch]$Capture,
 [switch]$CleanImport,
 [switch]$SkipFoundation
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$logRoot = Join-Path $projectRoot '.godot/m6_validation/logs'
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
if (-not $SkipFoundation) {
 & (Join-Path $PSScriptRoot 'validate_m5.ps1') -Godot $Godot -Capture:$Capture
 if ($LASTEXITCODE -ne 0) { throw 'M1-M5 regression failed.' }
}
function Invoke-M6Step {
 param([string]$Name, [string[]]$Arguments, [string]$Expected)
 $savedPreference = $ErrorActionPreference
 $ErrorActionPreference = 'Continue'
 $output = & $Godot @Arguments 2>&1
 $processExit = $LASTEXITCODE
 $ErrorActionPreference = $savedPreference
 $lines = $output | Out-String
 $lines | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $logRoot ($Name + '.log'))
 if ($processExit -ne 0 -or $lines -match '(SCRIPT ERROR:|ERROR:|WARNING:)' -or ($Expected -and $lines -notmatch [regex]::Escape($Expected))) {
  Write-Output $lines
  throw "M6 validation failed: $Name (exit $processExit)"
 }
 Write-Output ('PASS ' + $Name)
 if ($Expected) { $output | Select-String -SimpleMatch $Expected | ForEach-Object { Write-Output $_.Line } }
}
Invoke-M6Step 'generate' @('--headless','--path',$projectRoot,'--script','tools/art/generate_m6.gd','--quit-after','1000') 'M6 GENERATED:'
Invoke-M6Step 'import' @('--headless','--path',$projectRoot,'--editor','--quit') ''
Invoke-M6Step 'assemble' @('--headless','--path',$projectRoot,'--script','tools/art/assemble_m6.gd','--quit-after','1000') 'M6 ASSEMBLED:'
$hashes = @{}
foreach ($id in 'briarwarden','pyrelace','tideveil') { $hashes[$id] = (Get-FileHash -LiteralPath (Join-Path $projectRoot ('assets/generated/m6/' + $id + '_frames.tres'))).Hash }
Invoke-M6Step 'assemble-repeat' @('--headless','--path',$projectRoot,'--script','tools/art/assemble_m6.gd','--quit-after','1000') 'M6 ASSEMBLED:'
foreach ($id in $hashes.Keys) { if ((Get-FileHash -LiteralPath (Join-Path $projectRoot ('assets/generated/m6/' + $id + '_frames.tres'))).Hash -ne $hashes[$id]) { throw 'Nondeterministic M6 SpriteFrames.' } }
$suites = @(@('art','tests/progression/test_art.gd','M6 ART PASS:'),@('state','tests/progression/test_state.gd','M6 STATE PASS:'),@('transactions','tests/progression/test_transactions.gd','M6 TRANSACTION PASS:'),@('rules','tests/progression/test_rules.gd','M6 RULES PASS:'),@('flow','tests/progression/test_flow.gd','M6 FLOW PASS:'),@('balance','tests/progression/test_balance.gd','M6 BALANCE PASS:'))
foreach ($suite in $suites) { Invoke-M6Step $suite[0] @('--headless','--path',$projectRoot,'--script',$suite[1],'--quit-after','1000') $suite[2] }
Invoke-M6Step 'app-smoke' @('--headless','--path',$projectRoot,'--quit-after','5') ''
if ($Capture) {
 Invoke-M6Step 'capture' @('--path',$projectRoot,'--script','tools/art/capture_m6.gd','--quit-after','1000') 'M6 CAPTURE PASS:'
 Invoke-M6Step 'screenshots' @('--headless','--path',$projectRoot,'--script','tests/progression/test_screenshots.gd','--quit-after','1000') 'M6 SCREENSHOT PASS:'
}
if ($CleanImport) {
 $cleanRoot = Join-Path $projectRoot ('.godot/m6_validation/clean_' + [guid]::NewGuid().ToString('N'))
 New-Item -ItemType Directory -Path $cleanRoot | Out-Null
 foreach ($entry in 'project.godot','assets','data','tools','scripts','scenes','tests') { Copy-Item -LiteralPath (Join-Path $projectRoot $entry) -Destination $cleanRoot -Recurse }
 Invoke-M6Step 'clean-import' @('--headless','--path',$cleanRoot,'--editor','--quit') ''
 $earlier = @(@('m1','tests/art/test_assets.gd','ART/SHOWCASE PASS:'),@('m2','tests/world/test_exploration.gd','M2 TEST PASS:'),@('m3-art','tests/battle/test_art.gd','M3 ART PASS:'),@('m3-battle','tests/battle/test_battle.gd','M3 BATTLE PASS:'),@('m4-art','tests/save/test_art.gd','M4 ART PASS:'),@('m4-system','tests/save/test_management.gd','M4 SYSTEM PASS:'),@('m5-art','tests/expedition/test_art.gd','M5 ART PASS:'),@('m5-state','tests/expedition/test_state.gd','M5 STATE PASS:'),@('m5-flow','tests/expedition/test_flow.gd','M5 FLOW PASS:'),@('m5-balance','tests/expedition/test_balance.gd','M5 BALANCE PASS:'))
 foreach ($suite in ($earlier + $suites)) { Invoke-M6Step ('clean-' + $suite[0]) @('--headless','--path',$cleanRoot,'--script',$suite[1],'--quit-after','1000') $suite[2] }
 Invoke-M6Step 'clean-app-smoke' @('--headless','--path',$cleanRoot,'--quit-after','5') ''
 Write-Output ('Clean source copy: ' + $cleanRoot)
}
Write-Output ('M6 VALIDATION PASSED. Logs: ' + $logRoot)
