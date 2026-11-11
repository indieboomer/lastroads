"""Install pinned official Windows export templates for the portable Godot editor."""
from pathlib import Path
import hashlib, urllib.request, zipfile
ROOT = Path(__file__).resolve().parents[1]
URL = "https://github.com/godotengine/godot-builds/releases/download/4.5.1-stable/Godot_v4.5.1-stable_export_templates.tpz"
SHA256 = "1998af37f1387684e2c211cdb483daf492fc64dc6b12096bddcdca25b6910c86"
ARCHIVE = ROOT / "tools/godot-export-templates.tpz"
DEST = ROOT / "tools/godot/editor_data/export_templates/4.5.1.stable"
NAMES = ["windows_release_x86_64.exe", "windows_debug_x86_64.exe"]
if all((DEST/name).exists() for name in NAMES):
    print("Windows templates already installed.", flush=True)
else:
    if not ARCHIVE.exists():
        print("Downloading pinned official export templates...", flush=True)
        partial = ARCHIVE.with_suffix(".partial")
        with urllib.request.urlopen(URL) as response, partial.open("wb") as output:
            while chunk := response.read(4*1024*1024): output.write(chunk)
        partial.replace(ARCHIVE)
    digest = hashlib.sha256()
    with ARCHIVE.open("rb") as source:
        while chunk := source.read(8*1024*1024): digest.update(chunk)
    if digest.hexdigest()!=SHA256: raise SystemExit("Export template archive SHA-256 mismatch.")
    DEST.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(ARCHIVE) as archive:
        for name in NAMES:
            entry = "templates/"+name
            (DEST/name).write_bytes(archive.read(entry))
            print("Installed "+name, flush=True)
    print("Template archive SHA-256 verified.", flush=True)
