param([switch]$Quick, [string[]]$Only)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$engine = Join-Path $PSScriptRoot 'godot/Godot_v4.5.1-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $engine)) { & (Join-Path $PSScriptRoot 'setup.ps1') }
New-Item -ItemType Directory -Path (Join-Path $projectRoot '.godot') -Force | Out-Null
& $engine --headless --path $projectRoot --editor --import --quit --log-file (Join-Path $projectRoot '.godot/check-import.log') | Out-Null
$checks = @(
    @{ Name = 'safety'; Arg = '--safety-check'; Pass = 'SAFETY PASS'; Limit = 150 },
    @{ Name = 'journal'; Arg = '--journal-check'; Pass = 'JOURNAL PASS'; Limit = 150 },
    @{ Name = 'levels'; Arg = '--level-check'; Pass = 'LEVEL PASS'; Limit = 150 },
    @{ Name = 'woods'; Arg = '--woods-check'; Pass = 'WOODS PASS'; Limit = 180 },
    @{ Name = 'woods-route'; Arg = '--woods-route'; Pass = 'WOODS ROUTE PASS'; Limit = 240 },
    @{ Name = 'side-quests'; Arg = '--side-quest-check'; Pass = 'SIDE QUEST PASS'; Limit = 150 },
    @{ Name = 'controls'; Arg = '--controls-check'; Pass = 'CONTROLS PASS'; Limit = 150 },
    @{ Name = 'journey'; Arg = '--journey-check'; Pass = 'JOURNEY PASS'; Limit = 150 },
    @{ Name = 'splash'; Arg = '--splash-check'; Pass = 'SPLASH PASS'; Limit = 150 },
    @{ Name = 'weeper'; Arg = '--weeper-check'; Pass = 'WEEPER PASS'; Limit = 140 },
    @{ Name = 'godrays'; Arg = '--godrays-check'; Pass = 'GODRAYS PASS'; Limit = 120 },
    @{ Name = 'coop'; Arg = '--coop-check'; Pass = 'COOP PASS'; Limit = 150 },
    @{ Name = 'romance'; Arg = '--romance-check'; Pass = 'ROMANCE PASS'; Limit = 180 },
    @{ Name = 'ranger'; Arg = '--ranger-check'; Pass = 'RANGER PASS'; Limit = 150 },
    @{ Name = 'inventory'; Arg = '--inventory-check'; Pass = 'INVENTORY PASS'; Limit = 120 },
    @{ Name = 'wilderness'; Arg = '--wilderness-check'; Pass = 'WILDERNESS PASS'; Limit = 120 },
    @{ Name = 'grass'; Arg = '--grass-check'; Pass = 'GRASS PASS'; Limit = 150 },
    @{ Name = 'quest-access'; Arg = '--quest-access-check'; Pass = 'QUEST ACCESS PASS'; Limit = 120 },
    @{ Name = 'march-field'; Arg = '--march-field-check'; Pass = 'MARCH FIELD PASS'; Limit = 120 },
    @{ Name = 'field'; Arg = '--field-check'; Pass = 'FIELD PASS'; Limit = 120 },
    @{ Name = 'architecture'; Arg = '--architecture-check'; Pass = 'ARCHITECTURE PASS'; Limit = 150 },
    @{ Name = 'release'; Arg = '--release-check'; Pass = 'RELEASE CHECK PASS'; Limit = 120 },
    @{ Name = 'profession'; Arg = '--profession-check'; Pass = 'PROFESSION PASS'; Limit = 90 },
    @{ Name = 'profession-encounters'; Arg = '--profession-encounters'; Pass = 'PROFESSION ENCOUNTERS PASS'; Limit = 240 },
    @{ Name = 'sound'; Arg = '--sound-check'; Pass = 'SOUND PASS'; Limit = 90 },
    @{ Name = 'smoke'; Arg = '--smoke'; Pass = 'SMOKE PASS'; Limit = 45 },
    @{ Name = 'tour'; Arg = '--tour'; Pass = 'TOUR PASS'; Limit = 45 }
    @{ Name = 'feedback'; Arg = '--feedback-check'; Pass = 'FEEDBACK PASS'; Limit = 90 }
    @{ Name = 'visual'; Arg = '--visual-check'; Pass = 'VISUAL PASS'; Limit = 90 }
    @{ Name = 'forest'; Arg = '--forest-check'; Pass = 'FOREST PASS'; Limit = 90 }
    @{ Name = 'march'; Arg = '--march-check'; Pass = 'MARCH PASS'; Limit = 110 }
    @{ Name = 'terrain'; Arg = '--terrain-check'; Pass = 'TERRAIN PASS'; Limit = 120 }
    @{ Name = 'living'; Arg = '--living-check'; Pass = 'LIVING PASS'; Limit = 100 }
    @{ Name = 'production'; Arg = '--production-check'; Pass = 'PRODUCTION PASS'; Limit = 100 }
    @{ Name = 'survival'; Arg = '--survival-check'; Pass = 'SURVIVAL PASS'; Limit = 90 }
)
if (-not $Quick) {
    $checks += @{ Name = 'march-route'; Arg = '--march-route'; Pass = 'MARCH ROUTE PASS'; Limit = 190 }
    $checks += @{ Name = 'combat'; Arg = '--combat-check'; Pass = 'COMBAT PASS'; Limit = 110 }
    $checks += @{ Name = 'route'; Arg = '--route'; Pass = 'ROUTE PASS'; Limit = 120 }
}
if ($Only) { $checks = @($checks | Where-Object { $_.Name -in $Only }) }
$results = @()
foreach ($check in $checks) {
    $stdout = Join-Path $projectRoot ('reports/check-' + $check.Name + '-stdout.log')
    $stderr = Join-Path $projectRoot ('reports/check-' + $check.Name + '-stderr.log')
    $engineLog = Join-Path $projectRoot ('.godot/check-' + $check.Name + '.log')
    $arguments = '--path "' + $projectRoot + '" --log-file "' + $engineLog + '" -- ' + $check.Arg
    $process = Start-Process -FilePath $engine -ArgumentList $arguments -WorkingDirectory $projectRoot -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $null = $process.Handle
    $timer = [Diagnostics.Stopwatch]::StartNew()
    while (-not $process.WaitForExit(1000)) {
        if ((Test-Path -LiteralPath $stderr) -and (Get-Content -LiteralPath $stderr -Raw) -match 'SCRIPT ERROR|ERROR:|Assertion failed') {
            & taskkill.exe /PID $process.Id /T /F | Out-Null
            throw ($check.Name + ' failed. See ' + $stderr)
        }
        if ($timer.Elapsed.TotalSeconds -gt $check.Limit) {
            & taskkill.exe /PID $process.Id /T /F | Out-Null
            throw ($check.Name + ' timed out. See ' + $stderr)
        }
    }
    $process.Refresh()
    $log = (Get-Content -LiteralPath $stdout -Raw) + (Get-Content -LiteralPath $stderr -Raw)
    if ($process.ExitCode -ne 0 -or $log -match 'SCRIPT ERROR|ERROR:|Assertion failed' -or $log -notmatch $check.Pass) {
        throw ($check.Name + ' failed: ' + $log)
    }
    $line = ($log -split '\r?\n' | Where-Object { $_ -match $check.Pass }) -join ' '
    Write-Host $line
    $results += @{ check = $check.Name; result = 'pass'; seconds = [Math]::Round($timer.Elapsed.TotalSeconds, 2); detail = $line }
}
$resultName = if ($Quick) { 'reports/validation-quick.json' } else { 'reports/validation.json' }
@{ build = ([regex]::Match([IO.File]::ReadAllText((Join-Path $projectRoot 'scripts/content.gd')), 'const BUILD = "([^"]+)"').Groups[1].Value); captured_at_utc = [DateTime]::UtcNow.ToString('o'); checks = $results } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $projectRoot $resultName) -Encoding UTF8
