param([Parameter(Mandatory=$true)][string]$GameRoot)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $GameRoot).Path
$pack = Join-Path $root 'TheLastRoads.pck'
if (Test-Path -LiteralPath $pack) {
    $engine = Join-Path $root 'runtime/godotsteam.452.editor.win64.exe'
    $gameArgs = @('--main-pack', ('"' + $pack + '"'))
} else {
    $engine = Join-Path $root 'tools/godot/Godot_v4.5.1-stable_win64.exe'
    if (-not (Test-Path -LiteralPath $engine)) { $engine = Join-Path $root 'tools/godot/Godot_v4.5.1-stable_win64_console.exe' }
    $gameArgs = @('--path', ('"' + $root + '"'))
}
$logs = Join-Path $root 'debug-logs'
New-Item -ItemType Directory -Path $logs -Force | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
for ($instance = 1; $instance -le 2; $instance++) {
    $log = Join-Path $logs "local-$stamp-$instance.log"
    $position = if ($instance -eq 1) { '20,30' } else { '520,300' }
    $arguments = $gameArgs + @('--windowed','--resolution','960x540','--position',$position,'--log-file',('"' + $log + '"'))
    Start-Process -FilePath $engine -ArgumentList $arguments -WorkingDirectory $root | Out-Null
}
Write-Host 'Window 1: Co-op > Host on LAN. Window 2: Co-op > Join host.'
Write-Host 'Address: 127.0.0.1 / port: 27841. Pick different character names and colors.'
Write-Host 'This local test uses LAN networking. Menus and switching focus keep the party running.'
