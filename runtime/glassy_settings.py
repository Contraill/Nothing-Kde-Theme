"""Semantic Glassy settings, using Aurorae's existing native KConfig group.

main.xml is the single default/range source for both renderers and settings UIs.
"""
import configparser
import os
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
DATA = Path(os.environ.get('XDG_DATA_HOME', Path.home()/'.local/share'))
SCHEMA = ROOT/'plasma/aurorae/org.glassy.decoration/contents/config/main.xml'
if not SCHEMA.exists(): SCHEMA = DATA/'kwin/decorations/org.glassy.decoration/contents/config/main.xml'
GROUP = 'org.glassy.decoration'


def schema():
    ns = {'k':'http://www.kde.org/standards/kcfg/1.0'}
    return ET.parse(SCHEMA).findall('.//k:entry', ns)


def settings(path=None):
    path = path or Path(os.environ.get('XDG_CONFIG_HOME', Path.home()/'.config'))/'auroraerc'
    c = configparser.ConfigParser(interpolation=None, strict=False)
    c.read(path)
    result = {}
    ns = {'k':'http://www.kde.org/standards/kcfg/1.0'}
    for e in schema():
        key=e.get('name'); default=e.find('k:default',ns).text
        raw=c.get(GROUP,key,fallback=default)
        if e.get('type')=='Bool': value=raw.lower() in ('true','1','yes')
        elif e.get('type')=='String': value=raw or ''
        else:
            try: value=int(raw)
            except ValueError: value=int(default)
            value=max(int(e.find('k:min',ns).text),min(int(e.find('k:max',ns).text),value))
        result[key]=value
    return result


def metrics(s):
    return dict(radius=[0,4,6][s['SurfaceRoundness']],
                spacing=[4,6,8][s['UiDensity']], margin=[0,2,4][s['UiDensity']],
                horizontal=[5,6,8][s['UiDensity']],
                min_height=['1.4font','1.6font','1.8font'][s['UiDensity']],
                menu_margin=[0,1,2][s['UiDensity']],
                scroll=[8,10,14][s['ScrollbarSize']],
                border=[0,.18,.26][s['BorderStrength']],
                popup_border=[0,.08,.14][s['BorderStrength']],
                accent=[.65,1,1][s['AccentIntensity']], pressed=[.15,.25,.40][s['AccentIntensity']])


def configure(template, s):
    c=configparser.ConfigParser(interpolation=None); c.optionxform=str; c.read_string(template)
    m=metrics(s); g=c['%General']
    g['reduce_window_opacity']=str(100-s['WindowOpacity'])
    g['reduce_menu_opacity']=str(100-s['PopupOpacity'])
    g['blurring']=g['popup_blurring']=str(s['BlurSurfaces']).lower()
    c['Hacks']['blur_translucent']=str(s['BlurSurfaces']).lower()
    g['scroll_width']=str(m['scroll']); g['layout_spacing']=str(m['spacing'])
    # Kvantum's own list; whitespace and empty items are dropped.
    g['opaque']=','.join(name.strip() for name in str(s.get('OpaqueApplications','')).split(',') if name.strip())
    g['menu_blur_radius']=g['tooltip_blur_radius']=str(m['radius'])
    c['ToolTip']['frame.element']='tooltip'; c['ToolTip']['interior.element']='tooltip'
    for key in ('top','bottom'):
        c['PanelButtonCommand']['text.margin.'+key]=str(m['margin'])
        for group in ('MenuItem','ItemView'): c[group]['text.margin.'+key]=str(m['menu_margin'])
    for key in ('left','right'):
        c['PanelButtonCommand']['text.margin.'+key]=str(m['horizontal'])
    # Qt/Kvantum measures the actual font and icons in sizeFromContents. Keep
    # padding bounded (min/ideal/max semantic presets), not window-relative.
    # There is no supported max_height key: do not cap accessibility fonts or
    # fight application layouts. These minimums are font-relative lower bounds.
    c['PanelButtonCommand']['min_height']=m['min_height']
    for group in ('MenuItem','ItemView'): c[group]['min_height']='1font'
    # Nine-slice widths MUST match the generated SVG geometry, including Square.
    for group, radius in (('PanelButtonCommand',m['radius']),('ScrollbarSlider',min(m['radius'],m['scroll']//2)),
                          ('HeaderSection',min(m['radius'],2)),('Slider',min(m['radius'],2)),('Focus',min(m['radius'],2))):
        for side in ('top','bottom','left','right'): c[group]['frame.'+side]=str(max(1,radius))
    import io
    out=io.StringIO(); c.write(out, space_around_delimiters=False)
    return out.getvalue()
