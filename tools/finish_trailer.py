"""Mix project soundtrack/SFX and finish the 45-second in-engine trailer."""
from pathlib import Path
import json, subprocess, wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'reports/trailer'
RATE = 48000
N = RATE * 45
rng = np.random.default_rng(114)

def decode(path, seconds=45, offset=0):
    result = subprocess.run(['ffmpeg','-v','error','-ss',str(offset),'-i',str(path),'-t',str(seconds),'-f','f32le','-ac','2','-ar',str(RATE),'-'],capture_output=True,check=True)
    return np.frombuffer(result.stdout,dtype='<f4').reshape(-1,2).copy()

def put(dest, sound, at, gain=1, fade=.02):
    sound = sound.copy() * gain
    count = min(int(fade*RATE), len(sound)//2)
    if count:
        sound[:count] *= np.linspace(0,1,count)[:,None]
        sound[-count:] *= np.linspace(1,0,count)[:,None]
    start = round(at*RATE)
    length = min(len(sound),len(dest)-start)
    if length>0: dest[start:start+length] += sound[:length]

def write(name, data):
    data = np.clip(data,-.98,.98)
    with wave.open(str(OUT/name),'wb') as f:
        f.setnchannels(2); f.setsampwidth(2); f.setframerate(RATE)
        f.writeframes((data*32767).astype('<i2').tobytes())

music = np.zeros((N,2),np.float32)
fx = np.zeros_like(music)
put(music,decode(ROOT/'music/night_ambient.mp3',5),0,.52,.2)
put(music,decode(ROOT/'music/battle_music.mp3',34.5,12),5,.63,.35)
put(music,decode(ROOT/'music/main_menu_music.mp3',5.5,24),39.5,.65,.45)

cuts = [0,2,3.3,5,8.5,12,15,18,20.5,23,25.5,28,30,32.5,34,36,39.5]
for at in cuts:
    duration=1.1
    t=np.arange(int(duration*RATE))/RATE
    phase=2*np.pi*(47*t+38*.09*(1-np.exp(-t/.09)))
    hit=(np.sin(phase)*np.exp(-t*6)+rng.normal(0,.10,len(t))*np.exp(-t*24))*.34
    put(fx,np.column_stack((hit,hit)),at,1,.004)
    if at>0:
        t=np.arange(int(.32*RATE))/RATE
        noise=rng.normal(0,1,len(t))
        noise=np.convolve(noise,np.ones(12)/12,mode='same')
        whoosh=noise*np.linspace(0,.24,len(t))**1.2
        put(fx,np.column_stack((whoosh,whoosh[::-1])),at-.32,1,.01)

events=[(0,'warden_windup_01',.75),(2,'crypt_interior',.2),(3.35,'thunder_02',.4),
        (5,'campfire',.15),(12,'forest_night',.16),(15,'wraith_windup_01',.6),
        (18,'crypt_interior',.23),(20.6,'sword_hit_01',.65),
        (21.5,'shield_parry_01',.5),(23.1,'ember_cast_01',.65),
        (24.0,'ember_hit_01',.65),(25.6,'rime_cast_01',.65),
        (26.5,'rime_hit_01',.6),(28.1,'wraith_windup_02',.55),
        (30,'warden_windup_02',.7),(32.5,'dart_cast_01',.65),
        (34.1,'ember_hit_02',.65),(36,'quest_complete',.42),(39.5,'quest_discovery',.32)]
for at,name,gain in events:
    sound=decode(ROOT/'sounds'/f'{name}.mp3',min(5,45-at))
    put(fx,sound,at,gain,.04)

# Match the repeatable in-engine spell choreography.
combat_ranges=[(0,2),(3.3,5),(20.5,36)]
for frame in range(5,1080,24):
    at=frame/30
    if any(a<=at<b for a,b in combat_ranges):
        kind=['ember','rime','dart'][(frame//24)%3]
        put(fx,decode(ROOT/'sounds'/f'{kind}_cast_01.mp3',1.2),at,.22,.015)

endfade=np.ones(N,np.float32)
endfade[-int(1.5*RATE):]=np.linspace(1,0,int(1.5*RATE))
music*=endfade[:,None]; fx*=endfade[:,None]
mix=music+fx
peak=float(np.max(np.abs(mix)))
gain=min(1,.94/max(peak,.001))
music*=gain;fx*=gain;mix*=gain
write('music-stem.wav',music)
write('effects-stem.wav',fx)
write('mix-no-voice.wav',mix)
duck=np.ones(N,np.float32)
for a,b in [(0.2,1.9),(3.3,4.9),(8.5,11.5),(15,17.8),(20.5,27.5),(30,32.4),(36,38.6),(40,43.2)]:
    start=int(a*RATE);end=int(b*RATE)
    duck[start:end]=.55
    ramp=int(.12*RATE)
    duck[max(0,start-ramp):start]=np.linspace(1,.55,min(ramp,start))
    duck[end:min(N,end+ramp)]=np.linspace(.55,1,min(ramp,N-end))
write('mix-for-narrator.wav',mix*duck[:,None])

for source,target,duration in [('picture-master.avi','part-one.avi','36'),('ending.avi','part-two.avi','9')]:
    subprocess.run(['ffmpeg','-v','error','-y','-i',str(OUT/source),'-map','0:v:0','-t',duration,'-c:v','copy',str(OUT/target)],check=True)
(OUT/'picture.ffconcat').write_text("ffconcat version 1.0\nfile 'part-one.avi'\nduration 36\nfile 'part-two.avi'\nduration 9\n",encoding='utf-8')
cmd=['ffmpeg','-hide_banner','-y','-f','concat','-safe','0','-i',str(OUT/'picture.ffconcat'),'-i',str(OUT/'mix-no-voice.wav'),
     '-vf','scale=1920:1080:flags=lanczos,setsar=1',
     '-map','0:v:0','-map','1:a:0','-t','45','-r','30',
     '-c:v','libx264','-preset','slow','-crf','17','-pix_fmt','yuv420p','-c:a','aac','-b:a','320k',
     '-af','loudnorm=I=-16:TP=-1.5:LRA=9','-ar','48000','-movflags','+faststart',str(OUT/'The-Last-Roads-Trailer-45s.mp4')]
subprocess.run(cmd,check=True)
probe=json.loads(subprocess.check_output(['ffprobe','-v','error','-show_streams','-show_format','-of','json',str(OUT/'The-Last-Roads-Trailer-45s.mp4')]))
video=next(s for s in probe['streams'] if s['codec_type']=='video')
audio=next(s for s in probe['streams'] if s['codec_type']=='audio')
assert int(video['nb_frames'])==1350,video
assert abs(float(video['duration'])-45)<.04,video
assert (video['width'],video['height'])==(1920,1080)
assert audio['sample_rate']=='48000'
(OUT/'video-validation.json').write_text(json.dumps(probe,indent=2),encoding='utf-8')
metadata={'duration_seconds':45,'fps':30,'output':'1920x1080','render':'2560x1440 in-engine, downsampled',
          'look':{'preset':'Copper & Pine','dither':.5,'grain':.3,'detail':'Fine'},
          'source_pack':'dist/TheLastRoads-0.13.0-Windows/TheLastRoads.pck','voice_recorded':False,
          'soundtrack':'Existing project music and sound effects, plus generated transition percussion',
          'picture':'Choreographed in-engine camera and encounters; no external cinematic footage'}
(OUT/'delivery.json').write_text(json.dumps(metadata,indent=2),encoding='utf-8')
