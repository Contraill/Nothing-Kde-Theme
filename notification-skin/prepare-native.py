#!/usr/bin/env python3
"""Build an isolated Plasma 6.7.4 popup delegate adapter from pinned KDE source.
No native files, DBus services, or live panel configurations are modified.
"""
import argparse, hashlib, json, os, pathlib, re, shutil, sys, urllib.request

ROOT = pathlib.Path(__file__).resolve().parent
VERSION = '0.6.0-rc32'
NATIVE = '6.7.4'
MODULE = 'plasma.applet.org.kde.plasma.notifications'
RESOURCE = 'qrc:/qt/qml/plasma/applet/org/kde/plasma/notifications/components'
SOURCES = {
    'Globals.qml': ('applets/notifications/global/Globals.qml', '15f893d6e2b763aa33728f17068c98ea952f23a5'),
    'NotificationPopup.qml': ('applets/notifications/NotificationPopup.qml', 'bfc68dfe8bcc7d2296b8467d07b9beeb1895b4e2'),
}


def git_blob(data):
    return hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()


def verified_source(name, source_dir=None):
    relative, expected = SOURCES[name]
    if source_dir:
        path = pathlib.Path(source_dir) / relative
        data = path.read_bytes()
    else:
        cache = ROOT / 'upstream-cache' / NATIVE / name
        if cache.is_file() and git_blob(cache.read_bytes()) == expected:
            data = cache.read_bytes()
        else:
            url = 'https://raw.githubusercontent.com/KDE/plasma-workspace/v' + NATIVE + '/' + relative
            with urllib.request.urlopen(url, timeout=25) as response:
                data = response.read(1024 * 1024 + 1)
            if len(data) > 1024 * 1024:
                raise ValueError('Upstream source exceeded its size limit')
            if git_blob(data) != expected:
                raise ValueError('KDE upstream source hash mismatch: ' + name)
            cache.parent.mkdir(parents=True, exist_ok=True)
            cache.write_bytes(data)
    if git_blob(data) != expected:
        raise ValueError('KDE upstream source hash mismatch: ' + name)
    return data.decode('utf-8')


def block(text, anchor):
    """Extract one brace-balanced QML block, ignoring strings and comments."""
    start = text.find(anchor)
    if start < 0:
        raise ValueError('Missing upstream anchor: ' + anchor)
    opening = text.find('{', start + len(anchor) - 1)
    if opening < 0:
        raise ValueError('Missing opening brace')
    depth, i, mode = 0, opening, 'code'
    while i < len(text):
        c = text[i]
        n = text[i+1] if i+1 < len(text) else ''
        if mode == 'line':
            if c == '\n': mode = 'code'
        elif mode == 'comment':
            if c == '*' and n == '/': mode = 'code'; i += 1
        elif mode in ('"', "'", '`'):
            if c == '\\': i += 1
            elif c == mode: mode = 'code'
        elif c == '/' and n == '/': mode = 'line'; i += 1
        elif c == '/' and n == '*': mode = 'comment'; i += 1
        elif c in ('"', "'", '`'): mode = c
        elif c == '{': depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0: return text[start:i+1]
        i += 1
    raise ValueError('Unbalanced upstream QML block')


def generate(globals_text, popup_text, output):
    output = pathlib.Path(output)
    # Fail closed on a different upstream implementation instead of guessing.
    delegate = block(globals_text, '        delegate: NotificationPopup {')
    if 'required property string notificationId' not in delegate or 'onExpired:' not in delegate or 'onReplied:' not in delegate:
        raise ValueError('Unexpected native notification delegate contract')
    delegate = delegate.replace('delegate: NotificationPopup {', 'NothingNotificationPopup {', 1)
    delegate = '\n'.join(line[8:] if line.startswith('        ') else line for line in delegate.splitlines())
    if 'globals.' in delegate:
        used = set(re.findall(r'globals\.([A-Za-z_][A-Za-z_0-9]*)', delegate))
        allowed = {'popupNotificationsModel', 'notificationSettings', 'tasksModel', 'plasmoid',
                   'popupWidth', 'inhibited', 'positionPopups'}
        if used - allowed:
            raise ValueError('Unmapped native Globals references: ' + ', '.join(sorted(used-allowed)))
    # Bind directly to KDE's singleton, including callbacks. A copied delegate
    # no longer has the lexical scope of the original Globals.qml.
    delegate = delegate.replace('globals.', 'Notifications.Globals.')
    # KDE's ModelInterface declares jobError as int (zero means no error).
    delegate = delegate.replace('required property string jobError', 'required property int jobError')
    delegate = delegate.replace('    id: popup', '    id: popup\n    nothingLightMode: globals.nothingLightMode', 1)
    if 'NotificationsApplet.NotificationWindow {' not in popup_text or 'contentItem: Delegates.DelegatePopup {' not in popup_text:
        raise ValueError('Unexpected native NotificationPopup contract')
    popup_text = popup_text.replace('    contentItem: Delegates.DelegatePopup {', '    contentItem: Delegates.NothingDelegatePopup {', 1)
    popup_text = popup_text.replace('            contentItem: Delegates.DelegatePopup {', '            contentItem: Delegates.NothingDelegatePopup {', 1)
    popup_text = popup_text.replace('        DraggableDelegate {', '        NotificationsApplet.DraggableDelegate {')
    popup_text = popup_text.replace('topMargin: notificationPopup.modelInterface.closable || notificationPopup.modelInterface.dismissable || notificationPopup.modelInterface.configurable ? -notificationPopup.topPadding : 0', 'topMargin: 0')
    popup_text = popup_text.replace('    property int popupWidth', '    property bool nothingLightMode: false\n    property int popupWidth', 1)
    popup_text = popup_text.replace('                id: notificationItem',
        '                id: notificationItem\n                lightMode: notificationPopup.nothingLightMode\n                showTimeout: notificationPopup.showPopupTimeout', 1)
    if 'Delegates.NothingDelegatePopup {' not in popup_text:
        raise ValueError('Native popup content replacement failed')
    # The native module owns the QML types and timers; only the visual delegate changes.
    controller = (ROOT / 'native-controller.qml.in').read_text().replace('@@NATIVE_DELEGATE@@', delegate)
    if globals_text.startswith('/*'):
        controller = globals_text.split('*/', 1)[0] + '*/\n\n' + controller
    if '@@' in controller:
        raise ValueError('Unexpanded controller template')
    if output.exists():
        # Never recursively delete an arbitrary caller-supplied output directory.
        metadata = output / 'metadata.json'
        if not metadata.is_file() or json.loads(metadata.read_text()).get('KPlugin', {}).get('Id') != 'com.nothingplasma.notificationbridge':
            raise ValueError('Output exists and is not a generated Nothing notification package')
        shutil.rmtree(output)
    ui = output / 'contents' / 'ui'
    (ui / 'delegates').mkdir(parents=True)
    meta = {
        'KPackageStructure': 'Plasma/Applet',
        'KPlugin': {'Id':'com.nothingplasma.notificationbridge','Name':'Nothing KDE Notification Bridge',
                    'Description':'Theme-scoped notification renderer using the existing KDE notification backend',
                    'Version':VERSION,'License':'GPL-3.0-only','EnabledByDefault':False,
                    'Icon':'preferences-desktop-notification-bell'},
        'X-Plasma-API-Minimum-Version':'6.0','NoDisplay':True
    }
    (output/'metadata.json').write_text(json.dumps(meta, indent=2)+'\n')
    config=output/'contents/config'
    config.mkdir(parents=True,exist_ok=True)
    (config/'main.xml').write_text('<kcfg xmlns="http://www.kde.org/standards/kcfg/1.0"><kcfgfile name=""/><group name="General"><entry name="enabled" type="Bool"><default>true</default></entry><entry name="diagnostics" type="Bool"><default>false</default></entry></group></kcfg>\n')
    (ui/'main.qml').write_text(controller+'\n')
    (ui/'NothingNotificationPopup.qml').write_text(popup_text)
    for name in ('NothingDelegatePopup.qml','NothingNotificationGlyph.qml','NothingDotMatrixLabel.qml','NothingGlyphEdgeLights.qml'):
        content = (ROOT/'delegates'/name).read_text()
        if name == 'NothingDelegatePopup.qml':
            content = content.replace('import "../components" as Components', 'import "'+RESOURCE+'" as Components')
        (ui/'delegates'/name).write_text(content)
    (output/'UPSTREAM.json').write_text(json.dumps({'version':NATIVE,'sources':SOURCES},indent=2)+'\n')
    if (ROOT.parent/'LICENSES').is_dir():
        shutil.copytree(ROOT.parent/'LICENSES', output/'LICENSES')
    return output


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--source-dir',help='Local extracted KDE plasma-workspace v6.7.4 source tree')
    parser.add_argument('--output',default=str(ROOT/'build'/'com.nothingplasma.notificationbridge'))
    args=parser.parse_args()
    result=generate(verified_source('Globals.qml',args.source_dir),verified_source('NotificationPopup.qml',args.source_dir),args.output)
    print('Prepared pinned native notification adapter:',result)

if __name__=='__main__':
    try: main()
    except Exception as exc:
        print('Notification preparation failed without changing KDE:',exc,file=sys.stderr)
        sys.exit(1)
