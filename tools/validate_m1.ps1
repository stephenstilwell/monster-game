param(
    [Parameter(Mandatory = $true)][string]$Godot,
    [switch]$Capture,
    [switch]$CleanImport
)
# Source-project developer validation. No downloads, dependency installation or deletion.
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$logRoot = Join-Path $projectRoot '.godot/m1_validation/logs'
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
if (-not (Test-Path -LiteralPath $Godot -PathType Leaf)) { throw 'Provide the installed Godot console executable with -Godot.' }

function Invoke-GodotStep {
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
        throw "Godot validation failed: $Name (exit $processExit)"
    }
    Write-Output ("PASS " + $Name)
    if ($Expected) { $output | Select-String -SimpleMatch $Expected | ForEach-Object { Write-Output $_.Line } }
}

Invoke-GodotStep 'version' @('--version') '4.7.2.stable'
Invoke-GodotStep 'generate' @('--headless','--path',$projectRoot,'--script','tools/art/generate.gd','--quit-after','300') 'GENERATED:'
Invoke-GodotStep 'import' @('--headless','--path',$projectRoot,'--editor','--quit') ''
Invoke-GodotStep 'assemble' @('--headless','--path',$projectRoot,'--script','tools/art/assemble.gd','--quit-after','300') 'ASSEMBLED:'
$resourceNames = 'player_frames.tres','brindlewick_frames.tres','effects_frames.tres','woodland_tileset.tres','woodland_theme.tres'
$resourceHashes = @{}
foreach ($name in $resourceNames) { $resourceHashes[$name] = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $projectRoot ('assets/generated/' + $name))).Hash }
Invoke-GodotStep 'assemble-repeat' @('--headless','--path',$projectRoot,'--script','tools/art/assemble.gd','--quit-after','300') 'ASSEMBLED:'
foreach ($name in $resourceNames) {
    if ($resourceHashes[$name] -ne (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $projectRoot ('assets/generated/' + $name))).Hash) { throw ('Nondeterministic Godot resource: ' + $name) }
}
Write-Output 'PASS byte-identical repeated assembly (5 resources)'
Invoke-GodotStep 'art-tests' @('--headless','--path',$projectRoot,'--script','tests/art/test_assets.gd','--quit-after','300') 'ART/SHOWCASE PASS:'
Invoke-GodotStep 'scene-smoke' @('--headless','--path',$projectRoot,'--quit-after','5') ''
if ($Capture) {
    Invoke-GodotStep 'capture' @('--path',$projectRoot,'--quit-after','300','--','--capture') 'CAPTURE PASS:'
    Invoke-GodotStep 'screenshots' @('--headless','--path',$projectRoot,'--script','tests/art/test_screenshots.gd','--quit-after','300') 'SCREENSHOT PASS:'
}
if ($CleanImport) {
    # A new isolated source copy proves startup without any existing import cache.
    $cleanRoot = Join-Path $projectRoot ('.godot/m1_validation/clean_' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $cleanRoot | Out-Null
    foreach ($entry in 'project.godot','icon.svg','icon.svg.import','assets','tools','scripts','scenes','tests') {
        Copy-Item -LiteralPath (Join-Path $projectRoot $entry) -Destination $cleanRoot -Recurse
    }
    Invoke-GodotStep 'clean-import' @('--headless','--path',$cleanRoot,'--editor','--quit') ''
    Invoke-GodotStep 'clean-art-tests' @('--headless','--path',$cleanRoot,'--script','tests/art/test_assets.gd','--quit-after','300') 'ART/SHOWCASE PASS:'
    Invoke-GodotStep 'clean-scene-smoke' @('--headless','--path',$cleanRoot,'--quit-after','5') ''
    Write-Output ('Clean source copy: ' + $cleanRoot)
}
Write-Output ('M1 VALIDATION PASSED. Logs: ' + $logRoot)
