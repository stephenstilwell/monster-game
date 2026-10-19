param(
    [Parameter(Mandatory = $true)][string]$Godot,
    [switch]$Capture,
    [switch]$CleanImport
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$logRoot = Join-Path $projectRoot '.godot/m4_validation/logs'
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
& (Join-Path $PSScriptRoot 'validate_m3.ps1') -Godot $Godot -Capture:$Capture
if ($LASTEXITCODE -ne 0) { throw 'M1/M2/M3 regression failed.' }
function Invoke-M4Step {
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
        throw "M4 validation failed: $Name (exit $processExit)"
    }
    Write-Output ('PASS ' + $Name)
    if ($Expected) { $output | Select-String -SimpleMatch $Expected | ForEach-Object { Write-Output $_.Line } }
}
Invoke-M4Step 'generate' @('--headless','--path',$projectRoot,'--script','tools/art/generate_m4.gd','--quit-after','300') 'M4 GENERATED:'
Invoke-M4Step 'import' @('--headless','--path',$projectRoot,'--editor','--quit') ''
Invoke-M4Step 'art' @('--headless','--path',$projectRoot,'--script','tests/save/test_art.gd','--quit-after','300') 'M4 ART PASS:'
Invoke-M4Step 'system' @('--headless','--path',$projectRoot,'--script','tests/save/test_management.gd','--quit-after','300') 'M4 SYSTEM PASS:'
Invoke-M4Step 'app-smoke' @('--headless','--path',$projectRoot,'--quit-after','5') ''
if ($Capture) {
    Invoke-M4Step 'capture' @('--path',$projectRoot,'--script','tools/art/capture_m4.gd','--quit-after','300') 'M4 CAPTURE PASS:'
    Invoke-M4Step 'screenshots' @('--headless','--path',$projectRoot,'--script','tests/save/test_screenshots.gd','--quit-after','300') 'M4 SCREENSHOT PASS:'
}
if ($CleanImport) {
    $cleanRoot = Join-Path $projectRoot ('.godot/m4_validation/clean_' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $cleanRoot | Out-Null
    foreach ($entry in 'project.godot','assets','data','tools','scripts','scenes','tests') { Copy-Item -LiteralPath (Join-Path $projectRoot $entry) -Destination $cleanRoot -Recurse }
    Invoke-M4Step 'clean-import' @('--headless','--path',$cleanRoot,'--editor','--quit') ''
    foreach ($suite in @(@('m1','tests/art/test_assets.gd','ART/SHOWCASE PASS:'),@('m2','tests/world/test_exploration.gd','M2 TEST PASS:'),@('m3-art','tests/battle/test_art.gd','M3 ART PASS:'),@('m3-battle','tests/battle/test_battle.gd','M3 BATTLE PASS:'),@('m4-art','tests/save/test_art.gd','M4 ART PASS:'),@('m4-system','tests/save/test_management.gd','M4 SYSTEM PASS:'))) {
        Invoke-M4Step ('clean-' + $suite[0]) @('--headless','--path',$cleanRoot,'--script',$suite[1],'--quit-after','300') $suite[2]
    }
    Invoke-M4Step 'clean-app-smoke' @('--headless','--path',$cleanRoot,'--quit-after','5') ''
    Write-Output ('Clean source copy: ' + $cleanRoot)
}
Write-Output ('M4 VALIDATION PASSED. Logs: ' + $logRoot)
