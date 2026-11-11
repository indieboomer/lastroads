"""Read the exact recorded PCK; reject likeness sources AND imported payloads."""
from pathlib import Path
import hashlib,json,re,struct
ROOT=Path(__file__).resolve().parents[1]
pack=ROOT/'dist/TheLastRoads-0.13.0-Windows/TheLastRoads.pck'
with pack.open('rb') as f:
    magic,version,major,minor,patch,flags=struct.unpack('<6I',f.read(24))
    assert magic==0x43504447 and version in (2,3) and not flags&1
    f.read(8)
    if version==3: f.seek(struct.unpack('<Q',f.read(8))[0])
    else: f.read(64)
    count=struct.unpack('<I',f.read(4))[0]
    names=[]
    for _ in range(count):
        length=struct.unpack('<I',f.read(4))[0]
        names.append(f.read(length).rstrip(b'\0').decode())
        f.read(36)
for name in names:
    assert 'assets/friends/' not in name.lower(),name
    assert not re.search(r'girl[12]',name,re.I),name
payloads=[]
for source in (ROOT/'assets/friends').glob('*.import'):
    payloads+=re.findall(r'res://([^"\n]+\.(?:ctex|stex))',source.read_text(encoding='utf-8'))
for source in [ROOT/'girl1.png.import',ROOT/'girl2.png.import']:
    if source.exists(): payloads+=re.findall(r'res://([^"\n]+\.(?:ctex|stex))',source.read_text(encoding='utf-8'))
for payload in payloads:
    assert not any(payload in name for name in names),payload
assert (ROOT/'assets/friends/.gdignore').exists()
report={'result':'PASS','pack':str(pack.relative_to(ROOT)),
        'sha256':hashlib.sha256(pack.read_bytes()).hexdigest(),
        'entries_checked':len(names),'forbidden_imported_payloads_checked':len(set(payloads)),
        'friends_sources_present':False,'friends_imported_payloads_present':False}
(ROOT/'reports/trailer/likeness-audit.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
