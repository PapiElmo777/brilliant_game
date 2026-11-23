"""Reproduce the approved original Imperial finale verbatim."""
import json
from array import array
from pathlib import Path
import math,random,wave
SR=44100;D=5.8;N=int(SR*D);TAU=math.tau
L=array('f',[0])*N;R=array('f',[0])*N;rng=random.Random(91)
def add(start,data,gain=1,pan=0):
 offset=int(start*SR);a=math.sqrt((1-pan)/2)*gain;b=math.sqrt((1+pan)/2)*gain
 for j,x in enumerate(data):
  i=offset+j
  if i<N:L[i]+=x*a;R[i]+=x*b
def brass(start,f,dur,gain=.15,pan=0):
 data=array('f')
 for i in range(int(dur*SR)):
  t=i/SR;env=(1-math.exp(-t*45))*min(1,(dur-t)/.22)*math.exp(-t*.55)
  # Rounded, low brass and a restrained chorus.
  x=math.sin(TAU*f*t)+.32*math.sin(TAU*f*2*t)+.12*math.sin(TAU*f*3*t)+.045*math.sin(TAU*f*4*t)
  x+=.16*math.sin(TAU*f*1.003*t)
  data.append(x*env)
 add(start,data,gain,pan)
def drum(start,gain=.18,bright=False):
 data=array('f');phase=0;lp=0
 for i in range(int(.65*SR)):
  t=i/SR;lp=.87*lp+.13*rng.uniform(-1,1);phase+=TAU*(43+42*math.exp(-t*20))/SR
  env=(1-math.exp(-t*650))*math.exp(-t*9)*min(1,(.65-t)/.08)
  x=math.sin(phase)*.8+lp*(1.3 if bright else .65)
  data.append(x*env)
 add(start,data,gain)
# An original short ceremonial motif: grounded bass, compact ascent, dark cadence.
for start in [.12,.73,1.34,2.25,2.86]:drum(start,.19)
for start in [1.80,1.97,3.30,3.44]:drum(start,.065,True)
for t,f,d in [(.12,146.832,.43),(.73,164.814,.43),(1.34,174.614,.72),(2.25,130.813,.43),(2.86,138.591,.43),(3.52,146.832,1.72)]:
 brass(t,f,d,.11,-.12);brass(t,f/2,d,.13,.12)
# Final minor chord and a low energy tail.
for f,p in [(73.416,-.3),(146.832,.15),(174.614,-.15),(220,.3)]:brass(3.52,f,1.9,.047,p)
drum(3.52,.25)
lp=0;energy=array('f')
for i in range(int(1.65*SR)):
 t=i/SR;lp=.975*lp+.025*rng.uniform(-1,1)
 env=(1-math.exp(-t*110))*math.exp(-t*3.4)*min(1,(1.65-t)/.2)
 energy.append((lp*.8+math.sin(TAU*36*t)*.12)*env)
add(3.52,energy,.20)
a=array('f',L);b=array('f',R)
for delay,g in [(.061,.13),(.127,.09),(.231,.06),(.347,.035)]:
 k=int(delay*SR)
 for i in range(k,N):L[i]+=b[i-k]*g;R[i]+=a[i-k]*g
peak=max(max(map(abs,L)),max(map(abs,R)));gain=.73/peak;pcm=array('h')
for i in range(N):
 fade=min(1,i/(SR*.015),(N-1-i)/(SR*.38))
 for x in (L[i],R[i]):pcm.append(int(x*gain*fade*32767))
root=Path(__file__).resolve().parents[2]/'assets/audio'
manifest=json.loads((root/'manifest.json').read_text())
for name in ('victory','podium','finish'):
 p=root/'sfx'/(name+'.wav')
 with wave.open(str(p),'wb') as f:
  f.setnchannels(2);f.setsampwidth(2);f.setframerate(SR);f.writeframes(pcm.tobytes())
 for item in manifest:
  if item['file']=='sfx/'+name+'.wav':
   item.update(seconds=D,bytes=p.stat().st_size,source='Original synthesis, approved Cierre imperial original preview')
(root/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
