#!/usr/bin/env python3
"""Read installed Qt resources, then check the adapter's private QML contract.

Patch versions are not an API. This conservative check allows changed unrelated
Globals implementation and whitespace/comments, but refuses changed delegates.
It never imports Globals (which could initialize native notification state).
"""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('notification_prepare', ROOT / 'prepare-native.py')
prepare = importlib.util.module_from_spec(spec)
spec.loader.exec_module(prepare)


def tokens(text):
    # Preserve strings; ignore comments/formatting only, not executable tokens.
    pattern = r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|`(?:\\.|[^`\\])*`|//[^\n]*|/\*[\s\S]*?\*/|\w+|[^\s]'
    return [m[0] for m in re.finditer(pattern, text) if not m[0].startswith(('//', '/*'))]


def declarations(text):
    """QML property/signal signatures, independent of bindings and formatting."""
    text = ' '.join(tokens(text))
    properties = set(re.findall(r'\bproperty\s+([\w.]+)\s+(\w+)', text))
    signals = set(re.findall(r'\bsignal\s+(\w+)', text))
    return properties, signals


def validate(sources):
    native = sources['global/Globals.qml']
    pinned = prepare.verified_source('Globals.qml')
    # Extract the delegate with flexible whitespace, but compare every model
    # role and callback. Anything new needs an explicit adapter review.
    def delegate(text):
        text = re.sub(r'delegate\s*:\s*NotificationPopup\s*\{', 'delegate: NotificationPopup {', text)
        return prepare.block(text, 'delegate: NotificationPopup {')
    if tokens(delegate(native)) != tokens(delegate(pinned)):
        raise ValueError('Native notification delegate/model contract changed')
    actual = declarations(sources['NotificationPopup.qml'])
    expected = declarations(prepare.verified_source('NotificationPopup.qml'))
    if any(not required <= found for required, found in zip(expected, actual)):
        raise ValueError('Native popup property/signal contract changed')
    for anchor in ('NotificationsApplet.NotificationWindow {', 'contentItem: Delegates.DelegatePopup {'):
        normalized = ' '.join(tokens(sources['NotificationPopup.qml']))
        if ' '.join(tokens(anchor)) not in normalized:
            raise ValueError('Native popup composition changed')
    for name in ('plasmoid', 'popupInstantiator', 'popupNotificationsModel', 'notificationSettings',
                 'tasksModel', 'popupWidth', 'inhibited', 'screenRect', 'popupLocation',
                 'popupEdgeDistance', 'popupSpacing'):
        if not re.search(r'\bproperty\s+[\w.]+\s+' + name + r'\s*:', native):
            raise ValueError('Missing native Globals property: ' + name)
    if not re.search(r'\bfunction\s+positionPopups\s*\(', native):
        raise ValueError('Missing native popup positioning API')
    qmldir = sources['qmldir']
    for name in ('DraggableDelegate', 'Globals'):
        if name not in qmldir:
            raise ValueError('Missing native QML type: ' + name)
    if sources.get('NotificationWindow') != 'available':
        raise ValueError('Missing native NotificationWindow API')
    model = sources['components/ModelInterface.qml']
    delegate_text = (ROOT / 'delegates/NothingDelegatePopup.qml').read_text()
    for name in set(re.findall(r'modelInterface\.(\w+)', delegate_text)):
        if not re.search(r'\b(?:property\s+[\w.<>]+|function|signal)\s+' + name + r'\b', model):
            raise ValueError('Missing model API: ' + name)
    # The custom delegate reuses these native components. Verify the properties
    # it binds rather than a distro version string.
    contracts = {'Body': ('modelInterface',), 'Icon': ('modelInterface',),
                 'FooterLoader': ('modelInterface',)}
    for component, names in contracts.items():
        text = sources['components/' + component + '.qml']
        for name in names:
            if not re.search(r'\bproperty\s+[\w.]+\s+' + name + r'\b', text):
                raise ValueError('Missing component API: ' + component + '.' + name)


def installed_sources():
    compiler, pkgconfig = shutil.which('c++'), shutil.which('pkg-config')
    if not compiler or not pkgconfig:
        raise ValueError('Resource inspection needs a C++ compiler, pkg-config and Qt 6 Core/Qml/Gui headers')
    flags = subprocess.check_output([pkgconfig, '--cflags', '--libs', 'Qt6Core', 'Qt6Qml', 'Qt6Gui'], text=True)
    with tempfile.TemporaryDirectory(prefix='nothing-notification-contract-') as td:
        probe = Path(td) / 'read-resources'
        subprocess.run([compiler, '-std=c++17', '-fPIC', str(ROOT / 'read-resources.cpp'),
                        '-o', str(probe), *shlex.split(flags)], check=True,
                       capture_output=True, text=True, timeout=60)
        env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QPA_PLATFORMTHEME='generic',
                   QML_DISABLE_DISK_CACHE='1', XDG_CONFIG_HOME=td + '/config',
                   XDG_DATA_HOME=td + '/data', XDG_CACHE_HOME=td + '/cache',
                   DBUS_SESSION_BUS_ADDRESS='unix:path=' + td + '/no-session')
        result = subprocess.run([str(probe)], env=env, check=True, capture_output=True, text=True, timeout=20)
        return json.loads(result.stdout)


def main():
    argparse.ArgumentParser(description=__doc__).parse_args()
    try:
        validate(installed_sources())
    except (ValueError, KeyError, OSError, subprocess.SubprocessError) as error:
        print('Notification compatibility not established:', error)
        return 3
    print('Installed notification QML/API contract is compatible.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
