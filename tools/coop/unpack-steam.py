"""Extract only the pinned Windows Steam runtime files into the requested directory."""
from pathlib import Path
import sys
import tarfile

archive, destination = map(Path, sys.argv[1:])
destination = destination.resolve()
destination.mkdir(parents=True, exist_ok=True)
allowed = {"godotsteam.452.editor.win64.exe", "godotsteam.452.editor.win64.console.exe", "steam_api64.dll"}
with tarfile.open(archive) as source:
    for member in source.getmembers():
        assert member.isfile() and member.name in allowed
        target = (destination / member.name).resolve()
        assert target.parent == destination
        target.write_bytes(source.extractfile(member).read())
