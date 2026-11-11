$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$engineFolder = Join-Path $PSScriptRoot 'godot'
$archive = Join-Path $PSScriptRoot 'godot.zip'
$download = 'https://github.com/godotengine/godot-builds/releases/download/4.5.1-stable/Godot_v4.5.1-stable_win64.exe.zip'
$expected = 'DEFCCC78669E644861B4247626B01AE362CD9F23975EDF19C8BFD2EB1F6A1783'
if (-not (Test-Path -LiteralPath $archive)) {
    Write-Host 'Downloading pinned Godot 4.5.1 stable...'
    Invoke-WebRequest -Uri $download -OutFile $archive -UseBasicParsing
}
if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $expected) {
    throw 'Engine archive checksum mismatch. The archive was not extracted.'
}
Expand-Archive -LiteralPath $archive -DestinationPath $engineFolder -Force
New-Item -ItemType File -Path (Join-Path $engineFolder '_sc_') -Force | Out-Null
$engine = Join-Path $engineFolder 'Godot_v4.5.1-stable_win64_console.exe'
New-Item -ItemType Directory -Path (Join-Path $projectRoot '.godot') -Force | Out-Null
& $engine --headless --path $projectRoot --editor --import --quit --log-file (Join-Path $projectRoot '.godot/setup.log')
if ($LASTEXITCODE -ne 0) { throw 'Godot project import failed.' }
Write-Host 'Ready. Run launch.cmd.'
