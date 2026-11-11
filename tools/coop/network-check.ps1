param([int]$Port = (Get-Random -Minimum 29500 -Maximum 31000))
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$engine = Join-Path $root 'tools/godot/Godot_v4.5.1-stable_win64_console.exe'
$reportRoot = Join-Path $root 'reports/coop'
$jobs = @()
for ($slot = 0; $slot -le 4; $slot++) {
    $role = if ($slot -eq 0) { 'host' } else { 'client' }
    $stdout = Join-Path $reportRoot "network-$Port-$slot-stdout.log"
    $stderr = Join-Path $reportRoot "network-$Port-$slot-stderr.log"
    $argsList = @('--headless','--audio-driver','Dummy','--max-fps','30','--path',('"' + $root + '"'),'--','--coop-probe',"--role=$role","--slot=$slot","--port=$Port")
    $process = Start-Process -FilePath $engine -ArgumentList $argsList -WorkingDirectory $root -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $null = $process.Handle
    $jobs += @{ Process = $process; Out = $stdout; Err = $stderr; Slot = $slot }
    if ($slot -eq 0) {
        $marker = Join-Path $reportRoot "listening-$Port.txt"
        $timer = [Diagnostics.Stopwatch]::StartNew()
        while (-not (Test-Path -LiteralPath $marker)) {
            if ($process.HasExited -or $timer.Elapsed.TotalSeconds -gt 45) { throw "Host could not start. See $stderr" }
            Start-Sleep -Milliseconds 200
        }
    } elseif ($slot -lt 4) {
        Start-Sleep -Milliseconds 1200
    }
}
$results = @()
foreach ($job in $jobs) {
    if (-not $job.Process.WaitForExit(60000)) {
        Stop-Process -Id $job.Process.Id -Force
        throw "Network probe $($job.Slot) timed out."
    }
    $log = [IO.File]::ReadAllText($job.Out) + [IO.File]::ReadAllText($job.Err)
    if ($job.Process.ExitCode -ne 0 -or $log -match 'SCRIPT ERROR|ERROR:|Assertion failed') { throw "Network probe $($job.Slot) failed: $log" }
    $result = Get-Content -LiteralPath (Join-Path $reportRoot "probe-$($job.Slot).json") -Raw | ConvertFrom-Json
    if (-not $result.passed) { throw "Network probe $($job.Slot) did not pass." }
    $results += $result
}
if (-not ($results | Where-Object { $_.role -eq 'client' -and $_.incoming_damage })) { throw 'No visitor received an authoritative enemy attack.' }
if (@($results | Where-Object { $_.slot -in 1,2,3 -and $_.guardian_damage -and $_.weeper_frame }).Count -ne 3) { throw 'All three visitors must receive the Weeper cone and shared introduction.' }
$results | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $reportRoot 'network-validation.json') -Encoding UTF8
Write-Host 'COOP NETWORK PASS: host plus three clients, fifth admission refused, late-join world/enemy replication, authoritative enemy attacks reach visitors, private character identity and save isolation, host menu does not pause transport.'
