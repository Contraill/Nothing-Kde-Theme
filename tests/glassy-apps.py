#!/usr/bin/env python3
"""Opt-in Wayland application captures. Restores the color scheme; no app data edits."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import time

ROOT=Path(__file__).resolve().parents[1]

def run(*args):
    return subprocess.run(args,check=True,capture_output=True,text=True,timeout=30).stdout.strip()

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--capture-library',required=True,type=Path)
    p.add_argument('--gallery',required=True,type=Path)
    p.add_argument('--output',required=True,type=Path)
    args=p.parse_args(); args.output.mkdir(parents=True,exist_ok=True)
    if not args.capture_library.is_file() or not args.gallery.is_file(): p.error('Build test executables first')
    original=run('kreadconfig6','--file','kdeglobals','--group','General','--key','ColorScheme')
    results={}; children=[]
    def theme(name):
        run('plasma-apply-colorscheme',name)
        run('python3',str(ROOT/'runtime/appearance.py'),'sync')
        time.sleep(2)
    def capture(name,command,popups=False):
        prefix=args.output/name
        env=dict(os.environ,LD_PRELOAD=str(args.capture_library),NOTHING_CAPTURE=str(prefix),QT_STYLE_OVERRIDE='kvantum')
        if popups: env['NOTHING_CAPTURE_POPUPS']='1'
        with prefix.with_suffix('.log').open('w') as log:
            process=subprocess.Popen(command,env=env,stdout=log,stderr=log,start_new_session=True)
            children.append(process)
            time.sleep(7)
            metadata=prefix.with_suffix('.json')
            results[name]=json.loads(metadata.read_text()) if metadata.exists() else {'error':'No isolated application capture'}
            if process.poll() is None:
                if command[0]=='dbus-run-session':
                    # Closing our isolated bus tears down only that test session.
                    import signal
                    os.killpg(process.pid,signal.SIGTERM)
                else:
                    run('python3',str(ROOT/'tests/appearance-session.py'),str(process.pid),'close')
                try: process.wait(timeout=5)
                except subprocess.TimeoutExpired: process.terminate(); process.wait(timeout=5)
    try:
        for mode in ('dark','light'):
            theme('NothingPlasma'+mode.title())
            capture('dolphin-'+mode,['dolphin','--new-window','-stylesheet',str(Path.home()/'.config/nothing-kde/dolphin/style.qss'),str(ROOT)],True)
            capture('kate-'+mode,['kate','--startanon'],True)
            capture('settings-'+mode,['dbus-run-session','--','systemsettings','kcm_style'])
        # Keep the SAME Widgets process through Light -> Dark -> Light. It must
        # not be silently restarted to make this test appear to pass.
        prefix=args.output/'live'
        env=dict(os.environ,GLASSY_CAPTURE=str(prefix),QT_STYLE_OVERRIDE='kvantum')
        with (args.output/'live.log').open('w') as log:
            gallery=subprocess.Popen([str(args.gallery)],env=env,stdout=log,stderr=log)
            children.append(gallery); time.sleep(2)
            for index,scheme in enumerate(('NothingPlasmaLight','NothingPlasmaDark','NothingPlasmaLight')):
                theme(scheme)
                for suffix in ('.png','.json'):
                    shutil.copy2(prefix.with_suffix(suffix),args.output/f'live-{index}{suffix}')
            run('python3',str(ROOT/'tests/appearance-session.py'),str(gallery.pid),'close')
            gallery.wait(timeout=5)
    finally:
        for process in children:
            if process.poll() is None: process.terminate()
        theme(original)
        (args.output/'results.json').write_text(json.dumps(results,indent=2)+'\n')
    print('Captured fresh application palettes and same-process transitions; original scheme restored.')

if __name__=='__main__': main()
