param(
    [Parameter(Mandatory = $true)][string]$Godot,
    [switch]$Capture,
    [switch]$CleanImport
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$logRoot = Join-Path $projectRoot '.godot/m2_validation/logs'
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
# Keep the original visual milestone passing while exploration becomes the default scene.
& (Join-Path $PSScriptRoot 'validate_m1.ps1') -Godot $Godot -Capture:$Capture
if ($LASTEXITCODE -ne 0) { throw 'M1 regression failed.' }
function Invoke-M2Step {
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
        throw "M2 validation failed: $Name (exit $processExit)"
    }
    Write-Output ('PASS ' + $Name)
    if ($Expected) { $output | Select-String -SimpleMatch $Expected | ForEach-Object { Write-Output $_.Line } }
}
Invoke-M2Step 'generate' @('--headless','--path',$projectRoot,'--script','tools/art/generate_m2.gd','--quit-after','300') 'M2 GENERATED:'
Invoke-M2Step 'import' @('--headless','--path',$projectRoot,'--editor','--quit') ''
Invoke-M2Step 'assemble' @('--headless','--path',$projectRoot,'--script','tools/art/assemble_m2.gd','--quit-after','300') 'M2 ASSEMBLED:'
$resources = 'mara_frames.tres','ivo_frames.tres','exploration_tileset.tres'
$hashes = @{}
foreach ($name in $resources) { $hashes[$name] = (Get-FileHash -LiteralPath (Join-Path $projectRoot ('assets/generated/m2/' + $name))).Hash }
Invoke-M2Step 'assemble-repeat' @('--headless','--path',$projectRoot,'--script','tools/art/assemble_m2.gd','--quit-after','300') 'M2 ASSEMBLED:'
foreach ($name in $resources) {
    if ($hashes[$name] -ne (Get-FileHash -LiteralPath (Join-Path $projectRoot ('assets/generated/m2/' + $name))).Hash) { throw ('Nondeterministic M2 resource: ' + $name) }
}
Write-Output 'PASS byte-identical M2 resource assembly (3 resources)'
Invoke-M2Step 'world-tests' @('--headless','--path',$projectRoot,'--script','tests/world/test_exploration.gd','--quit-after','300') 'M2 TEST PASS:'
Invoke-M2Step 'scene-smoke' @('--headless','--path',$projectRoot,'--quit-after','5') ''
if ($Capture) {
    Invoke-M2Step 'capture' @('--path',$projectRoot,'--script','tools/art/capture_m2.gd','--quit-after','300') 'M2 CAPTURE PASS:'
    Invoke-M2Step 'screenshots' @('--headless','--path',$projectRoot,'--script','tests/world/test_screenshots.gd','--quit-after','300') 'M2 SCREENSHOT PASS:'
}
if ($CleanImport) {
    $cleanRoot = Join-Path $projectRoot ('.godot/m2_validation/clean_' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $cleanRoot | Out-Null
    foreach ($entry in 'project.godot','assets','data','tools','scripts','scenes','tests') {
        Copy-Item -LiteralPath (Join-Path $projectRoot $entry) -Destination $cleanRoot -Recurse
    }
    Invoke-M2Step 'clean-import' @('--headless','--path',$cleanRoot,'--editor','--quit') ''
    Invoke-M2Step 'clean-art-tests' @('--headless','--path',$cleanRoot,'--script','tests/art/test_assets.gd','--quit-after','300') 'ART/SHOWCASE PASS:'
    Invoke-M2Step 'clean-world-tests' @('--headless','--path',$cleanRoot,'--script','tests/world/test_exploration.gd','--quit-after','300') 'M2 TEST PASS:'
    Invoke-M2Step 'clean-scene-smoke' @('--headless','--path',$cleanRoot,'--quit-after','5') ''
    Write-Output ('Clean source copy: ' + $cleanRoot)
}
Write-Output ('M2 VALIDATION PASSED. Logs: ' + $logRoot)
