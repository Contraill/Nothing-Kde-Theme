import importlib.util
from pathlib import Path
import re
import tomllib
import unittest

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('starship_colors',ROOT/'runtime/accent-links.py')
colors=importlib.util.module_from_spec(spec);spec.loader.exec_module(colors)
SOURCE='''palette = "frost"
format = "$os$directory$git_branch$time$character"
[palettes.frost]
ice = "#8BD5FF"
bg0 = "#0B1118"
bg1 = "#111A24"
bg2 = "#17222D"
bg3 = "#22303D"
text = "#DCE7F3"
muted = "#6E7F91"
red = "#ED8796"
blue = "#7AA2F7"
[os]
style = "fg:bg0 bg:ice"
format = "[](fg:ice)[$symbol]($style)"
[os.symbols]
Linux = "  "
[directory]
style = "fg:text bg:bg2"
format = "[](fg:bg2 bg:blue)[  $path ]($style)[](fg:blue bg:bg1)"
[git_branch]
style = "fg:text bg:bg1"
format = "[ $symbol$branch ]($style)"
[time]
style = "fg:muted"
format = "[ $time]($style)"
[character]
success_symbol = "[❯](bold ice)"
error_symbol = "[❯](bold red)"
'''

class StarshipPalette(unittest.TestCase):
    def test_light_dark_accent_matrix_and_structure(self):
        before=tomllib.loads(SOURCE)
        for text,bg in [('#202A35','#F3F1EC'),('#E3E9F0','#111923')]:
            palette=dict(text=text,window=bg,base=bg,button=bg,alternate=bg,selection_text=text)
            for accent in ('#F2D872','#263B79','#806EE7','#19C964'):
                with self.subTest(text=text,accent=accent):
                    after=tomllib.loads(colors.patch_starship(SOURCE,accent,palette))
                    roles=after['palettes']['frost']
                    for name in ('os','directory','git_branch','time'):
                        style=dict(token.split(':',1) for token in after[name]['style'].split())
                        foreground=roles.get(style['fg'],style['fg'])
                        background=roles.get(style.get('bg'),style.get('bg',bg))
                        self.assertGreaterEqual(colors.contrast(foreground,background),4.5)
                        self.assertEqual(re.sub(r'\]\([^()]*\)',']',after[name]['format']),
                                         re.sub(r'\]\([^()]*\)',']',before[name]['format']))
                    self.assertEqual(after['time']['style'],'fg:'+text)
                    self.assertEqual(after['format'],before['format'])
                    self.assertEqual(after['os']['symbols'],before['os']['symbols'])
                    self.assertEqual(after['os']['format'],before['os']['format'])
                    self.assertEqual(roles['ice'],accent)
                    self.assertEqual(roles['bg0'],bg)
                    self.assertEqual(after['character']['success_symbol'],'[❯](bold fg:'+text+')')
    def test_custom_low_contrast_palette_is_adjusted_not_replaced(self):
        result=colors.readable_foreground('#888888',dict(text='#858A8F',window='#888888'))
        self.assertGreaterEqual(colors.contrast(result,'#888888'),4.5)
        self.assertNotIn(result,('#000000','#FFFFFF'))
    def test_inline_ink_is_not_confused_with_powerline_paint(self):
        palette=dict(text='#212C38',window='#F1EFEA',base='#F1EFEA',button='#F1EFEA',alternate='#F1EFEA')
        source=SOURCE.replace('[$symbol]($style)','[$symbol](fg:#000000 bg:ice)')
        result=tomllib.loads(colors.patch_starship(source,'#263B79',palette))
        self.assertTrue(result['os']['format'].startswith('[](fg:ice)'))
        self.assertNotIn('fg:#000000',result['os']['format'])

if __name__=='__main__': unittest.main()
