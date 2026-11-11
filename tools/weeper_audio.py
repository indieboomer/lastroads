"""Original synthesized temporary cues: formant lament, low tone, and breath.
Replace with performed female vocals during final sound production.
"""
from pathlib import Path
import numpy as np
import wave

out=Path('assets/wilderness/weeper/audio'); out.mkdir(parents=True,exist_ok=True)
sr=24000
rng=np.random.default_rng(721)
for name,duration in [('lament',5.8),('windup',1.15),('scream',1.0),('sweep',.65),('death',2.5)]:
    t=np.arange(int(sr*duration))/sr
    f=235+18*np.sin(t*1.2)+3*np.sin(t*2*np.pi*5.2)
    if name=='death': f=250-100*t/duration
    if name=='scream': f=325+22*np.sin(t*7)
    phase=2*np.pi*np.cumsum(f)/sr
    voice=np.zeros_like(t)
    for harmonic in range(1,26):
        hz=f*harmonic
        weight=sum(np.exp(-.5*((hz-center)/spread)**2)*level for center,spread,level in [(650,160,1),(1180,200,.6),(2600,300,.25)])
        voice+=np.sin(phase*harmonic)*weight/(harmonic**.7)
    low=.19*np.sin(2*np.pi*78*t)+.08*np.sin(2*np.pi*116*t)
    breath=rng.normal(0,.035,len(t))
    pulse=.55+.45*np.sin(np.pi*np.minimum(t/duration*1.3,1))**2
    env=np.minimum(t/.18,1)*np.minimum((duration-t)/.5,1)
    if name=='windup': voice*=np.linspace(.02,.55,len(t)); breath*=5
    if name=='sweep': voice*=0; low*=.3; breath*=8
    sound=(voice*pulse+low+breath)*np.maximum(env,0)
    sound*=.62/max(abs(sound))
    with wave.open(str(out/(name+'.wav')),'wb') as stream:
        stream.setnchannels(1);stream.setsampwidth(2);stream.setframerate(sr)
        stream.writeframes((sound*32767).astype('<i2').tobytes())
print('Five original synthesized Weeper cues written')
