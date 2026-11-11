"""Reproduce the approved Sector asegurado cristal cue verbatim."""
import json
from array import array
from pathlib import Path
import math, random, wave
SR=44100; D=1.6; N=int(SR*D); T=2*math.pi
left=array('f',[0])*N;right=array('f',[0])*N
rng=random.Random(179)
def bell(start,freq,gain,pan,duration=.95):
 for j in range(int(duration*SR)):
  i=int(start*SR)+j
  if i>=N:break
  t=j/SR;u=t/duration
  env=(1-math.exp(-t*160))*math.exp(-t*5.8)*min(1,(duration-t)/.16)
  sample=(math.sin(T*freq*t)+.12*math.sin(T*freq*2*t)*math.exp(-t*9)+.035*math.sin(T*freq*3*t)*math.exp(-t*12))*env*gain
  left[i]+=sample*math.sqrt((1-pan)/2);right[i]+=sample*math.sqrt((1+pan)/2)
# Quiet energy swell, then a rounded harmonic confirmation.
lp=0
for i in range(int(SR*.48)):
 t=i/SR;u=t/.48;lp=.96*lp+.04*rng.uniform(-1,1)
 env=math.sin(math.pi*u)**2
 tone=math.sin(T*(170*t+85*t*t))*.025
 left[i]+=(lp*.10+tone)*env;right[i]+=(lp*.08+tone)*env
for start,f,g,p in [(0.08,659.255,.19,-.22),(.19,830.609,.15,0),(.32,987.767,.15,.22),(.40,1318.51,.055,.12)]:bell(start,f,g,p)
# Spacious, short reflections, no metallic distortion.
a=array('f',left);b=array('f',right)
for delay,g in [(.073,.12),(.139,.075),(.221,.04)]:
 k=int(delay*SR)
 for i in range(k,N):left[i]+=b[i-k]*g;right[i]+=a[i-k]*g
peak=max(max(map(abs,left)),max(map(abs,right)));gain=.56/peak
pcm=array('h')
for i in range(N):
 fade=min(1,i/(SR*.008),(N-1-i)/(SR*.2))
 for sample in (left[i],right[i]):pcm.append(int(sample*gain*fade*32767))
root=Path(__file__).resolve().parents[2]/'assets/audio'
manifest=json.loads((root/'manifest.json').read_text())
for name in ('zone_1','zone_2','zone_3'):
 p=root/'sfx'/(name+'.wav')
 with wave.open(str(p),'wb') as f:
  f.setnchannels(2);f.setsampwidth(2);f.setframerate(SR);f.writeframes(pcm.tobytes())
 for item in manifest:
  if item['file']=='sfx/'+name+'.wav':
   item.update(seconds=D,bytes=p.stat().st_size,source='Original synthesis, approved Sector asegurado cristal preview')
(root/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
