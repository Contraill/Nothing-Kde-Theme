import configparser
from pathlib import Path
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'runtime'))
from glassy_settings import settings, metrics, configure
from appearance_render import render
ROOT=Path(__file__).resolve().parents[1]
PALETTE=dict(window='#181818',text='#eeeeee',base='#202020',button='#252525',highlight='#806ee7',highlight_text='#ffffff')

class PresetTests(unittest.TestCase):
    def defaults(self): return settings(Path('/nonexistent/glassy-test'))

    def test_native_defaults_and_documented_opacity_limits(self):
        s=self.defaults(); self.assertEqual((s['WindowOpacity'],s['PopupOpacity']),(50,75))
        with tempfile.TemporaryDirectory() as td:
            path=Path(td)/'auroraerc'; path.write_text('[org.glassy.decoration]\nWindowOpacity=0\nPopupOpacity=300\nUiDensity=garbage\n')
            self.assertEqual((settings(path)['WindowOpacity'],settings(path)['PopupOpacity'],settings(path)['UiDensity']),(10,100,1))

    def test_presets_frame_sizes_and_shadow_contract(self):
        template=(ROOT/'assets/kvantum/Glassy/Glassy.kvconfig').read_text()
        for roundness in range(3):
            for scroll in range(3):
                s=self.defaults(); s.update(SurfaceRoundness=roundness,ScrollbarSize=scroll)
                m=metrics(s); c=configparser.ConfigParser(interpolation=None); c.read_string(configure(template,s))
                self.assertEqual(c.getint('PanelButtonCommand','frame.top'),max(1,m['radius']))
                self.assertLessEqual(2*c.getint('ScrollbarSlider','frame.left'),m['scroll'])
                svg=ET.fromstring(render(PALETTE,s)); ids=[e.get('id') for e in svg if e.get('id')]
                self.assertEqual(len(ids),len(set(ids)))
                for kind in ('menu','tooltip'):
                    for side in ('top','bottom','left','right','topleft','topright','bottomleft','bottomright'):
                        self.assertIn(kind+'-shadow-'+side,ids)
                    for side in ('top','bottom','left','right'): self.assertIn(kind+'-shadow-hint-'+side,ids)
                self.assertNotIn('A-1',ET.tostring(svg).decode())

    def test_accent_strength_never_changes_source_palette(self):
        original=PALETTE.copy(); s=self.defaults(); normal=render(PALETTE,s)
        s['AccentIntensity']=0; self.assertNotEqual(normal,render(PALETTE,s))
        s['AccentIntensity']=2; self.assertNotEqual(normal,render(PALETTE,s))
        self.assertEqual(PALETTE,original)

    def test_defaults_preserve_opacity_and_refine_padding(self):
        c=configparser.ConfigParser(interpolation=None)
        c.read_string(configure((ROOT/'assets/kvantum/Glassy/Glassy.kvconfig').read_text(),self.defaults()))
        self.assertEqual(c.getint('%General','reduce_window_opacity'),50)
        self.assertEqual(c.getint('%General','reduce_menu_opacity'),25)
        self.assertEqual(c.getint('%General','scroll_width'),10)
        self.assertEqual(c.getint('PanelButtonCommand','text.margin.top'),2)

    def test_density_is_bounded_and_font_relative(self):
        template=(ROOT/'assets/kvantum/Glassy/Glassy.kvconfig').read_text()
        for density in range(3):
            s=self.defaults(); s['UiDensity']=density
            c=configparser.ConfigParser(interpolation=None); c.read_string(configure(template,s))
            self.assertEqual(c['PanelButtonCommand']['min_height'], ['1.4font','1.6font','1.8font'][density])
            self.assertEqual(c.getint('PanelButtonCommand','text.margin.top'), [0,2,4][density])
            self.assertEqual(c.getint('MenuItem','text.margin.top'), density)
            # Views no longer inherit menu items, but keep their spacing.
            self.assertEqual(c.getint('ItemView','text.margin.top'), density)
            self.assertEqual(c['ItemView']['min_height'], c['MenuItem']['min_height'])
            self.assertEqual(c.getint('PanelButtonCommand','frame.top'), metrics(s)['radius'])
            self.assertNotIn('max_height', c['PanelButtonCommand'])
