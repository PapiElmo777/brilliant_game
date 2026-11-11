"""Reproducible original soundtrack derived from Brilliant's first voiceless demo.
No external samples or voices. Python standard library only.
"""
from array import array
from pathlib import Path
import math, random, wave, json
OUT=Path(__file__).resolve().parents[1]/'assets/audio'
SR=22050; TAU=2*math.pi
rng=random.Random(119)
N=0; L=array('f'); R=array('f')
def mix(data,start,gain=1.0,pan=0.0):
    offset=int(start*SR); a=math.cos((pan+1)*math.pi/4)*gain; b=math.sin((pan+1)*math.pi/4)*gain
    for j,x in enumerate(data):
        i=offset+j
        if 0 <= i < N: L[i]+=x*a; R[i]+=x*b

def note(freq,dur,kind='bell',gain=.1,pan=0,start=0):
    count=int(dur*SR); data=array('f'); phase=0.0
    for i in range(count):
        t=i/SR; u=i/max(count-1,1); phase+=TAU*freq/SR
        if kind=='pad':
            env=min(t/.85,1)*min((dur-t)/1.4,1)
            vibr=.004*math.sin(TAU*.19*t)
            x=(math.sin(phase+vibr)+.25*math.sin(phase*2.002)+.12*math.sin(phase*3.001)+.07*math.sin(phase*.999))*.66
            x*=env*(.9+.1*math.sin(TAU*.11*t))
        elif kind=='brass':
            env=(1-math.exp(-t*35))*math.exp(-t*.9)*min((dur-t)/.20,1)
            x=(math.sin(phase+.23*math.sin(phase*2))+.32*math.sin(2*phase)+.13*math.sin(3*phase))*.7*env
        else:
            env=min(t/.006,1)*math.exp(-t*(5 if kind=='bell' else 14))*min((dur-t)/.025,1)
            x=(math.sin(phase)+.22*math.sin(phase*2.01)+.08*math.sin(phase*3.99))*.75*env
        data.append(x)
    mix(data,start,gain,pan)

def chord(freqs,start,dur,gain=.024,kind='pad'):
    for j,freq in enumerate(freqs): note(freq,dur,kind,gain,(-.75+1.5*j/max(len(freqs)-1,1)),start)

def motif(start,gain=.12,tempo=.29,octave=1,kind='bell'):
    for j,f in enumerate([293.665,349.228,440.0]): note(f*octave,1.25,kind,gain,(-.32+j*.32),start+j*tempo)

def chirp(start,f0=900,f1=1800,dur=.14,gain=.1,pan=0):
    data=array('f'); phase=0
    for i in range(int(SR*dur)):
        t=i/SR; u=t/dur; phase+=TAU*(f0+(f1-f0)*u)/SR
        env=math.sin(math.pi*u)**1.5
        data.append(math.sin(phase+.25*math.sin(phase*2))*env)
    mix(data,start,gain,pan)

def whoosh(start,dur=1.2,gain=.17,reverse=False):
    data=array('f'); lp=0; phase=0
    for i in range(int(SR*dur)):
        u=i/(SR*dur); p=1-u if reverse else u
        lp=.93*lp+.07*rng.uniform(-1,1)
        phase+=TAU*(100+350*p*p)/SR
        env=math.sin(math.pi*u)**.8
        data.append((lp*2.5+.15*math.sin(phase)) * env * (.25+.75*p))
    mix(data,start,gain,-.45); mix(data,start+.025,gain*.7,.5)

def impact(start,gain=.29):
    data=array('f'); lp=0; phase=0; dur=1.5
    for i in range(int(SR*dur)):
        t=i/SR; phase+=TAU*(37+55*math.exp(-t*8))/SR
        lp=.90*lp+.10*rng.uniform(-1,1)
        env=min(t/.004,1)*math.exp(-t*4.5)*min((dur-t)/.1,1)
        x=(.65*math.sin(phase)+1.8*lp+.08*rng.uniform(-1,1)*math.exp(-t*12))*env
        data.append(x)
    mix(data,start,gain)


manifest=[]
def render(name,duration,fn):
    global N,L,R
    N=int(SR*duration);L=array('f',[0])*N;R=array('f',[0])*N
    fn()
    peak=max(max(map(abs,L[:N])),max(map(abs,R[:N])),.001)
    gain=min(3,.75/peak)
    pcm=array('h')
    for i in range(N):
        fade=min(i/(SR*.004),1,(N-1-i)/(SR*.025))
        values=((L[i]+R[i])*.7071,)
        for value in values: pcm.append(int(max(-.95,min(.95,value*gain*fade))*32767))
    path=OUT/'sfx'/(name+'.wav')
    path.parent.mkdir(parents=True,exist_ok=True)
    with wave.open(str(path),'wb') as f:
        f.setnchannels(1);f.setsampwidth(2);f.setframerate(SR);f.writeframes(pcm.tobytes())
    manifest.append({'file':str(path.relative_to(OUT)),'seconds':round(N/SR,3),'source':'Original synthesis, Brilliant first voiceless demo','bytes':path.stat().st_size})

render('startup',1.4,lambda:(whoosh(0,1.1,.06),motif(.1,.08,.14,2)))
render('click',.12,lambda:chirp(0,1250,1550,.065,.08))
render('back',.18,lambda:chirp(0,1250,750,.1,.07))
render('panel',.45,lambda:whoosh(0,.34,.045))
render('connect',.6,lambda:(chirp(0,650,1300,.14,.08),note(1318.5,.4,'bell',.08,0,.15)))
render('disconnect',.8,lambda:(note(523.25,.35,'bell',.08),note(329.63,.4,'bell',.08,0,.28)))
render('ready',.6,lambda:motif(0,.07,.09,1.5))
render('launch',1.7,lambda:(whoosh(0,1.1,.1),motif(.35,.095,.18,2)))
render('round',.9,lambda:(chirp(0,1300,950,.09,.075),chirp(.14,950,1550,.1,.08),motif(.28,.075,.12,2)))
render('meteor',1.5,lambda:whoosh(0,1.45,.24))
render('impact',1.55,lambda:impact(0,.32))
render('reveal',.65,lambda:(note(1174.66,.36,'bell',.11,-.42,0),note(1396.91,.36,'bell',.11,.42,.15)))
render('select',.14,lambda:chirp(0,900,1150,.065,.075))
render('preview',.22,lambda:note(1046.5,.18,'tick',.06))
render('shot',.26,lambda:chirp(0,1900,260,.18,.13))
render('place',.55,lambda:note(880,.42,'bell',.09))
render('reject',.65,lambda:(note(392,.26,'bell',.065),note(329.63,.3,'bell',.06,0,.21)))
render('skip',.4,lambda:chirp(0,650,180,.28,.07))
for place in (1,2,3):
    render('zone_'+str(place),1.7,lambda p=place:(whoosh(0,.62,.07),motif(.25,.10,.15,2 if p==1 else 1.5 if p==2 else 1,'brass')))
render('zone_other',.65,lambda:(chirp(0,800,1100,.1,.07),note(587.33,.4,'bell',.06,0,.15)))
render('zone_exhausted',.65,lambda:chirp(0,700,140,.5,.06))
render('chat',.35,lambda:(chirp(0,1500,1900,.075,.065),chirp(.12,1900,1350,.09,.065)))
render('sent',.18,lambda:chirp(0,1100,1450,.09,.04))
render('thirty',1.4,lambda:(note(1174.66,1.25,'bell',.13),note(587.33,.7,'bell',.045,0,.08)))
render('tick',.3,lambda:(note(659.25,.16,'bell',.07),note(146.83,.23,'tick',.06)))
render('tick_final',.35,lambda:(note(880,.16,'bell',.105),note(146.83,.23,'tick',.06)))
render('timeout',.4,lambda:chirp(0,880,220,.24,.10))
render('victory',6,lambda:(whoosh(0,.9,.17),impact(.9,.15),motif(.98,.15,.37,1,'brass'),motif(2.4,.14,.37,2,'brass'),chord([293.665,349.228,440,587.33],3.4,2.2,.095,'brass')))
render('podium',2.8,lambda:(motif(0,.11,.28,1.5,'brass'),chord([293.66,349.23,440],.9,1.7,.06,'brass')))
render('finish',2.4,lambda:(note(440,1.1,'bell',.06),note(349.23,1.1,'bell',.06,0,.4),note(293.66,1.1,'bell',.06,0,.8)))
render('alert',1,lambda:(chirp(0,800,450,.22,.09),chirp(.35,800,450,.22,.09)))
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
import runpy
runpy.run_path(str(Path(__file__).parent/'audio/zone_completed.py'),run_name='__main__')
runpy.run_path(str(Path(__file__).parent/'audio/imperial_finish.py'),run_name='__main__')
manifest=json.loads((OUT/'manifest.json').read_text())
print(str(len(manifest))+' files; '+str(round(sum(m['bytes'] for m in manifest)/1048576,2))+' MiB')
