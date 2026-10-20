param([Parameter(Mandatory = $true)][string]$Godot, [switch]$Playback, [switch]$CleanImport)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$logRoot = Join-Path $projectRoot '.godot/audio_validation/logs'
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
function Invoke-AudioStep {
 param([string]$Name, [string[]]$Arguments, [string]$Expected)
 $savedPreference=$ErrorActionPreference
 $ErrorActionPreference='Continue'
 $output=& $Godot @Arguments 2>&1
 $processExit=$LASTEXITCODE
 $ErrorActionPreference=$savedPreference
 $lines=$output|Out-String
 $lines|Set-Content -Encoding UTF8 -LiteralPath (Join-Path $logRoot ($Name+'.log'))
 if($processExit -ne 0 -or $lines -match 'SCRIPT ERROR:|ERROR:|WARNING:' -or ($Expected -and $lines -notmatch [regex]::Escape($Expected))){Write-Output $lines;throw ('Audio validation failed: '+$Name)}
 Write-Output ('PASS '+$Name)
 if($Expected){$output|Select-String -SimpleMatch $Expected|ForEach-Object{Write-Output $_.Line}}
}
Invoke-AudioStep 'generate' @('--headless','--path',$projectRoot,'--script','tools/audio/generate_score.gd','--quit-after','1000') 'AUDIO GENERATED:'
Invoke-AudioStep 'import' @('--headless','--path',$projectRoot,'--editor','--quit') ''
$suites=@(@('audio','tests/audio/test_audio.gd','AUDIO TESTS:'),@('flow','tests/progression/test_flow.gd','M6 FLOW PASS:'),@('state','tests/progression/test_state.gd','M6 STATE PASS:'))
foreach($suite in $suites){Invoke-AudioStep $suite[0] @('--headless','--path',$projectRoot,'--script',$suite[1],'--quit-after','1000') $suite[2]}
Invoke-AudioStep 'app' @('--headless','--path',$projectRoot,'--quit-after','5') ''
if($Playback){
 Invoke-AudioStep 'playback' @('--path',$projectRoot,'--script','tests/audio/test_playback.gd','--quit-after','1500') 'AUDIO PLAYBACK:'
}
if($CleanImport){
 $cleanRoot=Join-Path $projectRoot ('.godot/audio_validation/clean_'+[guid]::NewGuid().ToString('N'))
 New-Item -ItemType Directory -Path $cleanRoot|Out-Null
 foreach($entry in 'project.godot','assets','data','tools','scripts','scenes','tests'){Copy-Item -LiteralPath (Join-Path $projectRoot $entry) -Destination $cleanRoot -Recurse}
 Invoke-AudioStep 'clean-import' @('--headless','--path',$cleanRoot,'--editor','--quit') ''
 foreach($suite in $suites){Invoke-AudioStep ('clean-'+$suite[0]) @('--headless','--path',$cleanRoot,'--script',$suite[1],'--quit-after','1000') $suite[2]}
 Invoke-AudioStep 'clean-app' @('--headless','--path',$cleanRoot,'--quit-after','5') ''
 Write-Output ('Clean source copy: '+$cleanRoot)
}
Write-Output ('AUDIO VALIDATION PASSED. Logs: '+$logRoot)
