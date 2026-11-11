$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$archive = Join-Path $PSScriptRoot 'godotsteam-win64.tar.xz'
$url = 'https://codeberg.org/godotsteam/godotsteam/releases/download/v4.24/win64-g452-s165-gs424-editor.tar.xz'
if (-not (Test-Path -LiteralPath $archive)) { Invoke-WebRequest -UseBasicParsing $url -OutFile $archive }
$expected = '36B92F0C575875544FFC7BD9DD8BC161F34D4D7BD4D2867AFEC9EE893C63295A'
if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $expected) { throw 'GodotSteam archive checksum mismatch.' }
& py -3 (Join-Path $PSScriptRoot 'unpack-steam.py') $archive (Join-Path $root 'tools/godot-steam')
if ($LASTEXITCODE -ne 0) { throw 'GodotSteam extraction failed.' }
Write-Host 'GodotSteam 4.24 / Godot 4.5.2 installed. Set LAST_ROADS_STEAM_APP_ID or coop/steam_app_id and run launch-coop.cmd.'
