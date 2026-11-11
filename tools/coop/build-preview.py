"""Pack a separate Steam-capable co-op playtest without touching older builds or saves."""
from pathlib import Path
import hashlib
import json
import re
import shutil
import struct
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "dist/TheLastRoads-0.15.5-Coop-Preview"
ENGINE = ROOT / "tools/godot-steam/godotsteam.452.editor.win64.console.exe"
REPORT = ROOT / "reports/coop"
OUT.mkdir(parents=True, exist_ok=True)

def run(args, label):
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    result = subprocess.run([str(a) for a in args], cwd=ROOT, capture_output=True, startupinfo=startup, timeout=300)
    log = result.stdout.decode("utf-8", errors="replace") + result.stderr.decode("utf-8", errors="replace")
    (REPORT / (label + ".log")).write_text(log, encoding="utf-8")
    assert result.returncode == 0 and not re.search(r"SCRIPT ERROR|ERROR:|Assertion failed", log), log[-5000:]

run([ENGINE, "--headless", "--path", ROOT, "--editor", "--import", "--quit"], "preview-import")
pack = OUT / "TheLastRoads.pck"
run([ENGINE, "--headless", "--path", ROOT, "--export-pack", "Windows Friends", pack], "preview-export")

# Audit the PCK directory. Original friend photos and generation metadata never ship.
with pack.open("rb") as source:
    magic, version, major, minor, patch, flags = struct.unpack("<6I", source.read(24))
    assert magic == 0x43504447 and version in (2, 3) and not flags & 1
    source.read(8)
    if version == 3:
        directory, = struct.unpack("<Q", source.read(8))
        source.seek(directory)
    else:
        source.read(64)
    count, = struct.unpack("<I", source.read(4))
    names = []
    for _ in range(count):
        length, = struct.unpack("<I", source.read(4))
        names.append(source.read(length).rstrip(b"\0").decode("utf-8"))
        source.read(36)
for name in names:
    clean = name.removeprefix("res://")
    assert not clean.startswith(("tools/", "reports/", "debug-logs/", "saves/", "dist/")), name
    assert clean not in ("settings.cfg", "controls.cfg", "steam_appid.txt"), name
    assert not re.search(r"(?:^|/)girl[12]\.png(?:[.-]|$)|img_1108|generation.*\.json$", clean, re.I), name
for origin in ("valdren", "shenari", "nambari", "dwarf", "elf", "ogre"):
    for profession in ("warrior", "mage", "cleric", "ranger"):
        name = f"assets/coop/ready/{origin}-{profession}.png.import"
        assert name in names, name
        assert f"assets/coop/{origin}-{profession}.png.import" not in names
        assert f"assets/coop/ready/female/{origin}-{profession}.png.import" in names
        assert f"assets/coop/female/{origin}-{profession}.png.import" not in names
for file in (ROOT / "sounds/weeper").glob("*.mp3"):
    assert "sounds/weeper/"+file.name+".import" in names, file.name
(REPORT / "preview-pck-files.json").write_text(json.dumps(names, indent=2), encoding="utf-8")

runtime = OUT / "runtime"
runtime.mkdir(exist_ok=True)
for name in ("godotsteam.452.editor.win64.exe", "godotsteam.452.editor.win64.console.exe", "steam_api64.dll"):
    shutil.copy2(ROOT / "tools/godot-steam" / name, runtime / name)
(OUT / "Play.cmd").write_text('@echo off\ncd /d "%~dp0"\nstart "" "runtime\\godotsteam.452.editor.win64.exe" --main-pack "%~dp0TheLastRoads.pck" --log-file "debug-logs/coop-%RANDOM%-%RANDOM%.log" %*\n', encoding="utf-8")
shutil.copy2(ROOT / "tools/coop/launch-local.ps1", OUT / "local-coop.ps1")
(OUT / "Test-Local-Coop.cmd").write_text('@echo off\ncd /d "%~dp0"\npowershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0local-coop.ps1" -GameRoot "%~dp0."\n', encoding="utf-8")
app_id_file = OUT / "steam_appid.txt"
if not app_id_file.exists(): app_id_file.write_text("480\n", encoding="ascii")
shutil.copy2(ROOT / "tools/coop/README.txt", OUT / "README.txt")
with (OUT / "README.txt").open("a", encoding="utf-8") as file:
    file.write("\nHOLLOW WEEPER (0.15.3)\nEncounter both the Pitchbound and Boughstalker, then explore farther into\nthe forest. A solitary Old Faith guardian waits at an offering site. Listen\nfor weeping; retreat is possible. Her scream can be sidestepped or blocked\nby solid cover. Iron is strongly resisted; magic, sacred attacks and\nGraveward resin work better. All 15 supplied Weeper recordings are integrated; the guardian is 20 percent larger.\n")
    file.write("\nPACKAGED PREVIEW\nRun Play.cmd in this folder. Steam test App ID 480 is already configured.\nThe runtime is included; no Godot installation is needed. The development\nfile paths above describe the source project, not files in this package.\n")
licenses = OUT / "LICENSES"
licenses.mkdir(exist_ok=True)
for source in (ROOT / "tools/distribution-licenses").glob("*.txt"):
    shutil.copy2(source, licenses / source.name)
shutil.copy2(ROOT / "assets/fonts/OFL.txt", licenses / "CINZEL_OFL.txt")
archive = OUT.parent / (OUT.name + ".zip")
allowed = [pack, OUT / "Play.cmd", OUT / "Test-Local-Coop.cmd", OUT / "local-coop.ps1", OUT / "README.txt", *runtime.iterdir(), *licenses.iterdir()]
with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as output:
    output.writestr(OUT.name + "/steam_appid.txt", "480\n")
    for source in allowed:
        output.write(source, OUT.name + "/" + source.relative_to(OUT).as_posix())
report = {"folder":str(OUT),"archive":str(archive),"bytes":archive.stat().st_size,"sha256":hashlib.sha256(archive.read_bytes()).hexdigest(),"runtime":"GodotSteam 4.24 / Godot 4.5.2","steam_app_id":480,"steam_invite_live_test":False,"pack_files":len(names)}
(REPORT / "preview-build.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
print(json.dumps(report, indent=2))
