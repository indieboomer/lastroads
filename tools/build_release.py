"""Build, audit, test and zip a clean Windows friends playtest."""
from pathlib import Path
import hashlib, json, os, re, shutil, struct, subprocess, sys, urllib.request, zipfile
ROOT = Path(__file__).resolve().parents[1]
VERSION = "0.17.0"
NAME = "TheLastRoads-"+VERSION+"-Windows"
OUT = ROOT/"dist"/NAME
ENGINE = ROOT/"tools/godot/Godot_v4.5.1-stable_win64_console.exe"
REPORT = ROOT/"reports"
RCEDIT = ROOT/"tools/rcedit-x64.exe"
RCEDIT_HASH = "3e7801db1a5edbec91b49a24a094aad776cb4515488ea5a4ca2289c400eade2a"
REPORT.mkdir(exist_ok=True)

def run(command, logname, cwd=ROOT, timeout=300):
    startup = subprocess.STARTUPINFO() if os.name=="nt" else None
    if startup:
        startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startup.wShowWindow = 0
    with (REPORT/(logname+"-stdout.log")).open("wb") as out, (REPORT/(logname+"-stderr.log")).open("wb") as err:
        result=subprocess.run([str(x) for x in command],cwd=cwd,stdout=out,stderr=err,timeout=timeout,startupinfo=startup)
    text=(REPORT/(logname+"-stdout.log")).read_text(encoding="utf-8",errors="replace")+(REPORT/(logname+"-stderr.log")).read_text(encoding="utf-8",errors="replace")
    if result.returncode or re.search(r"SCRIPT ERROR|ERROR:|Assertion failed",text):
        raise RuntimeError(logname+" failed (exit "+str(result.returncode)+"): "+text[-5000:])
    return text

def pck_files(path):
    with path.open("rb") as f:
        base=0
        if f.read(2)==b"MZ":
            f.seek(-12,2)
            size,tail=struct.unpack("<QI",f.read(12))
            assert tail==0x43504447
            base=f.tell()-12-size
        f.seek(base)
        magic,version,major,minor,patch,flags=struct.unpack("<6I",f.read(24))
        assert magic==0x43504447 and version in (2,3) and not flags&1
        f.read(8)
        if version==3:
            directory=struct.unpack("<Q",f.read(8))[0]
            f.seek(base+directory)
        else: f.read(64)
        count=struct.unpack("<I",f.read(4))[0]
        names=[]
        for _ in range(count):
            length=struct.unpack("<I",f.read(4))[0]
            assert length<8192
            names.append(f.read(length).rstrip(bytes([0])).decode("utf-8"))
            f.read(36)
    return names

run([sys.executable,ROOT/"tools/setup_export.py"],"release-templates")
if not RCEDIT.exists():
    with urllib.request.urlopen("https://github.com/electron/rcedit/releases/download/v2.0.0/rcedit-x64.exe") as r: RCEDIT.write_bytes(r.read())
assert hashlib.sha256(RCEDIT.read_bytes()).hexdigest()==RCEDIT_HASH
OUT.mkdir(parents=True,exist_ok=True)
exe=OUT/"TheLastRoads.exe"
run([ENGINE,"--headless","--path",ROOT,"--editor","--import","--quit"],"release-import")
run([ENGINE,"--headless","--path",ROOT,"--export-release","Windows Friends",exe],"release-export")
run([RCEDIT,exe,"--set-icon",ROOT/"assets/game-icon.ico","--set-file-version",VERSION,"--set-product-version",VERSION,"--set-version-string","ProductName","The Last Roads","--set-version-string","FileDescription","The Last Roads - Friends Playtest"],"release-resources")
pck=exe
names=pck_files(pck)
for npc in ["ilya-girl1","merchant-girl2"]:
    for suffix in ["","-portrait"]:
        asset="npc-"+npc+suffix+".png"
        assert "assets/friends/"+asset+".import" in names,asset
        assert any(n.startswith(".godot/imported/"+asset+"-") and n.endswith(".ctex") for n in names),asset
for path in names:
    clean=path.removeprefix("res://")
    assert not clean.startswith(("tools/","reports/","debug-logs/","saves/","dist/")),path
    assert not re.search(r"(?:^|/)girl[12]\.png(?:[.-]|$)",clean),path
    assert clean not in ["settings.cfg","controls.cfg","sound_asset_list.csv"],path
    assert not (clean.startswith("assets/friends/") and not re.search(r"npc-(ilya-girl1|merchant-girl2)(-portrait)?\.png(?:\.remap|\.import)?$",clean)),path
    assert not (re.search(r"girl[12]",clean,re.I) and not re.search(r"npc-(ilya-girl1|merchant-girl2)(-portrait)?\.png",clean)),path
    assert not re.search(r"img_1108",clean,re.I),path
(REPORT/"release-pck-files.json").write_text(json.dumps(names,indent=2),encoding="utf-8")
assert any("cast-atlas.png" in path for path in names),"Missing Rowan cast atlas"
assert any("woods.gd" in path for path in names),"Missing chapter controller"
licenses=OUT/"LICENSES";licenses.mkdir(exist_ok=True)
for source in (ROOT/"tools/distribution-licenses").glob("*.txt"): shutil.copy2(source,licenses/source.name)
shutil.copy2(ROOT/"assets/fonts/OFL.txt",licenses/"CINZEL_OFL.txt")
(OUT/"README.txt").write_text("""THE LAST ROADS - ROWAN MARCH PLAYTEST 0.17.0

ROADKEEPER QUALITY-OF-LIFE UPDATE
Separate rotating autosaves protect quest progress and safe exploration every
couple of active minutes. Unsafe moments, combat and menus defer automatic saves.
Your F5 manual save is never replaced by an automatic checkpoint. F9 restores
that manual save, with backup recovery if necessary. Continue journey and the
pause menu's Load latest checkpoint resume the newest valid save. Three automatic
slots and their recovery copies are kept beside the manual save.

TRACK THE SMALLER STORIES
Use Track this story in an NPC's side-story conversation, or select any discovered
unfinished story in the journal. Compass and map guide you to the next missing
trace, then the contact's current location. Both clue orders remain valid.
Show objective switches the map to the correct region. Completed stories leave
the active selector. The level-up banner now leaves the aiming reticle clear.

VISIBLE LEVELS
Level-ups show a dedicated eight-second banner with the level and new benefit.
The HUD shows your level, XP and XP remaining. New-game pacing targets level 2
at 10-15 minutes, level 3 around 30 minutes and level 4 around one hour.
Levels are earned through play, not idle time; exact timings depend on your route.
Existing saves keep their previously earned levels, XP and unlocked abilities.
Upgrade selection and the detailed progression dialog are planned for later.

THREE CONNECTED CHAPTERS
Bells of the Hollow / The Names We Carry / The Shape of a Murder
Designed toward roughly two hours with exploration and optional quests.
Playtime varies; a full human timing pass is still needed.

UPGRADE WITHOUT LOSING YOUR JOURNEY
Replace TheLastRoads.exe in your existing writable game folder.
Keep saves/, settings.cfg and controls.cfg. Do not delete your old folder.
This archive contains no player saves, preferences or original source photos.
For a fresh installation, extract into any writable folder.
No Godot installation or internet is needed. Windows 10/11, OpenGL 3.3 graphics.

QUICK CHAPTER III PREVIEW
Test-Chapter-Three.cmd starts an equipped traveller at the northern approach.
Its saves and preferences use test files under reports/; your normal journey
and settings are untouched. Launch TheLastRoads.exe normally to continue your save.

CHAPTER III
After freeing the hospice bell in Chapter II, follow the road north from
Saint Mary's Hospice to Alderwake. Hester is the coroner in the village yard.
Nera and Anselm also offer the Rowan March case button after the bell is free.
The two investigation branches can be explored in either order.
Use Hester's board to establish cause, access and motive from independent evidence.
The prison can be opened by negotiation or combat. Vent before turning the release.
Justice and the woodland pact are separate decisions, each with confirmation.
The journal includes six case tracks; cycle three map sheets with the map button.
First visit the northern travel stops on foot, then use secured road passage.

NINE WOODLAND SIDE STORIES
Ask NPCs using Off the road, or discover their traces first. Each story has two
clues that can be found in either order, and two resolutions. Adela buys the new
bog amber, mineral salts and silver wire. These stories stay available in old saves.

CHILD NPCS
Pip (eleven) at the starting inn and Nell (twelve) in Alderwake have only ordinary,
fully clothed, non-romantic interactions. Neither can enter the intimacy system.
Nell's account is optional and cannot identify the murderer or establish guilt.

CONTROLS
WASD move; mouse look; Shift sprint; Space jump; E interact.
LMB basic attack. Warrior: hold RMB to block/parry, Q heavy strike.
Cleric/Mage: RMB or Q defensive spell; C/V prepared spells.
I inventory; 1-8 quick slots; J/M journal/map; F fire; R safe rest.
L lantern; T torch; F5 save; F9 load; Esc pause; F11 fullscreen.
Controller bindings are listed in Settings / Keybindings.
Optional adult relationship invitations can be disabled in World & effects.

REPORTS
Press ` (left of 1), describe the issue, then Enter. Reports stay on your computer
unless you choose to send them. Shift+Enter adds a line; Esc cancels.

Engine: Godot 4.5.1 (MIT). Font: Cinzel (SIL Open Font License).
See LICENSES for engine, bundled third-party and font notices.
""",encoding="utf-8")
(OUT/"Test-Chapter-Three.cmd").write_text('@echo off\ncd /d "%~dp0"\nTheLastRoads.exe -- --woods-preview\n',encoding="ascii")
# Test the actual exported EXE in a separate clean folder; never zip test saves/logs.
staging=REPORT/("standalone-friends-test-"+VERSION)
staging.mkdir(exist_ok=True)
(staging/"reports").mkdir(exist_ok=True)
fixtures=staging/"reports/upgrade-fixtures";fixtures.mkdir(exist_ok=True)
for source in [ROOT/"saves/hollow-valley.json",*REPORT.glob("pre-*-player-save.json")]:
    if source.exists(): shutil.copy2(source,fixtures/source.name)
for file in [exe]: shutil.copy2(file,staging/file.name)
verified_checks=[]
for arg,marker,log in [("--safety-check","SAFETY PASS","standalone-safety"),("--journal-check","JOURNAL PASS","standalone-journal"),("--controls-check","CONTROLS PASS","standalone-controls"),("--level-check","LEVEL PASS","standalone-levels"),("--coop-check","COOP PASS","standalone-coop"),("--woods-check","WOODS PASS","standalone-woods"),("--side-quest-check","SIDE QUEST PASS","standalone-side-quests"),("--journey-check","JOURNEY PASS","standalone-journey"),("--romance-check","ROMANCE PASS","standalone-romance"),("--ranger-check","RANGER PASS","standalone-ranger"),("--inventory-check","INVENTORY PASS","standalone-inventory"),("--wilderness-check","WILDERNESS PASS","standalone-wilderness"),("--profession-check","PROFESSION PASS","standalone-profession"),("--grass-check","GRASS PASS","standalone-grass"),("--quest-access-check","QUEST ACCESS PASS","standalone-quest-access"),("--march-field-check","MARCH FIELD PASS","standalone-march-field"),("--field-check","FIELD PASS","standalone-field"),("--architecture-check","ARCHITECTURE PASS","standalone-architecture"),("--release-check","RELEASE CHECK PASS","standalone-release"),("--smoke","SMOKE PASS","standalone-smoke"),("--sound-check","SOUND PASS","standalone-sound")]:
    if "--playtest-checks" in sys.argv and arg not in ["--safety-check","--journal-check","--controls-check","--level-check","--coop-check","--woods-check","--side-quest-check","--journey-check","--smoke"]: continue
    if "--level-checks" in sys.argv and arg not in ["--level-check","--ranger-check","--profession-check","--smoke"]: continue
    if "--rowan-checks" in sys.argv and arg not in ["--coop-check","--woods-check","--side-quest-check","--journey-check","--romance-check","--smoke","--sound-check"]: continue
    if "--verify-audio" in sys.argv and arg not in ["--ranger-check","--march-field-check","--release-check","--sound-check"]: continue
    text=run([staging/exe.name,"--log-file",staging/"reports"/(log+".log"),"--",arg],log,cwd=staging,timeout=240)
    assert marker in text,text[-1000:]
    verified_checks.append(marker)
    print(next(line for line in text.splitlines() if marker in line),flush=True)
allowed={"TheLastRoads.exe","README.txt","Test-Chapter-Three.cmd"}
assert {p.name for p in OUT.iterdir()}==allowed|{"LICENSES"},"Unexpected files in clean release directory"
archive=ROOT/"dist"/(NAME+".zip")
with zipfile.ZipFile(archive,"w",zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for file in sorted(OUT.rglob("*")):
        if file.is_file(): z.write(file,Path(NAME)/file.relative_to(OUT))
assert zipfile.ZipFile(archive).testzip() is None
# Refresh the legacy top-level launcher too; it previously embedded an older PCK.
legacy = ROOT/"dist"/(NAME+".exe")
if legacy.exists():
    shutil.copy2(exe, legacy)
    # The current EXE embeds its own game data.
metadata={"build":"0.17.0-roadkeepers","platform":"Windows x86_64 / GL Compatibility","zip":str(archive.relative_to(ROOT)),"zip_bytes":archive.stat().st_size,"sha256":hashlib.sha256(archive.read_bytes()).hexdigest(),"pck_entries":len(names),"checks":verified_checks+["PCK excludes source photos, tools, reports, saves and preferences","ZIP CRC validation"],"source_photos_included":False,"developer_saves_included":False}
(REPORT/"distribution-validation.json").write_text(json.dumps(metadata,indent=2),encoding="utf-8")
(ROOT/"dist"/(NAME+".sha256")).write_text(metadata["sha256"]+"  "+archive.name+"\n",encoding="ascii")
print("DISTRIBUTION PASS: "+str(archive)+" / "+str(round(archive.stat().st_size/1024**2,1))+" MiB",flush=True)

