import importlib.util
from pathlib import Path
import tempfile
from unittest import mock
import os
import tomllib
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('accent_links', ROOT / 'runtime/accent-links.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class AccentLinksTests(unittest.TestCase):
    def setUp(self):
        self.palette=dict(text='#E1E4E8',window='#101820',base='#14202A',button='#203040',alternate='#263442',selection_text='#F2F4F6')
        mock=patch.object(module,'current_palette',return_value=self.palette)
        mock.start();self.addCleanup(mock.stop)
    def test_validate_accent(self):
        self.assertEqual(module.accent('26,105,169'), '#1A69A9')
        for value in ('#abc', '#123456; reboot', '999,0,0', '../test'):
            with self.assertRaises(ValueError): module.accent(value)

    def test_starship_preserves_everything_but_one_accent(self):
        text = 'palette = "frost"\nformat = "$os$directory$character"\n[palettes.frost]\nice = "#8bd5ff"\nred = "#ff0000"\nbg0 = "#111111"\n[directory]\nstyle = "fg:red bg:bg0"\n'
        before = tomllib.loads(text)
        after = tomllib.loads(module.patch_starship(text, '#AB1234'))
        self.assertEqual(after['palettes']['frost']['ice'],'#AB1234')
        self.assertEqual(after['palettes']['frost']['bg0'],self.palette['window'])
        self.assertEqual(after['format'],before['format'])
        self.assertEqual(after['character']['success_symbol'],'[❯](bold fg:'+self.palette['text']+')')

    def test_frost_directory_body_edges_and_success_follow_accent(self):
        text = '''palette = "frost"
[palettes.frost]
ice = "#8BD5FF"
blue = "#7AA2F7"
red = "#ED8796"
mint = "#8BD5CA"
[directory]
format = "[](fg:bg2 bg:blue)[  $path ]($style)[](fg:blue bg:bg1)"
style = "fg:text bg:bg2"
[character]
success_symbol = "[❯](bold mint)"
error_symbol = "[❯](bold red)"
'''
        result = tomllib.loads(module.patch_starship(text, '#AB1234'))
        self.assertIn('bg:#AB1234',result['directory']['style'])
        fg=next(t[3:] for t in result['directory']['style'].split() if t.startswith('fg:'))
        self.assertGreaterEqual(module.contrast(fg,'#AB1234'),4.5)
        self.assertEqual(result['directory']['format'].count('#AB1234'), 2)
        self.assertEqual(result['character']['success_symbol'], '[❯](bold fg:'+self.palette['text']+')')
        self.assertEqual(result['character']['error_symbol'], '[❯](bold red)')
        self.assertEqual(result['palettes']['frost']['blue'], '#7AA2F7')
        self.assertEqual(result['palettes']['frost']['mint'], '#8BD5CA')

    def test_fastfetch_roundtrip_comments_logo_and_user_edits(self):
        with tempfile.TemporaryDirectory() as td:
            home = Path(td); config = home / '.config'
            source = config / 'fastfetch/config.jsonc'; source.parent.mkdir(parents=True)
            logo = source.parent / 'logo.txt'; logo.write_text(' ···\n · ·\n')
            import json
            original = '// user comment\n' + json.dumps({'logo': {'type': 'file-raw', 'source': str(logo)},
                'display': {'color': {'keys': 'cyan', 'title': 'blue', 'output': 'white'}}, 'modules': ['os']}, indent=2) + '\n'
            source.write_text(original)
            links = module.Links(config, home)
            links.set('fastfetch', True, '#AB1234'); links.sync('#123456')
            data = module.Document(source.read_text()).data
            self.assertEqual(data['display']['color']['keys'], '#123456')
            self.assertEqual(data['display']['color']['output'], 'white')
            self.assertEqual(logo.read_text(), ' ···\n · ·\n')
            self.assertIn('\x1b[38;2;18;52;86m', Path(data['logo']['source']).read_text())
            self.assertTrue(source.read_text().startswith('// user comment'))
            source.write_text(source.read_text().replace('"os"', '"kernel"'))
            links.set('fastfetch', False, '#123456')
            self.assertEqual(source.read_text(), original.replace('"os"', '"kernel"'))
            links.set('fastfetch', True, '#AAAAAA'); links.set('fastfetch', False, '#AAAAAA')
            self.assertEqual(source.read_text(), original.replace('"os"', '"kernel"'))

    def test_jsonc_insert_delete_trailing_commas_and_urls(self):
        text = '{/* comment */ "url": "https://x/*a*/", "display": {},}'
        changed = module.Document(text).set(('display', 'color', 'keys'), '#123456')
        changed = module.Document(changed).set(('display', 'color', 'title'), '#123456')
        changed = module.Document(changed).set(('display', 'color', 'keys'), None, remove=True)
        self.assertEqual(module.Document(changed).data['display']['color'], {'title': '#123456'})
        self.assertEqual(module.Document(changed).data['url'], 'https://x/*a*/')
        with self.assertRaises(ValueError): module.Document('{"a":1,"a":2}')

    def test_fastfetch_exact_restore_and_manual_accent_override(self):
        with tempfile.TemporaryDirectory() as td:
            home = Path(td); config = home / '.config'; path = config / 'fastfetch/config.jsonc'
            path.parent.mkdir(parents=True); original = '{"modules": ["os"],}'
            path.write_text(original); links = module.Links(config, home)
            links.set('fastfetch', True, '#123456'); links.set('fastfetch', False, '#123456')
            self.assertEqual(path.read_text(), original)
            links.set('fastfetch', True, '#123456')
            path.write_text(module.Document(path.read_text()).set(('display', 'color', 'keys'), 'green'))
            links.set('fastfetch', False, '#123456')
            self.assertEqual(module.Document(path.read_text()).data['display']['color']['keys'], 'green')

    def test_starship_without_palette_keeps_background_and_format(self):
        text = '[directory]\nstyle = "bold fg:blue bg:black"\nformat = "[$path]($style)"\n'
        data = tomllib.loads(module.patch_starship(text, '#AB1234'))
        self.assertEqual(data['directory']['style'], 'bold bg:black fg:'+self.palette['text'])
        self.assertEqual(data['directory']['format'], '[$path]($style)')

    def test_retired_kitty_link_preserves_user_edits_without_backup(self):
        with tempfile.TemporaryDirectory() as td:
            home = Path(td)
            config = home / '.config'
            file = config / 'kitty/kitty.conf'
            file.parent.mkdir(parents=True)
            before = 'font_size 12.5\ncolor1 #FF0000\nbackground #112233\n'
            file.write_text(module.block(before, 'include ../nothing-kde/accent-links/kitty.conf') + 'font_size 14\n')
            links = module.Links(config, home)
            links.root.mkdir(parents=True)
            (links.root / 'kitty.conf').write_text('cursor #AB1234\n')
            links.state['kitty'] = True
            with patch.object(module, 'reload_kitty') as reload:
                links.retire_kitty()
                reload.assert_called_once()
                links.retire_kitty()
                reload.assert_called_once()
            self.assertEqual(file.read_text(), before + 'font_size 14\n')
            self.assertNotIn('kitty', module.TARGETS)
            self.assertNotIn('kitty', links.state)
            self.assertFalse((links.root / 'kitty.conf').exists())
            self.assertFalse((links.root / 'backups').exists())

    def test_starship_round_trip_preserves_original_and_running_shell_path(self):
        # The developer's own linked prompt exports STARSHIP_CONFIG; isolate it.
        environment = {k: v for k, v in os.environ.items() if k != 'STARSHIP_CONFIG'}
        with mock.patch.dict(os.environ, environment, clear=True), tempfile.TemporaryDirectory() as td:
            home = Path(td); config = home / '.config'
            (config / 'fish').mkdir(parents=True)
            source = config / 'starship.toml'
            original = 'format = "$directory$character"\n'
            source.write_text(original)
            links = module.Links(config, home)
            links.set('starship', True, '#AB1234')
            self.assertEqual(source.read_text(), original)
            links.set('starship', False, '#AB1234')
            self.assertEqual((links.root / 'starship.toml').read_text(), original)
            self.assertNotIn('STARSHIP_CONFIG', (config / 'fish/conf.d/00-nothing-kde-accent.fish').read_text())

    def test_spaceship_does_not_recolor_error_status(self):
        with tempfile.TemporaryDirectory() as td:
            home = Path(td); source = home / '.zshrc'
            source.write_text('# existing prompt\n')
            links = module.Links(home / '.config', home)
            links.set('spaceship', True, '#AB1234')
            code = (links.root / 'spaceship.zsh').read_text()
            self.assertNotIn('SPACESHIP_CHAR_COLOR_FAILURE=', code)
            self.assertIn('add-zsh-hook -d', code)
            links.set('spaceship', False, '#AB1234')
            self.assertEqual(source.read_text(), '# existing prompt\n')
            self.assertEqual((links.root / 'spaceship-color').read_text(), '')

    def test_limine_12_export_preserves_boot_entries_and_palette(self):
        text = 'timeout: 5\ninterface_branding_color: ABCDEF\nterm_palette: 000000;111111;222222;333333;444444;555555;666666;777777\n/CachyOS\n  protocol: linux\n  cmdline: root=UUID=example quiet\n/Windows\n  protocol: efi\n  path: boot():/EFI/Microsoft/Boot/bootmgfw.efi\n'
        result = module.limine_preview(text, '#1A69A9')
        self.assertIn('interface_branding_color: 1A69A9', result)
        self.assertEqual(result[result.index('/CachyOS'):], text[text.index('/CachyOS'):])
        self.assertIn(text.splitlines()[2], result)
        with self.assertRaises(ValueError): module.limine_preview('interface_branding_color: 6\n', '#123456')

    def test_incomplete_managed_block_is_not_overwritten(self):
        with self.assertRaises(ValueError): module.block(module.BEGIN + '\nuser changes\n', 'new')

    def test_disabled_sync_creates_no_configuration(self):
        with tempfile.TemporaryDirectory() as td:
            links = module.Links(Path(td) / '.config', Path(td))
            links.sync('#AB1234')
            self.assertFalse(links.root.exists())


    def test_gtk_block_follows_accent_and_keeps_kde_imports(self):
        with tempfile.TemporaryDirectory() as td:
            home = Path(td); config = home / '.config'; css = config / 'gtk-4.0/gtk.css'
            css.parent.mkdir(parents=True); css.write_text("@import 'colors.css';")
            links = module.Links(config, home)
            self.assertTrue(links.status()['available']['gtk'])
            links.set('gtk', True, '#109DD9'); links.sync('#D71921')
            text = css.read_text()
            self.assertTrue(text.startswith("@import 'colors.css';\n/* >>> Nothing KDE accent >>> */"))
            self.assertIn('--accent-bg-color: #D71921;', text)
            self.assertNotIn('#109DD9', text)
            self.assertNotIn('# >>>', text)
            links.set('gtk', False, '#D71921')
            self.assertEqual(css.read_text(), "@import 'colors.css';\n")

if __name__ == '__main__': unittest.main()
