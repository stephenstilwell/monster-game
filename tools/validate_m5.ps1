param(
    [Parameter(Mandatory = $true)][string]$Godot,
    [switch]$Capture,
    [switch]$CleanImport
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$logRoot = Join-Path $projectRoot '.godot/m5_validation/logs'
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
& (Join-Path $PSScriptRoot 'validate_m4.ps1') -Godot $Godot -Capture:$Capture
if ($LASTEXITCODE -ne 0) { throw 'M1-M4 foundation regression failed.' }
function Invoke-M5Step {
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
        throw "M5 validation failed: $Name (exit $processExit)"
    }
    Write-Output ('PASS ' + $Name)
    if ($Expected) { $output | Select-String -SimpleMatch $Expected | ForEach-Object { Write-Output $_.Line } }
}
Invoke-M5Step 'generate' @('--headless','--path',$projectRoot,'--script','tools/art/generate_m5.gd','--quit-after','1000') 'M5 GENERATED:'
Invoke-M5Step 'import' @('--headless','--path',$projectRoot,'--editor','--quit') ''
Invoke-M5Step 'assemble' @('--headless','--path',$projectRoot,'--script','tools/art/assemble_m5.gd','--quit-after','1000') 'M5 ASSEMBLED:'
$resourcePath = Join-Path $projectRoot 'assets/generated/m5/guardian_frames.tres'
$resourceHash = (Get-FileHash -LiteralPath $resourcePath).Hash
Invoke-M5Step 'assemble-repeat' @('--headless','--path',$projectRoot,'--script','tools/art/assemble_m5.gd','--quit-after','1000') 'M5 ASSEMBLED:'
if ((Get-FileHash -LiteralPath $resourcePath).Hash -ne $resourceHash) { throw 'Nondeterministic M5 SpriteFrames.' }
$suites = @(@('art','tests/expedition/test_art.gd','M5 ART PASS:'),@('state','tests/expedition/test_state.gd','M5 STATE PASS:'),@('flow','tests/expedition/test_flow.gd','M5 FLOW PASS:'),@('balance','tests/expedition/test_balance.gd','M5 BALANCE PASS:'))
foreach ($suite in $suites) { Invoke-M5Step $suite[0] @('--headless','--path',$projectRoot,'--script',$suite[1],'--quit-after','1000') $suite[2] }
Invoke-M5Step 'app-smoke' @('--headless','--path',$projectRoot,'--quit-after','5') ''
if ($Capture) {
    Invoke-M5Step 'capture' @('--path',$projectRoot,'--script','tools/art/capture_m5.gd','--quit-after','1000') 'M5 CAPTURE PASS:'
    Invoke-M5Step 'screenshots' @('--headless','--path',$projectRoot,'--script','tests/expedition/test_screenshots.gd','--quit-after','1000') 'M5 SCREENSHOT PASS:'
}
if ($CleanImport) {
    $cleanRoot = Join-Path $projectRoot ('.godot/m5_validation/clean_' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $cleanRoot | Out-Null
    foreach ($entry in 'project.godot','assets','data','tools','scripts','scenes','tests') { Copy-Item -LiteralPath (Join-Path $projectRoot $entry) -Destination $cleanRoot -Recurse }
    Invoke-M5Step 'clean-import' @('--headless','--path',$cleanRoot,'--editor','--quit') ''
    $earlier = @(@('m1','tests/art/test_assets.gd','ART/SHOWCASE PASS:'),@('m2','tests/world/test_exploration.gd','M2 TEST PASS:'),@('m3-art','tests/battle/test_art.gd','M3 ART PASS:'),@('m3-battle','tests/battle/test_battle.gd','M3 BATTLE PASS:'),@('m4-art','tests/save/test_art.gd','M4 ART PASS:'),@('m4-system','tests/save/test_management.gd','M4 SYSTEM PASS:'))
    foreach ($suite in ($earlier + $suites)) {
        Invoke-M5Step ('clean-' + $suite[0]) @('--headless','--path',$cleanRoot,'--script',$suite[1],'--quit-after','1000') $suite[2]
    }
    Invoke-M5Step 'clean-app-smoke' @('--headless','--path',$cleanRoot,'--quit-after','5') ''
    Write-Output ('Clean source copy: ' + $cleanRoot)
}
Write-Output ('M5 VALIDATION PASSED. Logs: ' + $logRoot)