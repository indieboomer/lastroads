param([ValidateSet("coop","godrays","weeper","splash")][string]$Check = "coop")
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$source = Join-Path $root 'dist/TheLastRoads-0.15.5-Coop-Preview'
$staging = Join-Path $root 'reports/coop/standalone-0.15.5'
New-Item -ItemType Directory -Path $staging -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $staging 'runtime') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $source 'TheLastRoads.pck') -Destination (Join-Path $staging 'TheLastRoads.pck')
Copy-Item -Path (Join-Path $source 'runtime/*') -Destination (Join-Path $staging 'runtime') -Force
$engine = Join-Path $staging 'runtime/godotsteam.452.editor.win64.console.exe'
$logName = "standalone-$Check-check"
$passMarker = if ($Check -eq 'coop') { 'COOP PASS' } elseif ($Check -eq 'weeper') { 'WEEPER PASS' } elseif ($Check -eq 'splash') { 'SPLASH PASS' } else { 'GODRAYS PASS' }
$stdout = Join-Path $root ("reports/coop/$logName-stdout.log")
$stderr = Join-Path $root ("reports/coop/$logName-stderr.log")
$argsList = @('--main-pack',('"' + (Join-Path $staging 'TheLastRoads.pck') + '"'),'--log-file',('"' + (Join-Path $root 'reports/coop/standalone-engine.log') + '"'),'--',("--$Check-check"))
$process = Start-Process -FilePath $engine -ArgumentList $argsList -WorkingDirectory $staging -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
$null = $process.Handle
if (-not $process.WaitForExit(150000)) { Stop-Process -Id $process.Id -Force; throw 'Packaged co-op check timed out.' }
$log = [IO.File]::ReadAllText($stdout)+[IO.File]::ReadAllText($stderr)
if ($process.ExitCode -ne 0 -or $log -match 'SCRIPT ERROR|ERROR:|Assertion failed' -or $log -notmatch $passMarker) { throw "Packaged co-op check failed: $log" }
Write-Host ("PACKAGE PASS: $Check / actual GodotSteam runtime and PCK / isolated directory.")
