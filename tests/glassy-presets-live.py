#!/usr/bin/env python3
"""Isolated real Wayland Qt gallery captures for semantic/fractional presets.
Writes no user configuration; all processes belong to this finite test.
"""
import argparse
import configparser
import json
import os
from pathlib import Path
import subprocess
import sys
sys.dont_write_bytecode=True
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'runtime'))
from glassy_settings import settings,metrics,configure
from appearance_render import render


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--output',type=Path,required=True)
    p.add_argument('--build',type=Path,required=True)
    p.add_argument('--mode',choices=('Dark','Light'))
    args=p.parse_args();args.output.mkdir(exist_ok=False)
    template=(ROOT/'assets/kvantum/Glassy/Glassy.kvconfig').read_text()
    results=[]
    for mode in ((args.mode,) if args.mode else ('Dark','Light')):
        c=configparser.ConfigParser(interpolation=None);c.optionxform=str
        c.read(Path.home()/'.config/kdeglobals')
        c.read(ROOT/f'color-schemes/NothingPlasma{mode}.colors')
        c['General']['ColorScheme']='NothingPlasma'+mode
        def color(group,key):return '#'+''.join(f'{int(x):02x}' for x in c['Colors:'+group][key].split(','))
        palette={k:color(g,v) for k,g,v in (('window','Window','BackgroundNormal'),('text','Window','ForegroundNormal'),
            ('base','View','BackgroundNormal'),('alternate','View','BackgroundAlternate'),('button','Button','BackgroundNormal'),
            ('highlight','Selection','BackgroundNormal'),('highlight_text','Selection','ForegroundNormal'))}
        for roundness,scale in ((0,'1.25'),(1,'1.25'),(2,'1.25'),(1,'1.5')):
            case=args.output/f'{mode.lower()}-r{roundness}-s{scale}';case.mkdir()
            config=case/'config';kv=config/'Kvantum/Glassy';kv.mkdir(parents=True)
            with (config/'kdeglobals').open('w') as f:c.write(f)
            (config/'Kvantum/kvantum.kvconfig').write_text('[General]\ntheme=Glassy\n')
            s=settings(Path('/nonexistent/glassy-test'));s.update(SurfaceRoundness=roundness,
                UiDensity=roundness,ScrollbarSize=roundness,BorderStrength=roundness,AccentIntensity=roundness)
            m=metrics(s)
            (kv/'Glassy.svg').write_text(render(palette,s))
            (kv/'Glassy.kvconfig').write_text(configure(template,s)+'\n[GeneralColors]\nbase.color='+palette['base']+'\nalt.base.color='+palette['alternate']+'\n')
            env=dict(os.environ,XDG_CONFIG_HOME=str(config.resolve()),QT_STYLE_OVERRIDE='kvantum',QT_SCALE_FACTOR=scale,
                     GLASSY_AUTO='1',GLASSY_CAPTURE=str((case/'gallery').resolve()))
            with (case/'probe.log').open('w') as log:
                subprocess.run([str(args.build/'glassy-svg'),str(kv/'Glassy.svg'),str(case/'slices.png'),str(m['radius']),str(min(m['radius'],m['scroll']//2))],env=dict(env,QT_QPA_PLATFORM='offscreen'),stdout=log,stderr=log,check=True,timeout=15)
            with (case/'gallery.log').open('w') as log:
                subprocess.run([str(args.build/'glassy-gallery')],env=env,stdout=log,stderr=log,check=True,timeout=20)
            for suffix in ('','-menu','-tooltip','-combo','-dialog','-views'):
                if not (case/f'gallery{suffix}.png').exists():raise RuntimeError('Missing capture: '+str(case)+suffix)
            result=json.loads((case/'gallery.json').read_text());assert result['windowOpacity']==1
            result['case']=case.name;results.append(result);print(case.name,'PASS',flush=True)
            (args.output/'results.json').write_text(json.dumps(results,indent=2))
    (args.output/'results.json').write_text(json.dumps(results,indent=2))


if __name__=='__main__':main()
