#!/usr/bin/env python3
"""Opt-in real session checks. Touches only appearance and explicitly owned test windows.

Always restore the exact prior Aurorae keys. Never close pre-existing apps.
"""
import argparse
import json
from pathlib import Path
import subprocess
import time

ROOT=Path(__file__).resolve().parents[1]
KEYS=('CornerRadius','RoundBottomCorners','TitlebarOpacity','InactiveOpacity','Blur','BorderWidth','Separator','TitlebarSize','ButtonSize','ButtonSpacing','Shadow','TitleAlignment','InactiveButtons','ActiveAccentBorder')
GROUP='org.glassy.decoration'
ABSENT='__GLASSY_ABSENT__'

def run(*args):
    return subprocess.run(args,check=True,capture_output=True,text=True,timeout=30).stdout.strip()

def read(key):
    return run('kreadconfig6','--file','auroraerc','--group',GROUP,'--key',key,'--default',ABSENT)

def write(key,value):
    run('kwriteconfig6','--file','auroraerc','--group',GROUP,'--key',key,*(['--delete'] if value==ABSENT else [str(value).lower()]))

def configure(values):
    for key,value in values.items(): write(key,value)
    run('qdbus6','org.kde.KWin','/KWin','org.kde.KWin.reconfigure')
    time.sleep(.4)

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pid',required=True,type=int)
    parser.add_argument('--output',required=True,type=Path)
    args=parser.parse_args()
    command=Path(f'/proc/{args.pid}/cmdline').read_bytes().split(b'\0')[0]
    if Path(command.decode()).name!='glassy-gallery': parser.error('Only the test gallery PID is accepted')
    args.output.mkdir(parents=True,exist_ok=True)
    original={key:read(key) for key in KEYS}
    cases={
        'defaults':original,
        'square-clear':dict(CornerRadius=0,TitlebarOpacity=15,Blur=False,BorderWidth=0,Shadow=0),
        'rounded-opaque':dict(CornerRadius=24,TitlebarOpacity=100,Blur=True,BorderWidth=2,Separator=True),
        'compact-large-buttons':dict(CornerRadius=10,TitlebarOpacity=50,Blur=True,BorderWidth=1,Separator=False,TitlebarSize=0,ButtonSize=2,ButtonSpacing=2,Shadow=3),
        'comfortable-small-buttons':dict(TitlebarSize=2,ButtonSize=0,ButtonSpacing=0,Shadow=1),
        'center-accent-dimmed':dict(TitleAlignment=1,ActiveAccentBorder=True,InactiveButtons=1),
    }
    cases.update({f'radius-{radius}-border-{border}-bottom-{bottom}':dict(CornerRadius=radius,BorderWidth=border,RoundBottomCorners=bottom)
                  for radius in (0,10,24) for border in (0,1) for bottom in (False,True)})
    try:
        for name,values in cases.items():
            configure(original); configure(values)
            run('python3',str(ROOT/'tests/appearance-session.py'),str(args.pid),'activate','--capture',str(args.output/(name+'.png')))
            run('python3',str(ROOT/'tests/appearance-session.py'),str(args.pid),'inactive','--capture',str(args.output/(name+'-inactive.png')))
            print('Captured configuration:',name,flush=True)
        configure(original)
        for action in ('maximize','restore','tile','tile-right','resize','restore'):
            run('python3',str(ROOT/'tests/appearance-session.py'),str(args.pid),action,'--capture',str(args.output/(action+'.png')))
            print('Captured window state:',action,flush=True)
    finally:
        configure(original)
        (args.output/'original-config.json').write_text(json.dumps(original,indent=2)+'\n')

if __name__=='__main__': main()
