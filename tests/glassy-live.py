#!/usr/bin/env python3
"""Opt-in Dolphin/Kate same-process palette experiment in an isolated config root.

Uses the real Wayland session, but never writes the user's appearance files.
Each variant gets two new test processes; neither is restarted during transitions.
Only these test processes are terminated at the end. The capture library observes
Qt palettes/rendering and never changes them. No observer ships with the theme.
"""
import argparse
import configparser
import hashlib
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import time
import sys

sys.dont_write_bytecode=True

ROOT=Path(__file__).resolve().parents[1]

def run(*command,env=None):
    return subprocess.run(command,env=env,check=True,capture_output=True,text=True,timeout=30).stdout

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--output',required=True,type=Path)
    p.add_argument('--observer',required=True,type=Path)
    p.add_argument('--variant',choices=('omit-all','refactored'),required=True)
    p.add_argument('--initial-mode',choices=('light','dark'),default='light')
    args=p.parse_args();args.output=args.output.resolve()
    if args.output.exists():p.error('Use a new output directory; previous evidence is never overwritten')
    args.output.mkdir(parents=True)
    config=args.output/'config';config.mkdir(exist_ok=True)
    actual=Path(os.environ.get('XDG_CONFIG_HOME',Path.home()/'.config'))
    shutil.copy2(actual/'kdeglobals',config/'kdeglobals')
    kv=config/'Kvantum/Glassy';kv.mkdir(parents=True,exist_ok=True)
    shutil.copy2(actual/'Kvantum/Glassy/Glassy.svg',kv/'Glassy.svg')
    source=(actual/'Kvantum/Glassy/Glassy.kvconfig').read_text()
    parser=configparser.ConfigParser(interpolation=None,strict=False);parser.optionxform=str
    parser.read_string(source)
    if args.variant=='omit-all': parser.remove_section('GeneralColors')
    elif args.variant=='refactored' and parser.has_section('GeneralColors'):
        # Only retain roles actually consumed through cached standardPalette().
        for key in list(parser['GeneralColors']):
            if key not in ('base.color','alt.base.color'):
                del parser['GeneralColors'][key]
    with (kv/'Glassy.kvconfig').open('w') as file:parser.write(file)
    (config/'Kvantum/kvantum.kvconfig').write_text('[General]\ntheme=Glassy\n')
    env=dict(os.environ,XDG_CONFIG_HOME=str(config.resolve()),QT_STYLE_OVERRIDE='kvantum',QT_QPA_PLATFORM='wayland')
    children=[];results={};observed={}
    hashes=lambda:{f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in kv.iterdir()}
    try:
        first='NothingPlasma'+args.initial_mode.title()
        second='NothingPlasma'+('Dark' if args.initial_mode=='light' else 'Light')
        run('plasma-apply-colorscheme',first,env=env)
        # Materialize the baseline ONCE, before launching either application.
        # Freeze both files for the entire Light -> Dark -> Light experiment.
        sys.path.insert(0,str(ROOT/'runtime'))
        import appearance
        appearance.CONFIG=config
        baseline=appearance.palette()
        (kv/'Glassy.svg').write_text(appearance.render(baseline))
        if args.variant!='omit-all':
            for key,role in (('base.color','base'),('alt.base.color','alternate'),('window.color','window'),('button.color','button')):
                if parser.has_option('GeneralColors',key):parser['GeneralColors'][key]=baseline[role]
            with (kv/'Glassy.kvconfig').open('w') as file:parser.write(file)
        before=hashes()
        for name,command in {'dolphin':['dolphin','--new-window',str(ROOT)],'kate':['kate','--startanon',str(ROOT/'README.md')]}.items():
            prefix=args.output/name
            prefix.with_suffix('.phase').write_text('startup')
            log=prefix.with_suffix('.log').open('w')
            child=subprocess.Popen(command,env=dict(env,LD_PRELOAD=str(args.observer.resolve()),GLASSY_LIVE_CAPTURE=str(prefix.resolve())),stdout=log,stderr=log)
            log.close();children.append(child)
            results[name]={'pid':child.pid,'phases':[]}
        time.sleep(5)
        for name in results:
            results[name]['startup']=json.loads((args.output/f'{name}-startup.json').read_text())
        for phase,scheme in enumerate((first,second,first)):
            run('plasma-apply-colorscheme',scheme,env=env)
            # Match the production switcher's native palette notification.
            # The CLI alone does not deliver this in the isolated config root.
            run('dbus-send','--session','--type=signal','/KGlobalSettings',
                'org.kde.KGlobalSettings.notifyChange','int32:0','int32:0',env=env)
            for name in results:(args.output/name).with_suffix('.phase').write_text(str(phase))
            time.sleep(3)
            for name in results:
                data=json.loads((args.output/f'{name}-{phase}.json').read_text())
                if phase==0:
                    # Kate may launch the actual application through a child.
                    # Adopt only an observer carrying this exact isolated prefix.
                    marker=('GLASSY_LIVE_CAPTURE='+str((args.output/name).resolve())).encode()
                    if marker not in Path(f'/proc/{data["pid"]}/environ').read_bytes().split(b'\0'):
                        raise RuntimeError('Capture is not from an owned test process')
                    observed[data['pid']]=marker
                    results[name]['pid']=data['pid']
                if data['pid']!=results[name]['pid']:raise RuntimeError('Process restarted during transition')
                if results[name]['phases'] and data['styleAddress']!=results[name]['phases'][0]['styleAddress']:
                    raise RuntimeError('QStyle was replaced during transition')
                results[name]['phases'].append(data)
        results['assetsUnchanged']=before==hashes()
        if not results['assetsUnchanged']:raise RuntimeError('Frozen theme assets changed during the experiment')
    finally:
        for pid,marker in observed.items():
            try:
                if marker in Path(f'/proc/{pid}/environ').read_bytes().split(b'\0'):
                    os.kill(pid,signal.SIGTERM)
            except ProcessLookupError:pass
            except FileNotFoundError:pass
        for child in children:
            if child.poll() is None:child.terminate()
            try:child.wait(timeout=5)
            except subprocess.TimeoutExpired:child.kill();child.wait(timeout=5)
        (args.output/'results.json').write_text(json.dumps(results,indent=2)+'\n')
    print('Same-process captures complete; isolated assets unchanged:',results['assetsUnchanged'])

if __name__=='__main__':main()
