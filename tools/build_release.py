"""Build, audit, test and zip a clean Windows friends playtest."""
from pathlib import Path
import hashlib, json, os, re, shutil, struct, subprocess, sys, urllib.request, zipfile
ROOT = Path(__file__).resolve().parents[1]
VERSION = "0.14.2"
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
licenses=OUT/"LICENSES";licenses.mkdir(exist_ok=True)
for source in (ROOT/"tools/distribution-licenses").glob("*.txt"): shutil.copy2(source,licenses/source.name)
shutil.copy2(ROOT/"assets/fonts/OFL.txt",licenses/"CINZEL_OFL.txt")
(OUT/"README.txt").write_text("""THE LAST ROADS - FRIENDS PLAYTEST 0.14.2

Extract the ZIP contents into your EXISTING game folder, replacing TheLastRoads.exe (all game data is now embedded).
Keep your saves/ folder, settings.cfg and controls.cfg. The archive includes no player saves or preferences and will not overwrite them.
Do not delete the old game folder. Launch TheLastRoads.exe and choose Continue.
For a fresh install, extract into any writable folder.
This EXE includes all game data and sounds. An older adjacent PCK is not required.
No Godot installation or internet is needed.
Windows 10/11 64-bit, with an OpenGL 3.3-capable graphics driver.

Fresh-install defaults: fullscreen; Retro look ON; Copper & Pine; Fine pixel detail;
dithering 50%; paper grain 30%. F11 switches fullscreen/windowed.
Existing saved preferences are preserved if you update an older folder.

Start a New Journey and create your character. Talk to Mara beside the inn.
Authorized friend-based artwork and portraits are used for Ilya at the Fallen Toll and Adela the
travelling trader beside Northwatch. Follow the road quests to meet them.

New in 0.14.2: game data embedded in the EXE; direct supplied MP3 footsteps.

New in 0.14.2: pistol and musket cartridges are also sold by Ilya, Captain Rook,
Lucan and Garran through the Paper cartridges conversation button.

New in 0.14.2: supplied pistol_shot and musket_shot recordings; shared
flintlock_reload for both firearms; supplied sword recordings for the ranger dagger.

New in 0.13: massively denser grass covers fields and forest ground by default.
Settings > World & effects > Dense grass coverage switches to lighter grass.
Mushrooms, fruit bushes and dry firewood retain clear, readable pickup patches.

Earlier fixes: visible E prompts on bridge/orchard votives, sickbeds, tablets
and bell; clearer tracked quest/completion states and Nera friendship access.

Earlier fixes: timber bridge footsteps, clean doorstep joins, grounded crosses,
closed road junction gaps, no flat patient decals, and repeatable Nera aftermath.

Earlier fixes: harvested berry bushes disappear and stay gone after reload;
NPC boots clear raised roads; pine tree-0 has a gentler, coherent trunk.

New in 0.12: straighter autumn oak; Renaissance-inspired arched entrances,
weathered limewash/brickwork, darker timber, brocade rugs, carved furniture,
milling equipment, supplies and lanterns. Includes current ranger/firearm, cartridge and smoke improvements.

WASD move; mouse look; Shift sprint; Space jump; E interact.
LMB basic attack. Warrior: hold RMB to block/parry, Q heavy strike.
Cleric/Mage: RMB or Q defensive spell; C/V prepared spells.
I inventory; 1-8 quick slots; J/M journal/map; F fire; R safe rest.
L lantern; T torch; F5 save; F9 load; Esc pause; F11 fullscreen.
Settings includes graphics styles, tree/wind options and separate sound/music levels.

REPORT A PROBLEM: press ` (the key left of 1). The game pauses.
Describe the problem and press Enter. Send the created debug-logs subfolder
back to the project owner: it contains your note, screenshot and game state.
Shift+Enter adds a line; Esc cancels. Reports stay on your computer until you send them.

Saves are in saves/hollow-valley.json beside the EXE; preferences in settings.cfg and control bindings in controls.cfg.
This archive starts fresh and contains no developer progress or original reference photos.
The playable prototype has two connected chapters, approximately one hour of content.
Optional non-explicit relationship invitations can be disabled in World & effects settings.

Engine: Godot 4.5.1 (MIT). Font: Cinzel (SIL Open Font License).
See LICENSES for engine, bundled third-party and font notices.
""",encoding="utf-8")
# Test the actual exported EXE in a separate clean folder; never zip test saves/logs.
staging=REPORT/("standalone-friends-test-"+VERSION)
staging.mkdir(exist_ok=True)
(staging/"reports").mkdir(exist_ok=True)
fixtures=staging/"reports/upgrade-fixtures";fixtures.mkdir(exist_ok=True)
for source in [ROOT/"saves/hollow-valley.json",*REPORT.glob("pre-*-player-save.json")]:
    if source.exists(): shutil.copy2(source,fixtures/source.name)
for file in [exe]: shutil.copy2(file,staging/file.name)
for arg,marker,log in [("--ranger-check","RANGER PASS","standalone-ranger"),("--inventory-check","INVENTORY PASS","standalone-inventory"),("--wilderness-check","WILDERNESS PASS","standalone-wilderness"),("--profession-check","PROFESSION PASS","standalone-profession"),("--grass-check","GRASS PASS","standalone-grass"),("--quest-access-check","QUEST ACCESS PASS","standalone-quest-access"),("--march-field-check","MARCH FIELD PASS","standalone-march-field"),("--field-check","FIELD PASS","standalone-field"),("--architecture-check","ARCHITECTURE PASS","standalone-architecture"),("--release-check","RELEASE CHECK PASS","standalone-release"),("--smoke","SMOKE PASS","standalone-smoke"),("--sound-check","SOUND PASS","standalone-sound")]:
    if "--verify-audio" in sys.argv and arg not in ["--ranger-check","--march-field-check","--release-check","--sound-check"]: continue
    text=run([staging/exe.name,"--log-file",staging/"reports"/(log+".log"),"--",arg],log,cwd=staging,timeout=240)
    assert marker in text,text[-1000:]
    print(next(line for line in text.splitlines() if marker in line),flush=True)
allowed={"TheLastRoads.exe","README.txt"}
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
metadata={"build":"0.14.2-friends-current","platform":"Windows x86_64 / GL Compatibility","zip":str(archive.relative_to(ROOT)),"zip_bytes":archive.stat().st_size,"sha256":hashlib.sha256(archive.read_bytes()).hexdigest(),"pck_entries":len(names),"checks":["PCK excludes source photos, tools, reports, saves and preferences","Fresh defaults: fullscreen, Copper & Pine, Fine, dither 50%, grain 30%", "Standalone authorized friend NPC bodies/portraits, current ranger/inventory/wilderness/profession content, sound loading, save/load and diagnostics","Standalone harvested-bush persistence, road boot clearance and oblique pine views","Standalone building collision and rendered architecture","Standalone March field reports: timber contact audio, grounded crosses, road caps, removed patient decals and repeatable Nera aftermath","Standalone quest access: exact bridge camera, normal E progression, all authored shrine/bed/tablet/bell targets, faith completion/save-load and Nera friendship","Standalone dense grass: default-on/legacy preferences, persistent checkbox, all pickup clearings, field captures and performance samples","Standalone gameplay smoke","Standalone sound/settings suite","ZIP CRC validation"],"source_photos_included":False,"developer_saves_included":False}
(REPORT/"distribution-validation.json").write_text(json.dumps(metadata,indent=2),encoding="utf-8")
(ROOT/"dist"/(NAME+".sha256")).write_text(metadata["sha256"]+"  "+archive.name+"\n",encoding="ascii")
print("DISTRIBUTION PASS: "+str(archive)+" / "+str(round(archive.stat().st_size/1024**2,1))+" MiB",flush=True)

