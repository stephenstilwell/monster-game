param(
    [Parameter(Mandatory = $true)][string]$Godot,
    [switch]$Capture,
    [switch]$CleanImport
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$logRoot = Join-Path $projectRoot '.godot/m3_validation/logs'
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
& (Join-Path $PSScriptRoot 'validate_m2.ps1') -Godot $Godot -Capture:$Capture
if ($LASTEXITCODE -ne 0) { throw 'M1/M2 regression failed.' }
function Invoke-M3Step {
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
        throw "M3 validation failed: $Name (exit $processExit)"
    }
    Write-Output ('PASS ' + $Name)
    if ($Expected) { $output | Select-String -SimpleMatch $Expected | ForEach-Object { Write-Output $_.Line } }
}
Invoke-M3Step 'generate' @('--headless','--path',$projectRoot,'--script','tools/art/generate_m3.gd','--quit-after','300') 'M3 GENERATED:'
Invoke-M3Step 'import' @('--headless','--path',$projectRoot,'--editor','--quit') ''
Invoke-M3Step 'assemble' @('--headless','--path',$projectRoot,'--script','tools/art/assemble_m3.gd','--quit-after','300') 'M3 ASSEMBLED:'
$resources = 'brindlewick_frames.tres','cindrel_frames.tres','rillume_frames.tres','effects_frames.tres'
$hashes = @{}
foreach ($name in $resources) { $hashes[$name] = (Get-FileHash -LiteralPath (Join-Path $projectRoot ('assets/generated/m3/' + $name))).Hash }
Invoke-M3Step 'assemble-repeat' @('--headless','--path',$projectRoot,'--script','tools/art/assemble_m3.gd','--quit-after','300') 'M3 ASSEMBLED:'
foreach ($name in $resources) {
    if ($hashes[$name] -ne (Get-FileHash -LiteralPath (Join-Path $projectRoot ('assets/generated/m3/' + $name))).Hash) { throw ('Nondeterministic M3 resource: ' + $name) }
}
Write-Output 'PASS byte-identical M3 resource assembly (4 resources)'
Invoke-M3Step 'art-tests' @('--headless','--path',$projectRoot,'--script','tests/battle/test_art.gd','--quit-after','300') 'M3 ART PASS:'
Invoke-M3Step 'battle-tests' @('--headless','--path',$projectRoot,'--script','tests/battle/test_battle.gd','--quit-after','300') 'M3 BATTLE PASS:'
Invoke-M3Step 'app-smoke' @('--headless','--path',$projectRoot,'--quit-after','5') ''
if ($Capture) {
    Invoke-M3Step 'capture' @('--path',$projectRoot,'--script','tools/art/capture_m3.gd','--quit-after','300') 'M3 CAPTURE PASS:'
    Invoke-M3Step 'screenshots' @('--headless','--path',$projectRoot,'--script','tests/battle/test_screenshots.gd','--quit-after','300') 'M3 SCREENSHOT PASS:'
}
if ($CleanImport) {
    $cleanRoot = Join-Path $projectRoot ('.godot/m3_validation/clean_' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $cleanRoot | Out-Null
    foreach ($entry in 'project.godot','assets','data','tools','scripts','scenes','tests') { Copy-Item -LiteralPath (Join-Path $projectRoot $entry) -Destination $cleanRoot -Recurse }
    Invoke-M3Step 'clean-import' @('--headless','--path',$cleanRoot,'--editor','--quit') ''
    foreach ($suite in @(@('m1','tests/art/test_assets.gd','ART/SHOWCASE PASS:'),@('m2','tests/world/test_exploration.gd','M2 TEST PASS:'),@('art','tests/battle/test_art.gd','M3 ART PASS:'),@('battle','tests/battle/test_battle.gd','M3 BATTLE PASS:'))) {
        Invoke-M3Step ('clean-' + $suite[0]) @('--headless','--path',$cleanRoot,'--script',$suite[1],'--quit-after','300') $suite[2]
    }
    Invoke-M3Step 'clean-app-smoke' @('--headless','--path',$cleanRoot,'--quit-after','5') ''
    Write-Output ('Clean source copy: ' + $cleanRoot)
}
Write-Output ('M3 VALIDATION PASSED. Logs: ' + $logRoot)
