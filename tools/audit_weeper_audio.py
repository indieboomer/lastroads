"""Measure supplied MP3 cue bounds without modifying the recordings."""
from pathlib import Path
import subprocess
import json
import numpy as np

report={}
for source in sorted(Path('sounds/weeper').glob('*.mp3')):
    raw=subprocess.run(['ffmpeg','-v','error','-i',str(source),'-f','f32le','-ac','1','-ar','24000','pipe:1'],capture_output=True,check=True).stdout
    samples=np.frombuffer(raw,dtype='<f4')
    size=240
    rms=np.sqrt(np.mean(samples[:len(samples)//size*size].reshape(-1,size)**2,axis=1))
    audible=np.flatnonzero(rms>max(.003,float(rms.max())*.025))
    assert len(audible),source
    start=max(0,int(audible[0])*.01-.035)
    end=min(len(samples)/24000,(int(audible[-1])+1)*.01+.10)
    report[source.name]={'offset':round(start,4),'end':round(end,4),'duration':round(len(samples)/24000,4),'peak':round(float(np.max(np.abs(samples))),5)}
Path('assets/audio/weeper-recordings.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
Path('reports/weeper/supplied-audio-audit.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
