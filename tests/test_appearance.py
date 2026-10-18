import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'runtime'))
import appearance as app
from appearance_render import render


class AppearanceTests(unittest.TestCase):
    def test_reusable_glassy_names(self):
        metadata = json.loads((ROOT / 'plasma/aurorae/org.glassy.decoration/metadata.json').read_text())
        self.assertEqual(metadata['KPlugin']['Name'], 'Glassy')
        self.assertEqual(metadata['KPlugin']['Id'], 'org.glassy.decoration')
        self.assertEqual(app.KV.name, 'Glassy')
        for mode in ('dark', 'light'):
            defaults = (ROOT / f'plasma/look-and-feel/com.nothingplasma.{mode}/contents/defaults').read_text()
            self.assertIn('org.glassy.decoration', defaults)

    def test_config_omits_live_palette_roles(self):
        import configparser
        with patch.object(app,'TEMPLATE',ROOT/'assets/kvantum/Glassy/Glassy.kvconfig'):
            content=app.config_text({'base':'#121212','alternate':'#202020'})
        config=configparser.ConfigParser(interpolation=None)
        config.read_string(content)
        self.assertEqual(dict(config['GeneralColors']),
                         {'base.color':'#121212','alt.base.color':'#202020'})

    def test_native_palette_signal_is_not_gated_by_asset_rewrites(self):
        with patch.object(app,'read',return_value='Glassy'),patch.object(app,'palette',return_value={}), \
             patch.object(app,'render',return_value='<svg/>'),patch.object(app,'config_text',return_value=''), \
             patch.object(app,'owned_file',return_value=False),patch.object(app,'notify') as notify:
            app.sync({'enabled':True})
            notify.assert_called_once_with()

    def _sync_with_style(self, style, kv, state):
        values = {app.KVTHEME: 'Glassy', app.STYLE: style}
        writes = []
        with patch.object(app, 'KV', kv), patch.object(app, 'read', side_effect=lambda key: values[tuple(key)]), \
             patch.object(app, 'write', side_effect=lambda key, value: (writes.append((tuple(key), value)), values.__setitem__(tuple(key), value))), \
             patch.object(app, 'palette', return_value={}), patch.object(app, 'glassy_settings', return_value={}), \
             patch.object(app, 'render', return_value='<svg id="new"/>'), patch.object(app, 'config_text', return_value='[General]\n'), \
             patch.object(app, 'save'), patch.object(app, 'notify') as notify:
            app.sync(state)
        return writes, notify

    def test_changed_palette_loads_through_the_other_kvantum_slot(self):
        with tempfile.TemporaryDirectory() as td:
            kv = Path(td); state = {'enabled': True}
            writes, notify = self._sync_with_style('kvantum', kv, state)
            self.assertEqual((kv / 'GlassyDark.svg').read_text(), '<svg id="new"/>')
            self.assertEqual(writes, [(app.STYLE, 'kvantum-dark')])
            notify.assert_called_once_with(style=True)
            # Ownership keeps the original style for rollback.
            self.assertEqual(state['keys'][0], {'key': list(app.STYLE), 'before': 'kvantum', 'after': 'kvantum-dark'})
            # The next change flips back into the light slot.
            (kv / 'GlassyDark.svg').write_text('stale')
            state['files'][str(kv / 'GlassyDark.svg')]['after'] = app.digest(b'stale')
            writes, notify = self._sync_with_style('kvantum-dark', kv, state)
            self.assertEqual(writes, [(app.STYLE, 'kvantum')])

    def test_unchanged_slot_only_refreshes_the_palette(self):
        with tempfile.TemporaryDirectory() as td:
            kv = Path(td)
            (kv / 'Glassy.svg').write_text('<svg id="new"/>'); (kv / 'Glassy.kvconfig').write_text('[General]\n')
            writes, notify = self._sync_with_style('kvantum', kv, {'enabled': True})
            self.assertEqual(writes, [])
            notify.assert_called_once_with()

    def test_restore_returns_from_the_dark_slot(self):
        state = {'keys': [{'key': list(app.STYLE), 'before': 'Breeze', 'after': 'kvantum-dark'}]}
        with patch.object(app, 'read', return_value='kvantum-dark'), patch.object(app, 'write') as write, \
             patch.object(app, 'save'), patch.object(app, 'notify'):
            app.restore(state)
            write.assert_called_once_with(list(app.STYLE), 'Breeze')

    def test_svg_uses_only_supplied_palette_and_valid_ids(self):
        palette = dict(window='#101112', text='#f0f1f2', base='#202122', button='#303132',
                       highlight='#806ee7', highlight_text='#fafafa')
        root = ET.fromstring(render(palette))
        ids = [n.attrib['id'] for n in root.iter() if 'id' in n.attrib]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertIn('button-normal-topleft', ids)
        self.assertIn('input-normal', ids)
        self.assertNotIn(' opacity=', render(palette))  # Alpha belongs only to shadow fills.
        palette['button'] = '#efeeed'
        self.assertIn('#efeeed', render(palette))

    def test_reinstall_is_noop_and_user_asset_edits_are_guarded(self):
        with tempfile.TemporaryDirectory() as td, patch.object(app, 'save'):
            path = Path(td) / 'asset.svg'; state = {}
            self.assertTrue(app.owned_file(state, path, 'first'))
            timestamp = path.stat().st_mtime_ns
            self.assertFalse(app.owned_file(state, path, 'first'))
            self.assertEqual(timestamp, path.stat().st_mtime_ns)
            self.assertTrue(app.owned_file(state, path, 'upgrade'))
            path.write_text('user-edit')
            with self.assertRaises(ValueError): app.owned_file(state, path, 'next')

    def test_restore_preserves_new_user_selection(self):
        state = {'keys': [{'key': list(app.STYLE), 'before': 'Breeze', 'after': 'kvantum'}]}
        with patch.object(app, 'read', return_value='Fusion'), patch.object(app, 'write') as write, \
             patch.object(app, 'save'), patch.object(app, 'notify'):
            app.restore(state)
            write.assert_not_called()

    def test_restore_owned_selection(self):
        state = {'keys': [{'key': list(app.STYLE), 'before': 'Breeze', 'after': 'kvantum'}]}
        with patch.object(app, 'read', return_value='kvantum'), patch.object(app, 'write') as write, \
             patch.object(app, 'save'), patch.object(app, 'notify'):
            app.restore(state)
            write.assert_called_once_with(list(app.STYLE), 'Breeze')

    def test_restore_keeps_decoration_pair_together(self):
        state={'keys':[{'key':list(app.LIBRARY),'before':'old.plugin','after':'org.kde.kwin.aurorae'},
                       {'key':list(app.THEME),'before':'old.theme','after':'org.glassy.decoration'}]}
        values={app.LIBRARY:'org.kde.kwin.aurorae',app.THEME:'user.decoration'}
        with patch.object(app,'read',side_effect=lambda key:values[tuple(key)]), patch.object(app,'write') as write, \
             patch.object(app,'save'),patch.object(app,'notify'):
            app.restore(state)
            write.assert_not_called()

    def test_owned_asset_rejects_symlinks(self):
        with tempfile.TemporaryDirectory() as td, patch.object(app,'save'):
            target=Path(td)/'user'; target.write_text('original')
            link=Path(td)/'theme'; link.symlink_to(target)
            with self.assertRaises(ValueError): app.owned_file({},link,'original')

    def test_color_scheme_changes_are_explicitly_owned(self):
        state={'enabled':True}
        with patch.object(app,'read',return_value='NothingPlasmaLight'),patch.object(app,'save'):
            app.record_scheme(state,'BreezeDark')
        self.assertEqual(state['keys'][0]['before'],'BreezeDark')
        with patch.object(app,'read',return_value='NothingPlasmaDark'),patch.object(app,'save'):
            app.record_scheme(state,'NothingPlasmaLight')
        self.assertEqual(state['keys'][0]['before'],'BreezeDark')
        self.assertEqual(state['keys'][0]['after'],'NothingPlasmaDark')

    def test_glass_does_not_set_global_window_opacity(self):
        config = (ROOT / 'assets/kvantum/Glassy/Glassy.kvconfig').read_text()
        for entry in ('composite=true', 'reduce_window_opacity=50', 'reduce_menu_opacity=25',
                      'blurring=true', 'popup_blurring=true', 'transparent_dolphin_view=true'):
            self.assertIn(entry, config)
        self.assertNotIn('[GeneralColors]', config)
        self.assertNotIn('kwinrulesrc', (ROOT / 'runtime/appearance.py').read_text())

    def test_aurorae_has_native_mask_and_palette(self):
        source = ROOT / 'plasma/aurorae/org.glassy.decoration/contents'
        qml = (source / 'ui/GlassyDecoration.qml').read_text()
        self.assertIn('property alias decorationMask: blurMask.mask', qml)
        self.assertIn('SystemPalette', qml)
        # Window-sized Canvas images were repainted on every resize frame.
        self.assertNotIn('Canvas', qml)
        self.assertIn('fillRule: ShapePath.OddEvenFill', qml)
        spec = importlib.util.spec_from_file_location('glassy_build', ROOT / 'plasma/aurorae/build.py')
        builder = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(builder)
        assets = builder.assets(source.parent)
        ids = {n.get('id') for n in ET.fromstring(assets['contents/assets/masks.svg']).iter()}
        self.assertTrue({'r10-center', 'r10-top', 'r10-topleft', 'r10-topright', 'off-center'} <= ids)
        for radius in range(25):
            self.assertTrue({f'b{radius}-{part}' for part in ('center','topleft','topright','bottomleft','bottomright')} <= ids)
        self.assertFalse(any(i and i.startswith('mask-') for i in ids))

    def test_configuration_form_covers_schema(self):
        package = ROOT / 'plasma/aurorae/org.glassy.decoration/contents'
        names = {n.get('name') for n in ET.parse(package / 'config/main.xml').iter() if n.tag.endswith('entry')}
        spec = importlib.util.spec_from_file_location('glassy_build', ROOT / 'plasma/aurorae/build.py')
        builder = importlib.util.module_from_spec(spec); spec.loader.exec_module(builder)
        form = ET.fromstring(builder.assets(package.parent)['contents/ui/config.ui'])
        widgets = {n.get('name')[5:] for n in form.iter('widget') if n.get('name','').startswith('kcfg_')}
        self.assertEqual(names, widgets)
        self.assertTrue({'CornerRadius','RoundBottomCorners','TitlebarOpacity','InactiveOpacity','Blur'} <= names)
        self.assertNotIn('BottomCornerRadius', names)

    def test_indicator_names_match_kvantum_contract(self):
        p=dict(window='#eeeeee',text='#111111',base='#fafafa',button='#dddddd',highlight='#806ee7',highlight_text='#ffffff')
        ids={n.get('id') for n in ET.fromstring(render(p)).iter()}
        self.assertTrue({'check-checked-normal','check-tristate-focused','radio-checked-focused',
                         'tab-close-normal','arrow-up-normal','tree-minus-normal','handle-normal','focus-top'} <= ids)

    def test_nine_slice_geometry_has_no_stroke(self):
        from appearance_render import frame
        self.assertNotIn('stroke=', frame('button-normal','#ffffff','#cccccc'))


if __name__ == '__main__': unittest.main()
