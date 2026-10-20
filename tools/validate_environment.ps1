param([Parameter(Mandatory = $true)][string]$Godot, [switch]$Capture, [switch]$CleanImport)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$logRoot = Join-Path $projectRoot '.godot/environment_validation/logs'
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
function Invoke-EnvironmentStep {
 param([string]$Name, [string[]]$Arguments, [string]$Expected)
 $savedPreference=$ErrorActionPreference
 $ErrorActionPreference='Continue'
 $output=& $Godot @Arguments 2>&1
 $processExit=$LASTEXITCODE
 $ErrorActionPreference=$savedPreference
 $lines=$output|Out-String
 $lines|Set-Content -Encoding UTF8 -LiteralPath (Join-Path $logRoot ($Name+'.log'))
 if($processExit -ne 0 -or $lines -match 'SCRIPT ERROR:|ERROR:|WARNING:' -or ($Expected -and $lines -notmatch [regex]::Escape($Expected))){Write-Output $lines;throw ('Environment validation failed: '+$Name)}
 Write-Output ('PASS '+$Name)
 if($Expected){$output|Select-String -SimpleMatch $Expected|ForEach-Object{Write-Output $_.Line}}
}
Invoke-EnvironmentStep 'generate' @('--headless','--path',$projectRoot,'--script','tools/art/generate_environment.gd','--quit-after','1000') 'ENVIRONMENT GENERATED:'
Invoke-EnvironmentStep 'import' @('--headless','--path',$projectRoot,'--editor','--quit') ''
$suites=@(@('environment','tests/environment/test_environment.gd','ENVIRONMENT TEST PASS:'),@('world','tests/world/test_exploration.gd','M2 TEST PASS:'),@('flow','tests/progression/test_flow.gd','M6 FLOW PASS:'),@('state','tests/progression/test_state.gd','M6 STATE PASS:'))
foreach($suite in $suites){Invoke-EnvironmentStep $suite[0] @('--headless','--path',$projectRoot,'--script',$suite[1],'--quit-after','1000') $suite[2]}
Invoke-EnvironmentStep 'app' @('--headless','--path',$projectRoot,'--quit-after','5') ''
if($Capture){
 Invoke-EnvironmentStep 'capture' @('--path',$projectRoot,'--script','tools/art/capture_environment.gd','--quit-after','1000') 'ENVIRONMENT CAPTURE PASS:'
 Invoke-EnvironmentStep 'screenshots' @('--headless','--path',$projectRoot,'--script','tests/environment/test_screenshots.gd','--quit-after','1000') 'ENVIRONMENT SCREENSHOT PASS:'
}
if($CleanImport){
 $cleanRoot=Join-Path $projectRoot ('.godot/environment_validation/clean_'+[guid]::NewGuid().ToString('N'))
 New-Item -ItemType Directory -Path $cleanRoot|Out-Null
 foreach($entry in 'project.godot','assets','data','tools','scripts','scenes','tests'){Copy-Item -LiteralPath (Join-Path $projectRoot $entry) -Destination $cleanRoot -Recurse}
 Invoke-EnvironmentStep 'clean-import' @('--headless','--path',$cleanRoot,'--editor','--quit') ''
 foreach($suite in $suites){Invoke-EnvironmentStep ('clean-'+$suite[0]) @('--headless','--path',$cleanRoot,'--script',$suite[1],'--quit-after','1000') $suite[2]}
 Invoke-EnvironmentStep 'clean-app' @('--headless','--path',$cleanRoot,'--quit-after','5') ''
 Write-Output ('Clean source copy: '+$cleanRoot)
}
Write-Output ('ENVIRONMENT VALIDATION PASSED. Logs: '+$logRoot)
