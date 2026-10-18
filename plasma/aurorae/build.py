"""Build native Aurorae assets; main.xml is the sole configuration default source."""
import json
import xml.etree.ElementTree as ET
from xml.sax.saxutils import escape


def config_ui(entries):
    """Same semantic form for Aurorae's native KCM and Glassy Settings."""
    fields = {
        'Application': [('SurfaceRoundness','Surface roundness',['Square','Subtle','Rounded']),
                        ('UiDensity','UI density',['Compact','Normal','Comfortable']),
                        ('BorderStrength','Border strength',['None','Subtle','Normal']),
                        ('ScrollbarSize','Scrollbar size',['Compact','Normal','Wide']),
                        ('AccentIntensity','Accent intensity',['Subtle','Normal','Strong']),
                        ('OpaqueApplications','Always opaque applications',None)],
        'Glass': [('WindowOpacity','Window opacity',None),('PopupOpacity','Popup/menu opacity',None),
                  ('BlurSurfaces','Blur application surfaces',None),('TitlebarOpacity','Active titlebar opacity',None),
                  ('InactiveOpacity','Inactive titlebar opacity',None),('Blur','Blur titlebar',None)],
        'Window Decoration': [('CornerRadius','Corner radius',None),('RoundBottomCorners','Round bottom corners',None),('BorderWidth','Border width',None),
                              ('Separator','Titlebar/content separator',None),
                              ('TitlebarSize','Titlebar size',['Compact','Normal','Comfortable']),
                              ('TitleAlignment','Title alignment',['Left','Center']),
                              ('ActiveAccentBorder','Active accent border',None),
                              ('Shadow','Shadow',['Off','Subtle','Normal','Strong'])],
        'Controls': [('ButtonStyle','Button style',['Line','Dots','Traffic lights']),
                     ('ButtonSize','Button size',['Compact','Normal','Large']),
                     ('ButtonSpacing','Button spacing',['Tight','Normal','Wide']),
                     ('InactiveButtons','Inactive window buttons',['Normal','Dimmed'])]}
    ns={'k':'http://www.kde.org/standards/kcfg/1.0'}
    lookup={e.get('name'):e for e in entries}
    out=['<?xml version="1.0" encoding="UTF-8"?><ui version="4.0"><class>GlassyConfig</class><widget class="QWidget" name="GlassyConfig"><layout class="QVBoxLayout" name="mainLayout"><item><widget class="QTabWidget" name="sections">']
    for group, rows in fields.items():
        name=group.replace(' ','')
        out.append(f'<widget class="QWidget" name="{name}"><attribute name="title"><string>{group}</string></attribute><layout class="QFormLayout" name="{name}Layout">')
        for row,(key,label,choices) in enumerate(rows):
            entry=lookup[key]; kind=entry.get('type')
            out.append(f'<item row="{row}" column="0"><widget class="QLabel" name="{key}Label"><property name="text"><string>{escape(label)}:</string></property><property name="buddy"><cstring>kcfg_{key}</cstring></property></widget></item>')
            cls='QComboBox' if choices else 'QCheckBox' if kind=='Bool' else 'QLineEdit' if kind=='String' else 'QSpinBox'
            out.append(f'<item row="{row}" column="1"><widget class="{cls}" name="kcfg_{key}">')
            if choices:
                for choice in choices: out.append(f'<item><property name="text"><string>{choice}</string></property></item>')
            elif kind=='String':
                out.append('<property name="toolTip"><string>Comma-separated application names (as in their process name). Kvantum keeps their windows opaque.</string></property>')
            elif kind=='Int':
                for field,prop in [('min','minimum'),('max','maximum')]: out.append(f'<property name="{prop}"><number>{entry.find("k:"+field,ns).text}</number></property>')
                out.append(f'<property name="suffix"><string>{" %" if "Opacity" in key else " px"}</string></property>')
            out.append('</widget></item>')
        if group=='Window Decoration':
            out.append('<item row="9" column="1"><widget class="QCheckBox" name="unavailableMaximizedRounding"><property name="enabled"><bool>false</bool></property><property name="text"><string>Round maximized windows (unavailable)</string></property><property name="toolTip"><string>Aurorae 6.7 forces a rectangular maximized blur region. Maximized and tiled windows stay square.</string></property></widget></item>')
        out.append('</layout></widget>')
    out.append('</widget></item><item><widget class="QLabel" name="limits"><property name="wordWrap"><bool>true</bool></property><property name="text"><string>Apply reloads running KDE applications with the new look. Titlebar blur strength belongs to KWin; Aurorae forces maximized blur. Bottom rounding reserves a decoration strip derived from Corner radius; application content is not covered.</string></property></widget></item></layout></widget><resources/><connections/></ui>')
    return ''.join(out)


def assets(package):
    ns={'k':'http://www.kde.org/standards/kcfg/1.0'}
    entries=ET.parse(package / 'contents/config/main.xml').findall('.//k:entry',ns)
    defaults={}; limits={}
    for entry in entries:
        value=entry.find('k:default',ns).text
        key=entry.get('name')
        kind=entry.get('type')
        defaults[key]=value=='true' if kind=='Bool' else (value or '') if kind=='String' else int(value)
        if entry.get('type')=='Int':
            limits[key]=[int(entry.find('k:min',ns).text),int(entry.find('k:max',ns).text)]
    js='// Generated from contents/config/main.xml. Do not edit.\n.pragma library\n'
    js+='var defaults = '+json.dumps(defaults)+';\nvar limits = '+json.dumps(limits)+';\n'
    # Use the frame's own alpha as the mask (FrameSvg::alphaMask fallback).
    # KSvg 6.30's separate maskFrame cache does not invalidate on prefix changes;
    # mask-rN-* would retain the previous radius, including when blur is disabled.
    # This invisible FrameSvg needs no second mask layer. Fixed shadow padding,
    # variable corner size, with optional lower decoration corners.
    svg=['<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128">']
    for r in range(limits['CornerRadius'][1]+1):
        prefix = r
        # Aurorae contracts its QRegion by 1px and translates it by (+1,+1).
        # Parallel inset geometry: same circle center, radius reduced by 1.
        r = max(0, r - 1)
        a=12; k=max(1,r); m=a+k
        corner=(f'<path d="M{m} {a} A{r} {r} 0 0 0 {a} {m} H{m}Z"/>' if r else
                f'<rect x="{a}" y="{a}" width="{k}" height="{k}"/>')
        shapes={
            'topleft':(m,m,corner),
            'topright':(m,m,f'<g transform="translate({m},0) scale(-1,1)">{corner}</g>'),
            'top':(8,m,f'<rect y="{a}" width="8" height="{k}"/>'),
            'left':(m,8,f'<rect x="{a}" width="{k}" height="8"/>'),
            'right':(m,8,f'<rect width="{k}" height="8"/>'),
            'bottomleft':(m,a+1,f'<rect x="{a}" width="{k}" height="1"/>'),
            'bottomright':(m,a+1,f'<rect width="{k}" height="1"/>'),
            'bottom':(8,a+1,'<rect width="8" height="1"/>'),
            'center':(8,8,'<rect width="8" height="8"/>')}
        for part,(w,h,shape) in shapes.items():
            svg.append(f'<g id="r{prefix}-{part}"><rect width="{w}" height="{h}" fill="none"/>{shape}</g>')
        shapes.update({
            'bottomleft':(m,m,f'<g transform="translate(0,{m}) scale(1,-1)">{corner}</g>'),
            'bottomright':(m,m,f'<g transform="translate({m},{m}) scale(-1,-1)">{corner}</g>'),
            'bottom':(8,m,f'<rect width="8" height="{k}"/>')})
        for part,(w,h,shape) in shapes.items():
            svg.append(f'<g id="b{prefix}-{part}"><rect width="{w}" height="{h}" fill="none"/>{shape}</g>')
    svg.append('<rect id="off-center" width="8" height="8" fill="none"/>')
    svg.append('</svg>\n')
    return {'contents/ui/ConfigDefaults.js':js,'contents/assets/masks.svg':'\n'.join(svg),
            'contents/ui/config.ui':config_ui(entries)}
