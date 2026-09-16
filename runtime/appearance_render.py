"""Glassy palette assets. Fill-only nine-slice geometry avoids QtSvg stroke bounds."""
from xml.sax.saxutils import escape
from glassy_settings import metrics, settings

STATES = ('normal', 'focused', 'pressed', 'toggled', 'disabled')


def mix(a, b, amount):
    return '#' + ''.join(f'{round(int(a[i:i+2],16)*(1-amount)+int(b[i:i+2],16)*amount):02x}'
                         for i in (1, 3, 5))


def frame(name, fill, edge, radius=4, border=1):
    """Exact rectangular bounds; strokes must never enlarge a slice."""
    r, b = max(1, radius, border), border
    k = r-b
    corner = (f'<path d="M0 {r} A{r} {r} 0 0 1 {r} 0 V{r}Z" fill="{edge}"/>'
              f'<path d="M{b} {r} A{k} {k} 0 0 1 {r} {b} V{r}Z" fill="{fill}"/>')
    if fill == 'none':
        corner = f'<path d="M0 {r} A{r} {r} 0 0 1 {r} 0 V{b} A{k} {k} 0 0 0 {b} {r}Z" fill="{edge}"/>'
    if radius == 0:
        corner = (f'<rect width="{r}" height="{r}" fill="{edge}"/>'
                  f'<rect x="{b}" y="{b}" width="{k}" height="{k}" fill="{fill}"/>')
        if fill == 'none':
            corner = f'<path d="M0 0H{r}V{b}H{b}V{r}H0Z" fill="{edge}"/>'
    horizontal = f'<rect width="8" height="{b}" fill="{edge}"/><rect y="{b}" width="8" height="{k}" fill="{fill}"/>'
    vertical = f'<rect width="{b}" height="8" fill="{edge}"/><rect x="{b}" width="{k}" height="8" fill="{fill}"/>'
    pieces = {
        'topleft': (r,r,'',corner), 'topright': (r,r,f'translate({r},0) scale(-1,1)',corner),
        'bottomleft': (r,r,f'translate(0,{r}) scale(1,-1)',corner),
        'bottomright': (r,r,f'translate({r},{r}) scale(-1,-1)',corner),
        'top': (8,r,'',horizontal), 'bottom': (8,r,f'translate(0,{r}) scale(1,-1)',horizontal),
        'left': (r,8,'',vertical), 'right': (r,8,f'translate({r},0) scale(-1,1)',vertical)}
    result=[]
    for part,(w,h,transform,shape) in pieces.items():
        result.append(f'<g id="{name}-{part}"><rect width="{w}" height="{h}" fill="none"/>'
                      f'<g transform="{transform or "translate(0,0)"}">{shape}</g></g>')
    result.append(f'<rect id="{name}" width="8" height="8" fill="{fill}"/>')
    return '\n'.join(result)


def popup_shadow(name, fill, edge, radius, depth):
    """Native Kvantum *-shadow atlas, including exact shadow-hint extents.

    Missing these IDs silently inherited Kvantum's default menu artwork, which
    was the real source of the heavy popup outline despite our 1px normal frame.
    """
    r=max(1,radius); size=depth+r
    corner=[]; horizontal=[]; vertical=[]
    for inset in range(depth):
        k=size-inset
        corner.append(f'<path d="M{inset} {size} A{k} {k} 0 0 1 {size} {inset} V{size}Z" fill="black" fill-opacity=".035"/>')
        horizontal.append(f'<rect y="{inset}" width="8" height="{size-inset}" fill="black" fill-opacity=".035"/>')
        vertical.append(f'<rect x="{inset}" width="{size-inset}" height="8" fill="black" fill-opacity=".035"/>')
    for offset,color in ((depth,edge),(depth+1,fill)):
        k=size-offset
        if k<=0: continue
        corner.append((f'<path d="M{offset} {size} A{k} {k} 0 0 1 {size} {offset} V{size}Z" fill="{color}"/>' if radius else
                       f'<rect x="{offset}" y="{offset}" width="{k}" height="{k}" fill="{color}"/>'))
        horizontal.append(f'<rect y="{offset}" width="8" height="{size-offset}" fill="{color}"/>')
        vertical.append(f'<rect x="{offset}" width="{size-offset}" height="8" fill="{color}"/>')
    c,h,v=map(''.join,(corner,horizontal,vertical))
    parts={'topleft':(size,size,'',c),'topright':(size,size,f'translate({size},0) scale(-1,1)',c),
           'bottomleft':(size,size,f'translate(0,{size}) scale(1,-1)',c),
           'bottomright':(size,size,f'translate({size},{size}) scale(-1,-1)',c),
           'top':(8,size,'',h),'bottom':(8,size,f'translate(0,{size}) scale(1,-1)',h),
           'left':(size,8,'',v),'right':(size,8,f'translate({size},0) scale(-1,1)',v)}
    out=[]
    for side,(w,h,transform,shape) in parts.items():
        out.append(f'<g id="{name}-shadow-{side}"><rect width="{w}" height="{h}" fill="none"/><g transform="{transform or "translate(0,0)"}">{shape}</g></g>')
    for side in ('left','right','top','bottom'):
        w,h=(depth,8) if side in ('left','right') else (8,depth)
        out.append(f'<rect id="{name}-shadow-hint-{side}" width="{w}" height="{h}" fill="none"/>')
    return '\n'.join(out)


def render(p, options=None):
    m = metrics(options or settings())
    out=['<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64">']
    # Generic focus is stateless and Kvantum caps its margins at 2px.
    accent=mix(p['button'],p['highlight'],m['accent'])
    out.append(frame('focus', 'none', accent, min(m['radius'],2)))
    kinds=('button','input','tab','menu','tooltip','selection','focus','scroll','groove','progress','header','group')
    for kind in kinds:
        for state in (*STATES, 'focus'):
            fill = p['base'] if kind=='input' else p['window'] if kind in ('menu','group') else p['button']
            edge = mix(fill,p['text'],m['popup_border'] if kind=='menu' else m['border'])
            if state=='focused': fill=mix(fill,p['text'],.05); edge=mix(fill,p['text'],m['border']+.08 if m['border'] else 0)
            if kind=='input' and state=='focused': edge=accent
            if state in ('pressed','toggled'): fill=mix(fill,p['highlight'],m['pressed']); edge=accent
            if kind=='selection':
                fill='none' if state=='normal' else accent; edge=fill
            if kind in ('focus','group') or state=='focus':
                fill='none'; edge=accent if kind=='focus' or state=='focus' else mix(p['window'],p['text'],m['border']*8/9)
            if kind=='scroll':
                fill=mix(p['window'],p['text'],.40 if state=='normal' else .58); edge=fill
            if kind=='groove': fill=mix(p['window'],p['text'],.14); edge=fill
            if kind=='progress': fill=p['highlight']; edge=fill
            if kind=='header': fill=p['button']; edge=fill
            if state=='disabled' and fill!='none': fill=mix(fill,p['window'],.4); edge=mix(edge,p['window'],.4)
            # Menu frame is never an interactive/focused control. One quiet
            # 1px contour across QMenu, combo popups and inherited ToolTip.
            if kind in ('menu','tooltip'): fill=p['window']; edge=mix(fill,p['text'],m['popup_border'])
            radius=min(m['radius'],2) if kind in ('groove','progress','header') else m['radius']
            if kind=='scroll': radius=min(radius,m['scroll']//2)
            out.append(frame(kind+'-'+state,fill,edge,radius))
    for kind,depth in (('menu',6),('tooltip',4)):
        out.append(popup_shadow(kind,p['window'],mix(p['window'],p['text'],m['popup_border']),m['radius'],depth))
    # Kvantum check/radio states are single interiors, not frame indicators.
    for kind in ('check','radio'):
        for checked in ('','checked-','tristate-'):
            for state in ('normal','focused'):
                active=bool(checked); fill=p['highlight'] if active else p['button']
                edge=accent if state=='focused' or active else mix(fill,p['text'],m['border']*5/3)
                ink=p['highlight_text']
                shape=(f'<circle cx="8" cy="8" r="7.5" fill="{edge}"/><circle cx="8" cy="8" r="6.5" fill="{fill}"/>' if kind=='radio' else
                       f'<rect x=".5" y=".5" width="15" height="15" rx="{m["radius"]}" fill="{edge}"/><rect x="1.5" y="1.5" width="13" height="13" rx="{max(0,m["radius"]-1)}" fill="{fill}"/>')
                if active:
                    if kind=='radio': shape+=f'<circle cx="8" cy="8" r="3" fill="{ink}"/>'
                    else: shape+=f'<path d="{"M4 8H12" if checked=="tristate-" else "M4 8L7 11L12 5"}" fill="none" stroke="{ink}" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>'
                out.append(f'<g id="{kind}-{checked}{state}"><rect width="16" height="16" fill="none"/>{shape}</g>')
    paths={'arrow-down':'M4 6L8 10L12 6','arrow-up':'M4 10L8 6L12 10',
           'arrow-left':'M10 4L6 8L10 12','arrow-right':'M6 4L10 8L6 12',
           'arrow-plus':'M4 8H12M8 4V12','arrow-minus':'M4 8H12',
           'tree-plus':'M6 4L10 8L6 12','tree-minus':'M4 6L8 10L12 6',
           'tab-close':'M5 5L11 11M11 5L5 11','grip':'M6 12L12 6M10 12L12 10'}
    for kind,path in paths.items():
        for state in (*STATES,'toggledFocused','toggledPressed'):
            ink=p.get('inactive_text',p['text']) if state=='disabled' else p['text']
            out.append(f'<g id="{kind}-{state}"><rect width="16" height="16" fill="none"/>'
                       f'<path d="{path}" fill="none" stroke="{escape(ink)}" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></g>')
    for state in STATES:
        out.append(f'<g id="handle-{state}"><rect width="18" height="18" fill="none"/>'
                   f'<circle cx="9" cy="9" r="8.5" fill="{p["highlight"]}"/><circle cx="9" cy="9" r="6.5" fill="{p["button"]}"/></g>')
    out.append('<rect id="header-separator" width="1" height="8" fill="none"/>')
    out.append('</svg>\n')
    return '\n'.join(out)
