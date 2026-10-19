#!/usr/bin/env python3
"""Real Kvantum size hints and menu-cache experiment; isolated disposable config."""
import argparse
import configparser
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'runtime'))
from glassy_settings import configure, settings
from appearance_render import render


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--probe', required=True, type=Path)
    args = parser.parse_args()
    template = (ROOT / 'assets/kvantum/Glassy/Glassy.kvconfig').read_text()
    with tempfile.TemporaryDirectory(prefix='glassy-density-matrix-') as td:
        directory = Path(td)
        kv = directory / 'config/Kvantum/Glassy'; kv.mkdir(parents=True)
        (kv.parent / 'kvantum.kvconfig').write_text('[General]\ntheme=Glassy\n')
        reports = {}
        for mode in ('Light', 'Dark'):
            colors = configparser.ConfigParser(interpolation=None)
            colors.read(ROOT / f'color-schemes/NothingPlasma{mode}.colors')
            def color(group, key):
                return '#' + ''.join(f'{int(x):02x}' for x in colors[group][key].split(','))
            p = {role: color(group,key) for role,group,key in (
                ('window','Colors:Window','BackgroundNormal'),('text','Colors:Window','ForegroundNormal'),
                ('base','Colors:View','BackgroundNormal'),('button','Colors:Button','BackgroundNormal'),
                ('highlight','Colors:Selection','BackgroundNormal'),('highlight_text','Colors:Selection','ForegroundNormal'))}
            for font in (8,10,14):
                for scale in ('1','1.25','2'):
                    for density in range(3):
                        s = settings(directory / 'absent'); s['UiDensity']=density
                        config = configure(template,s)
                        # Match production: only the two required Base overrides,
                        # never pin menu/window/text roles in the test config.
                        config += '\n[GeneralColors]\nbase.color=' + p['base'] + '\nalt.base.color=' + p['base'] + '\n'
                        (kv/'Glassy.kvconfig').write_text(config)
                        (kv/'Glassy.svg').write_text(render(p,s))
                        env = dict(os.environ, XDG_CONFIG_HOME=str(directory/'config'),
                                   XDG_DATA_HOME=str(directory/'data'), XDG_CACHE_HOME=str(directory/'cache'),
                                   QT_QPA_PLATFORM='offscreen', QT_QPA_PLATFORMTHEME='generic',
                                   QT_STYLE_OVERRIDE='kvantum', QT_SCALE_FACTOR=scale, GLASSY_TEST_FONT=str(font),
                                   GLASSY_TEST_WINDOW=p['window'], GLASSY_TEST_TEXT=p['text'])
                        result = subprocess.run([str(args.probe.resolve())],env=env,check=True,
                                                capture_output=True,text=True,timeout=20)
                        report = json.loads(result.stdout)
                        assert report['style'].lower() == 'kvantum', report
                        for control in report['controls']:
                            assert control['resizeStable'], control
                            assert control['fontHeight'] <= control['height'] <= control['fontHeight'] + 36, control
                        heights = {c['name']:c['height'] for c in report['controls']}
                        assert heights['input'] == heights['password']
                        assert abs(heights['input'] - heights['combo']) <= 4, heights
                        if density:
                            previous=reports[mode,font,scale,density-1]
                            assert all(previous[n] <= h for n,h in heights.items()), heights
                        if mode == 'Dark': assert heights == reports['Light',font,scale,density]
                        reports[mode,font,scale,density]=heights
                        if (mode,font,scale,density)==('Light',10,'1',1):
                            print('Normal, 10pt:',json.dumps(report),flush=True)
                            # Measure the former padding with the same SVG/font,
                            # in a separate baseline test process, not by reloading
                            # the style of an existing application.
                            old=configparser.ConfigParser(interpolation=None); old.optionxform=str; old.read_string(config)
                            old['PanelButtonCommand'].update({'text.margin.top':'4','text.margin.bottom':'4',
                                'text.margin.left':'7','text.margin.right':'7','min_height':'1.5font'})
                            for group in ('MenuItem','ItemView'):
                                for key in ('text.margin.top','text.margin.bottom','min_height'): old[group].pop(key,None)
                            with (kv/'Glassy.kvconfig').open('w') as stream: old.write(stream)
                            baseline=json.loads(subprocess.run([str(args.probe.resolve())],env=env,check=True,
                                                capture_output=True,text=True,timeout=20).stdout)
                            previous={c['name']:c['height'] for c in baseline['controls']}
                            print('Previous Normal, 10pt:',json.dumps(previous),flush=True)
                            assert all(heights[n] < previous[n] for n in heights), (heights,previous)
                            (kv/'Glassy.kvconfig').write_text(config)
                        # The style/SVG remains fixed through the three palette
                        # events, including creating a fresh menu after each event.
                        assert all(phase['sameStyle'] for phase in report['phases'])
        print(f'PASS: {len(reports)} font/scaling/density/palette combinations; stable size hints, font bounds, password/combo and light/dark parity.')


if __name__ == '__main__':
    main()
