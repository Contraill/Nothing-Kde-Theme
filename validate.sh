#!/usr/bin/env bash
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

while IFS= read -r -d '' file; do
  python3 -m json.tool "$file" >/dev/null
done < <(find "$ROOT" -name metadata.json -print0)

python3 - <<'PY' "$ROOT/plasmoids/com.nothingplasma.panel/contents/config/main.xml"
import sys, xml.etree.ElementTree as ET
ET.parse(sys.argv[1])
PY

python3 - <<'PY' "$ROOT/plasmoids/com.nothingplasma.panel/metadata.json"
import json, pathlib, sys
p = pathlib.Path(sys.argv[1])
data = json.loads(p.read_text())
plugin_id = data.get('KPlugin', {}).get('Id')
folder_id = p.parent.name
if plugin_id != folder_id:
    raise SystemExit(f'KPlugin.Id ({plugin_id!r}) does not match package folder ({folder_id!r})')
if data.get('KPackageStructure') != 'Plasma/Applet':
    raise SystemExit('KPackageStructure must be Plasma/Applet')
if data.get('X-Plasma-ContainmentType') != 'Panel':
    raise SystemExit('X-Plasma-ContainmentType must be Panel')
if data.get('NoDisplay') is not True:
    raise SystemExit('Panel containment must set NoDisplay=true so it does not appear in Add Widgets')
if not (p.parent / 'contents/ui/main.qml').is_file():
    raise SystemExit('contents/ui/main.qml is missing')
for rel in [
    'contents/ui/TopPanel.qml',
    'contents/ui/BottomPanel.qml',
    'contents/island/ui/ExpandedPanel.qml',
    'contents/island/ui/CompactPill.qml',
    'contents/ui/components/DotGlyph.qml',
    'contents/ui/components/SystemStats.qml',
    'contents/ui/components/TaskPreviewContent.qml',
    'contents/ui/components/PanelRoleMetrics.qml',
    'contents/ui/components/NothingPalette.qml',
    'contents/ui/components/PopupShell.qml',
    'contents/ui/components/NothingPopupWindow.qml',
    'contents/ui/components/SystemControls.qml',
    'contents/island/ui/AccentSettings.qml',
    'contents/ui/components/LauncherSettingsPage.qml',
]:
    if not (p.parent / rel).is_file():
        raise SystemExit(f'{rel} is missing')
PY

python3 - <<'PY' "$ROOT/plasma/layout-templates/com.nothingplasma.island.panel/metadata.json" "$ROOT/plasma/layout-templates/com.nothingplasma.island.panel/contents/layout.js"
import json, pathlib, sys
meta = json.loads(pathlib.Path(sys.argv[1]).read_text())
if meta.get("KPackageStructure") != "Plasma/LayoutTemplate":
    raise SystemExit("Panel preset KPackageStructure must be Plasma/LayoutTemplate")
if "panel" not in meta.get("X-Plasma-ContainmentCategories", []):
    raise SystemExit("Panel preset must advertise the panel containment category")
layout = pathlib.Path(sys.argv[2]).read_text()
if 'new Panel("com.nothingplasma.panel")' not in layout:
    raise SystemExit("Panel preset must create com.nothingplasma.panel")
PY


# System-control icons must use the local dotted glyph language. Real app/window
# icons are intentionally allowed only in LauncherPage and TaskStrip.
while IFS= read -r file; do
  case "$file" in
    */LauncherPage.qml|*/LauncherSettingsPage.qml|*/TaskStrip.qml|*/TaskPreviewContent.qml|*/TrayStrip.qml) ;;
    *)
      if grep -q 'Kirigami.Icon' "$file"; then
        printf 'Non-dotted system icon found in %s. Validation failed.
' "$file" >&2
        exit 1
      fi
      ;;
  esac
done < <(find "$ROOT/plasmoids/com.nothingplasma.panel/contents/ui/components" -name '*.qml' -type f)

# Plasma 6 enum properties must use their symbolic enum values. Raw integers can
# pass qmllint in some contexts but fail at runtime with "unknown enumeration".
if grep -RInE 'Plasmoid\.(backgroundHints|status|formFactor|location)[[:space:]]*:[[:space:]]*[0-9]+' \
  "$ROOT/plasmoids/com.nothingplasma.panel/contents"; then
  printf '\nRaw numeric Plasma enum assignment found. Validation failed.\n' >&2
  exit 1
fi


# Plasma 6 current-syntax guardrails. These catch legacy context/import patterns
# that may still run but generate qmllint warnings or bind to the wrong object.
if grep -RInE '\bplasmoid\.configuration\b|target:[[:space:]]*plasmoid\b|appletInterface:[[:space:]]*plasmoid\b' \
  "$ROOT/plasmoids/com.nothingplasma.panel/contents"; then
  printf '\nLegacy lowercase plasmoid context access found. Use Plasmoid / explicit QML item references. Validation failed.\n' >&2
  exit 1
fi

if grep -RInE '^import[[:space:]]+org\.kde\.plasma\.[^[:space:]]+[[:space:]]+[0-9]+\.[0-9]+' \
  "$ROOT/plasmoids/com.nothingplasma.panel/contents"; then
  printf '\nVersioned Plasma QML import found. Plasma 6 packages should use versionless module imports. Validation failed.\n' >&2
  exit 1
fi

# QtQuick.Window's QQuickScreenInfo does not expose QScreen::availableGeometry.
# Use the QML ScreenInfo properties instead.
if grep -RInE '\bscreen\.availableGeometry\b' \
  "$ROOT/plasmoids/com.nothingplasma.panel/contents"; then
  printf '\nQQuickScreenInfo.availableGeometry is not a QML property. Use virtualX/virtualY + desktopAvailableWidth/desktopAvailableHeight. Validation failed.\n' >&2
  exit 1
fi

# Loader.item is QObject to qmllint. Role sizing must flow through the typed
# PanelRoleMetrics bridge rather than reading implicit geometry from Loader.item.
if grep -RInE '\broleLoader\.item\.(implicitWidth|implicitHeight)\b' \
  "$ROOT/plasmoids/com.nothingplasma.panel/contents"; then
  printf '\nUntyped Loader role geometry access found. Use PanelRoleMetrics. Validation failed.\n' >&2
  exit 1
fi

# Loader.item is typed as QObject to qmllint. Do not invoke page-specific methods
# through an untyped Loader alias; keep a strongly typed QML reference instead.
if grep -RInE '\bpageItem\.(openSection|closeSection)\(' \
  "$ROOT/plasmoids/com.nothingplasma.panel/contents"; then
  printf '\nUntyped Loader pageItem method call found. Use a typed component reference. Validation failed.\n' >&2
  exit 1
fi


# Loader.item is QObject to qmllint. Global shortcut dispatch must use the typed
# shortcutEpoch bridge rather than probing/calling custom methods dynamically.
if grep -RInE '\broleLoader\.item\.[A-Za-z_][A-Za-z0-9_]*' \
  "$ROOT/plasmoids/com.nothingplasma.panel/contents/ui/main.qml"; then
  printf '\nUntyped Loader.item member access found in root shortcut dispatch. Validation failed.\n' >&2
  exit 1
fi

# Responsive sizing guardrails: popup geometry is percentage-based and the
# island width percentage is only a cap, never a forced pixel width.
if grep -RInE 'name="(launcherWidth|launcherHeight|quickWidth|quickHeight|wifiWidth|wifiHeight|bluetoothWidth|bluetoothHeight|audioWidth|audioHeight|displayWidth|displayHeight|powerDetailWidth|powerDetailHeight|calendarWidth|calendarHeight|powerWidth|powerHeight)"' \
  "$ROOT/plasmoids/com.nothingplasma.panel/contents/config/main.xml"; then
  printf '\nLegacy fixed-pixel popup geometry keys found. Validation failed.\n' >&2
  exit 1
fi

# Two-panel architecture and native popup guardrails.
python3 - <<'PY2' "$ROOT/plasmoids/com.nothingplasma.panel/contents/ui/main.qml" "$ROOT/plasmoids/com.nothingplasma.panel/contents/ui/components/NothingPopupWindow.qml" "$ROOT/plasmoids/com.nothingplasma.panel/contents/island/ui/Battery.qml" "$ROOT/plasma/layout-templates/com.nothingplasma.island.panel/contents/layout.js"
import pathlib, sys
main = pathlib.Path(sys.argv[1]).read_text()
popup = pathlib.Path(sys.argv[2]).read_text()
tray = pathlib.Path(sys.argv[3]).read_text()
layout = pathlib.Path(sys.argv[4]).read_text()
for role_file in ('TopPanel', 'BottomPanel'):
    if role_file not in main:
        raise SystemExit(f'main.qml must expose {role_file}')
if 'location: root.panelLocation' not in popup:
    raise SystemExit('NothingPopupWindow must follow the owning panel edge')
if 'type: PlasmaCore.Dialog.PopupMenu' not in popup:
    raise SystemExit('NothingPopupWindow must use PopupMenu role')
if 'hideOnWindowDeactivate: true' not in popup:
    raise SystemExit('NothingPopupWindow must close on focus/window deactivation')
if 'appletInterface:' in popup:
    raise SystemExit('NothingPopupWindow must never use appletInterface or popup-size persistence')
if 'engine: "powermanagement"' not in tray:
    raise SystemExit('Island battery must use KDE power management')
for role in ('top', 'bottom'):
    if f'"{role}"' not in layout:
        raise SystemExit(f'layout preset must create/configure {role} panel role')
if layout.count('new Panel("com.nothingplasma.panel")') != 2:
    raise SystemExit('preset must create exactly two independent Panel instances')
if '"dodgewindows"' not in layout:
    raise SystemExit('layout must configure dodge-windows')
if 'RightRail' in main or 'LeftRail' in main or 'rightRail' in layout or 'leftRail' in layout:
    raise SystemExit('retired side panels must not return')
PY2

python3 - <<'PY3' "$ROOT/plasmoids/com.nothingplasma.panel/contents/ui/BottomPanel.qml" "$ROOT/plasmoids/com.nothingplasma.panel/contents/ui/components/TaskStrip.qml" "$ROOT/plasmoids/com.nothingplasma.panel/contents/island/ui/ExpandedPanel.qml" "$ROOT/plasmoids/com.nothingplasma.panel/contents/ui/TopPanel.qml" "$ROOT/plasmoids/com.nothingplasma.panel/contents/ui/components/NothingPopupWindow.qml" "$ROOT/plasma/look-and-feel/com.nothingplasma.dark/contents/layouts/org.kde.plasma.desktop-layout.js" "$ROOT/plasma/look-and-feel/com.nothingplasma.light/contents/layouts/org.kde.plasma.desktop-layout.js"
import pathlib, sys
bottom = pathlib.Path(sys.argv[1]).read_text()
tasks = pathlib.Path(sys.argv[2]).read_text()
top_control = pathlib.Path(sys.argv[3]).read_text()
top = pathlib.Path(sys.argv[4]).read_text()
popup = pathlib.Path(sys.argv[5]).read_text()
dark_layout = pathlib.Path(sys.argv[6]).read_text()
light_layout = pathlib.Path(sys.argv[7]).read_text()
if 'groupMode: TaskManager.TasksModel.GroupApplications' not in bottom or 'groupInline: false' not in bottom:
    raise SystemExit('bottom task model must group same-application windows as a tree')
if 'separateLaunchers: true' not in bottom or 'launchInPlace: true' not in bottom:
    raise SystemExit('bottom task model must keep running pinned apps in their launcher slot')
if 'TaskPreviewContent' not in tasks or 'TaskManager.AbstractTasksModel.WinIdList' not in (pathlib.Path(sys.argv[2]).parent / 'TaskPreviewContent.qml').read_text():
    raise SystemExit('grouped tasks must expose hover window previews')
if 'CLOSE ALL WINDOWS' not in tasks or 'PIN DOCK' not in tasks:
    raise SystemExit('task context menu must expose pinning and close-all actions')
if 'StatusPills {' not in top_control or 'MediaCard {' not in top_control:
    raise SystemExit('top extension must retain the island controls and media card')
if 'required property int popupWidth' not in popup or 'required property int popupHeight' not in popup:
    raise SystemExit('NothingPopupWindow geometry must be explicitly supplied; fixed fallback popup pixels are forbidden')
if 'root.availableWidth - 24' not in top:
    raise SystemExit('top panel width must fit the available screen')
if 'Math.min(island.implicitHeight' not in top:
    raise SystemExit('top popup geometry must be content-driven')
for key in ('launcherWidthPercent', 'launcherHeightPercent', 'taskAreaMaxPercent', 'taskPreviewWidthPercent', 'taskPreviewHeightPercent'):
    if key not in bottom:
        raise SystemExit(f'bottom panel geometry must be driven by {key}')
for lf in (dark_layout, light_layout):
    if lf.count('new Panel("com.nothingplasma.panel")') != 2 or 'rightRail' in lf or 'leftRail' in lf:
        raise SystemExit('Look-and-Feel must create only the island and dock')
PY3

for required in   "$ROOT/runtime/nothing-control.sh"   "$ROOT/wallpapers/dark/wallpaper.jpeg"   "$ROOT/wallpapers/light/wallpaper.jpeg"   "$ROOT/plasma/desktoptheme/NothingPlasmaDark/dialogs/background.svg"   "$ROOT/plasma/desktoptheme/NothingPlasmaLight/dialogs/background.svg"; do
  [[ -f "$required" ]] || { printf 'Required runtime/theme asset missing: %s
' "$required" >&2; exit 1; }
done


# RC11 glowbar guardrails: keep edge reveal accent-aware and visually glow-like,
# not a solid coloured frame. Validate every shipped Plasma Style variant.
python3 - <<'PY_GLOW' "$ROOT"
import pathlib, sys, xml.etree.ElementTree as ET
root = pathlib.Path(sys.argv[1])
for theme in ('NothingPlasmaDark', 'NothingPlasmaLight'):
    for variant in ('', 'solid', 'translucent', 'opaque'):
        base = root / 'plasma/desktoptheme' / theme
        path = base / variant / 'widgets/glowbar.svg' if variant else base / 'widgets/glowbar.svg'
        if not path.is_file():
            raise SystemExit(f'missing glowbar asset: {path}')
        tree = ET.parse(path)
        svg = tree.getroot()
        ids = {e.attrib.get('id'): e for e in svg.iter() if e.attrib.get('id')}
        for required in ('top','bottom','left','right','topleft','topright','bottomleft','bottomright','center'):
            if required not in ids:
                raise SystemExit(f'{path}: missing glowbar element {required}')
        text = path.read_text()
        if 'ColorScheme-Highlight' not in text or 'currentColor' not in text:
            raise SystemExit(f'{path}: glowbar must follow KDE highlight/accent color')
        center = ids['center']
        try:
            alpha = float(center.attrib.get('fill-opacity', '1'))
        except ValueError:
            alpha = 1.0
        if alpha > 0.05:
            raise SystemExit(f'{path}: glowbar center is too opaque ({alpha}); this renders as a bar rather than a glow')
PY_GLOW

# RC10 regression guardrails: preserve the RC4 light/dark path, use KDE's live
# highlight as the one accent source, and keep personalization/shortcuts reachable
# from the actual popup UI rather than hidden in a configuration dialog.
python3 - <<'PY4' \
  "$ROOT/plasmoids/com.nothingplasma.panel/contents/ui/components/NothingPalette.qml" \
  "$ROOT/plasmoids/com.nothingplasma.panel/contents/island/ui/Clock.qml" \
  "$ROOT/plasmoids/com.nothingplasma.panel/contents/island/ui/Battery.qml" \
  "$ROOT/plasmoids/com.nothingplasma.panel/contents/ui/TopPanel.qml" \
  "$ROOT/plasmoids/com.nothingplasma.panel/contents/ui/BottomPanel.qml" \
  "$ROOT/plasmoids/com.nothingplasma.panel/contents/ui/components/SystemControls.qml" \
  "$ROOT/plasmoids/com.nothingplasma.panel/contents/island/ui/AccentSettings.qml" \
  "$ROOT/plasmoids/com.nothingplasma.panel/contents/ui/components/LauncherSettingsPage.qml" \
  "$ROOT/plasmoids/com.nothingplasma.panel/contents/ui/components/LauncherPage.qml" \
  "$ROOT/runtime/nothing-control.sh" \
  "$ROOT/plasmoids/com.nothingplasma.panel/contents/config/main.xml" \
  "$ROOT/plasmoids/com.nothingplasma.panel/contents/ui/main.qml"
import pathlib, sys
palette, dots, tray, top, bottom, controls, personal, launcher_settings, launcher_page, helper, schema, main = [pathlib.Path(p).read_text() for p in sys.argv[1:]]

if 'Plasmoid.configuration?.appearanceMode' not in palette:
    raise SystemExit('NothingPalette must render from explicit appearanceMode so all panel instances can be synchronized reliably')
if 'Kirigami.Theme.focusColor' not in palette:
    raise SystemExit('NothingPalette must use KDE accent (DecorationFocus) as the single accent source')
if 'Plasmoid.configuration.accentColor' in palette:
    raise SystemExit('NothingPalette must not fall back to per-containment accentColor config')
if 'Plasmoid.configuration.appearanceMode = mode' not in controls:
    raise SystemExit('SystemControls must preserve the proven RC4 local light/dark update before global synchronization')
if 'helperCommand("theme " + mode' not in controls:
    raise SystemExit('SystemControls must still invoke the runtime theme helper')
if 'helperCommand("accent " + hex.slice(1))' not in controls:
    raise SystemExit('SystemControls must route accent changes through the global helper')
for token in ('sync_panel_appearance()', 'sync_panel_accent()', 'apply_accent()', 'plasma-apply-colorscheme --accent-color'):
    if token not in helper:
        raise SystemExit(f'nothing-control.sh is missing global appearance/accent behavior: {token}')
for key in ('appearanceMode', 'accentColor'):
    if f'name="{key}"' not in schema:
        raise SystemExit(f'Internal synchronized config key {key} is missing')

if 'Theme.fontDots' not in dots:
    raise SystemExit('Island clock must retain dot typography')
if 'root.percent + "%"' not in tray:
    raise SystemExit('Island battery must retain its visible percentage')

if 'Plasmoid.onActivated: root.shortcutEpoch += 1' not in main:
    raise SystemExit('Root ContainmentItem must own shortcut activation and advance the typed shortcutEpoch bridge')
if 'roleLoader.item' in main and 'handleGlobalShortcut' in main:
    raise SystemExit('Global shortcut dispatch must never call methods through untyped Loader.item')
for name, text, action in (
    ('TopPanel', top, 'onShortcutEpochChanged:'),
    ('BottomPanel', bottom, 'onShortcutEpochChanged:'),
):
    if 'required property int shortcutEpoch' not in text or action not in text:
        raise SystemExit(f'{name} must consume the typed shortcutEpoch bridge')

if 'Island.ExpandedPanel' not in top or 'Island.CompactPill' not in top:
    raise SystemExit('Top panel must host the imported island views')
if 'accentColorPicker' not in personal or 'controls.applyAccent(value)' not in personal:
    raise SystemExit('Island settings must expose custom accent selection through the KDE backend')
if 'Components.LauncherSettingsPage' not in bottom or 'onSettingsRequested' not in bottom:
    raise SystemExit('Launcher must expose its visible settings page')
if 'KQuickControls.KeySequenceItem' not in launcher_settings or 'shortcutController' not in launcher_settings or 'setGlobalShortcut' not in launcher_settings:
    raise SystemExit('Launcher settings must route shortcut edits through the root containment controller')

if 'property var searchModel' in launcher_page or 'searchResultsModel' in bottom:
    raise SystemExit('Launcher search must not cache a stale RunnerModel submodel')
if 'root.runnerModel.modelForRow(0)' not in launcher_page:
    raise SystemExit('Launcher search must bind directly to the active Kicker RunnerModel result model')
if 'runners: ["krunner_services"' not in bottom or 'krunner_webshortcuts' in bottom or 'browsertabs' in bottom:
    raise SystemExit('Launcher search must name its runners explicitly, starting with applications, without web or browser runners')

for token in (
    'Math.min(Island.Theme.expandedWidth, root.availableWidth - 24)',
    'Math.min(island.implicitHeight, root.availableHeight - root.height - 24)',
    'visualParent: anchor',
    'hideOnWindowDeactivate: true',
    'Keys.onEscapePressed:',
):
    if token not in top:
        raise SystemExit('Every top popup must use content-driven sizing with a screen safety clamp')
if 'popupHeightFor(' in top:
    raise SystemExit('Legacy percentage/min-max popup sizing path remains in TopPanel')
if 'Plasmoid.configuration.audioHeightPercent' in top:
    raise SystemExit('Top audio popup must not derive its runtime height from a screen percentage')
PY4

# Plasma 6 KQuickControls.KeySequenceItem exposes keySequence. The old
# currentKeySequence property does not exist and is a blocking qmllint error.
if grep -RInE '\bcurrentKeySequence\b' \
  "$ROOT/plasmoids/com.nothingplasma.panel/contents"; then
  printf '\nInvalid KeySequenceItem.currentKeySequence access found. Use keySequence. Validation failed.\n' >&2
  exit 1
fi

# Hard-coded red is only allowed as one user-selectable preset/default display;
# runtime component styling must consume the synchronized accent property.
if grep -RInE '#[dD]71920' "$ROOT/plasmoids/com.nothingplasma.panel/contents/ui" \
  --exclude='ConfigGeneral.qml' --exclude='PersonalizationPage.qml'; then
  printf '\nHard-coded Nothing red found in runtime panel styling. Use the synchronized accent. Validation failed.\n' >&2
  exit 1
fi

# RC8: Plasma Style must inherit KDE's live color scheme. Shipping a private
# colors file would freeze screen-edge hover/focus roles to the package default.
for forbidden in \
  "$ROOT/plasma/desktoptheme/NothingPlasmaDark/colors" \
  "$ROOT/plasma/desktoptheme/NothingPlasmaLight/colors"; do
  if [[ -e "$forbidden" ]]; then
    printf '\nDesktop-theme colors override found: %s. Let Plasma inherit KDE system colors. Validation failed.\n' "$forbidden" >&2
    exit 1
  fi
done

# RC10: the Plasma autohide/dodge edge hint is widgets/glowbar.svg.
# Both Nothing styles must own an accent-aware copy instead of inheriting a
# fallback theme asset with a stale/fixed color.
for glow in \
  "$ROOT/plasma/desktoptheme/NothingPlasmaDark/widgets/glowbar.svg" \
  "$ROOT/plasma/desktoptheme/NothingPlasmaLight/widgets/glowbar.svg"; do
  [[ -f "$glow" ]] || { printf 'Accent-aware glowbar missing: %s\n' "$glow" >&2; exit 1; }
  grep -q 'ColorScheme-Highlight' "$glow" || { printf 'glowbar does not use ColorScheme-Highlight: %s\n' "$glow" >&2; exit 1; }
  grep -q 'fill="currentColor"' "$glow" || { printf 'glowbar does not bind fill to currentColor: %s\n' "$glow" >&2; exit 1; }
done

for theme in NothingPlasmaDark NothingPlasmaLight; do
  for variant in solid translucent opaque; do
    [[ -f "$ROOT/plasma/desktoptheme/$theme/$variant/widgets/glowbar.svg" ]] || {
      printf 'Variant glowbar missing: %s/%s\n' "$theme" "$variant" >&2; exit 1;
    }
  done
done
python3 - <<'PYGLOW' \
  "$ROOT/plasma/desktoptheme/NothingPlasmaDark/widgets/glowbar.svg" \
  "$ROOT/plasma/desktoptheme/NothingPlasmaLight/widgets/glowbar.svg"
import sys, xml.etree.ElementTree as ET
for path in sys.argv[1:]:
    ET.parse(path)
PYGLOW

python3 - <<'PY8' \
  "$ROOT/plasmoids/com.nothingplasma.panel/contents/ui/components/PopupShell.qml" \
  "$ROOT/plasmoids/com.nothingplasma.panel/contents/ui/components/TaskStrip.qml" \
  "$ROOT/plasmoids/com.nothingplasma.panel/contents/ui/components/TaskPreviewContent.qml" \
  "$ROOT/plasmoids/com.nothingplasma.panel/contents/island/ui/QuickActions.qml" \
  "$ROOT/plasmoids/com.nothingplasma.panel/contents/ui/components/LauncherPage.qml"
import pathlib, sys
popup, tasks, previews, top_control, launcher = [pathlib.Path(p).read_text() for p in sys.argv[1:]]
if 'onAccentColorChanged: accentEdge.requestPaint()' not in popup:
    raise SystemExit('PopupShell Canvas accent edge must repaint when accentColor changes')
for token in ('mainItem: TaskPreviewContent {', 'timeout: -1', 'chooseWindows', 'requestToggleMinimized', 'tasksModel.move', 'syncLaunchers'):
    if token not in tasks:
        raise SystemExit(f'Grouped task hover-preview / click-toggle behavior is missing: {token}')
if 'groupPreviewTip.showToolTip()' in tasks:
    raise SystemExit('Grouped task preview must be hover-only; left click must never open it')
if 'signal windowActivated()' not in previews:
    raise SystemExit('TaskPreviewContent must notify TaskStrip after activating a child window')
if 'visibleCardCount: Math.min(3, root.safeCount)' not in previews:
    raise SystemExit('Grouped previews must keep useful thumbnail widths and scroll extra windows')
if 'text: "SETTINGS"' in top_control or 'text: "SETTINGS"' in launcher:
    raise SystemExit('Header settings access must use compact dotted gear buttons, not text chips')
if 'icon: "settings"' not in top_control or 'text: "settings"' not in launcher:
    raise SystemExit('Top and launcher headers must expose frameless dotted settings gear controls')
PY8

# RC15: modifier-only Meta/Start uses PlasmaShell's native launcher-provider
# path, not a normal plasmoid global shortcut. Exactly one hidden provider is
# installed into the bottom panel; its containment listens to its activation.
python3 - <<'PY14' \
  "$ROOT/plasmoids/com.nothingplasma.launcherbridge/metadata.json" \
  "$ROOT/plasmoids/com.nothingplasma.launcherbridge/contents/ui/main.qml" \
  "$ROOT/plasmoids/com.nothingplasma.panel/contents/ui/main.qml" \
  "$ROOT/plasmoids/com.nothingplasma.panel/contents/ui/BottomPanel.qml" \
  "$ROOT/plasmoids/com.nothingplasma.panel/contents/ui/components/LauncherSettingsPage.qml" \
  "$ROOT/plasma/layout-templates/com.nothingplasma.island.panel/contents/layout.js" \
  "$ROOT/plasma/look-and-feel/com.nothingplasma.dark/contents/layouts/org.kde.plasma.desktop-layout.js" \
  "$ROOT/plasma/look-and-feel/com.nothingplasma.light/contents/layouts/org.kde.plasma.desktop-layout.js" \
  "$ROOT/install.sh" "$ROOT/package.sh"
import json, pathlib, sys
meta_path, bridge_qml_path, main_path, bottom_path, settings_path, *rest = map(pathlib.Path, sys.argv[1:])
layout_paths = rest[:3]
install_path, package_path = rest[3:]
meta = json.loads(meta_path.read_text())
bridge = bridge_qml_path.read_text()
main = main_path.read_text()
bottom = bottom_path.read_text()
settings = settings_path.read_text()
install = install_path.read_text()
package = package_path.read_text()
if meta.get('KPlugin', {}).get('Id') != 'com.nothingplasma.launcherbridge':
    raise SystemExit('Native Meta launcher bridge has the wrong plugin id')
if meta.get('KPackageStructure') != 'Plasma/Applet':
    raise SystemExit('Native Meta launcher bridge must be a Plasma/Applet')
if 'org.kde.plasma.launchermenu' not in meta.get('X-Plasma-Provides', []):
    raise SystemExit('Native Meta launcher bridge must advertise org.kde.plasma.launchermenu')
if meta.get('NoDisplay') is not True:
    raise SystemExit('Native Meta launcher bridge must stay hidden from Add Widgets')
if 'Plasmoid.containment.activated()' in bridge or 'preferredRepresentation: fullRepresentation' not in bridge:
    raise SystemExit('Native Meta launcher bridge must stay inert; re-activating the containment activates the panel window')
if 'applet.pluginName === "com.nothingplasma.launcherbridge"' not in main or 'target: root.launcherBridge' not in main:
    raise SystemExit('Panel root must listen to the Meta launcher bridge activation')
if 'Plasmoid.onActivated: root.shortcutEpoch += 1' not in main:
    raise SystemExit('Panel root must consume activation on the real containment')
if 'onShortcutEpochChanged:' not in bottom or 'root.toggleLauncher()' not in bottom:
    raise SystemExit('Bottom panel must turn root containment activation into launcher toggle')
for token in ('META / START KEY', 'CAN BE ENABLED OR REMOVED', 'OPTIONAL ALTERNATE SHORTCUT', 'CLEAR REMOVES THE ALTERNATE COMBINATION'):
    if token not in settings:
        raise SystemExit(f'Launcher settings must expose removable Meta and alternate shortcut controls: missing {token}')
if 'START / WINDOWS KEY — DEFAULT' in settings or 'META IS NATIVE' in settings:
    raise SystemExit('Launcher settings must not force Meta as an immutable default')
helper_text = (install_path.parent / 'runtime/nothing-control.sh').read_text()
for token in ('launcher-meta)', 'setForeignShortcut', 'META_KEY=16777250', 'meta-launcher-pref', 'patch_nothing_color_schemes()', 'current_accent_hex()', 'sync_accent_from_kde()'):
    if token not in helper_text:
        raise SystemExit(f'Runtime helper is missing Meta/accent synchronization behavior: {token}')
if 'launcher-meta init' not in install or 'accent init' not in install:
    raise SystemExit('Installer must initialize the removable Meta preference and synchronize paired Nothing color schemes')
for lp in layout_paths:
    text = lp.read_text()
    if text.count('bottomPanel.addWidget("com.nothingplasma.launcherbridge")') != 1:
        raise SystemExit(f'{lp} must attach exactly one native Meta bridge to the bottom panel')
if 'install_launcher_bridge' not in install or 'com.nothingplasma.launcherbridge' not in install:
    raise SystemExit('Installer must install/verify the native Meta bridge')
if 'runtime/ensure-panels.js' not in install or 'Pre-migration backup' not in install:
    raise SystemExit('Layout installation must use idempotent repair and preserve a backup')
if 'packaging/prepare-store.py' not in package or 'Nothing-KDE-Launcher-Bridge-{VERSION}.plasmoid' not in (package_path.parent/'packaging/prepare-store.py').read_text():
    raise SystemExit('package.sh must emit a standalone native Meta bridge plasmoid')
PY14

# RC18: the native notification service and compiled applet are never replaced.
# The adapter is API-checked, separate, and reversible; build inputs stay pinned.
python3 - <<'PY18' "$ROOT"
import pathlib, json, sys
r=pathlib.Path(sys.argv[1]); n=r/'notification-skin'
for name in ('prepare-native.py','native-controller.qml.in','install-native.sh','rollback-native.sh','test-native-generator.py'):
    assert (n/name).is_file(), name
c=(n/'native-controller.qml.in').read_text()
for token in ('Binding.RestoreBinding','SortByDate','Qt.DescendingOrder','Qt.AlignTop | Qt.AlignRight','NothingPlasmaDark','NothingPlasmaLight','NotificationManager.Server.valid'):
    assert token in c, token
assert '@@NATIVE_DELEGATE@@' in c
for name in ('install-native.sh','rollback-native.sh'):
    text=(n/name).read_text()
    assert 'com.nothingplasma.notificationbridge' in text
    assert 'p.remove()' not in text
assert 'install_notification_skin()' in (r/'install.sh').read_text()
assert not (n/'apply.py').exists()
print('Isolated native notification adapter checks: OK')
PY18
python3 "$ROOT/notification-skin/test-native-generator.py"
python3 - <<'PY' "$ROOT"
from pathlib import Path
import sys
for path in Path(sys.argv[1]).rglob('*.py'):
    if not any(part in ('dist', 'build', '__pycache__') for part in path.parts):
        compile(path.read_bytes(), str(path), 'exec')
PY
bash -n "$ROOT/notification-skin/install-native.sh" "$ROOT/notification-skin/rollback-native.sh"
bash -n "$ROOT/install.sh" "$ROOT/uninstall.sh" "$ROOT/package.sh" "$ROOT/validate.sh" "$ROOT/runtime/nothing-control.sh"

# Qt 6's tools first: a Qt 5 qmllint or qmltestrunner may come earlier on PATH.
QMLLINT=""
if command -v qmllint6 >/dev/null 2>&1; then
  QMLLINT="$(command -v qmllint6)"
elif [[ -x /usr/lib/qt6/bin/qmllint ]]; then
  QMLLINT="/usr/lib/qt6/bin/qmllint"
elif command -v qmllint >/dev/null 2>&1; then
  QMLLINT="$(command -v qmllint)"
fi

if [[ -n "$QMLLINT" ]]; then
  tmp="$(mktemp)"
  cleanup_validate_tmp() {
    rm -f "$tmp"
  }
  trap cleanup_validate_tmp EXIT
  blocking=0

  while IFS= read -r -d '' file; do
    out="$($QMLLINT "$file" 2>&1 || true)"
    if [[ -n "$out" ]]; then
      printf '%s\n' "$out" >> "$tmp"
    fi
  done < <(find "$ROOT/plasmoids" -path '*/contents/*' -name '*.qml' -print0)

  # qmllint cannot see two things this project verifies itself instead:
  # Plasmoid.configuration members (checked against the package's main.xml, so a
  # misspelled key still fails) and singletons linted on their own (checked
  # against the directory's qmldir).
  python3 - "$tmp" <<'PYLINT'
import pathlib, re, sys
log = pathlib.Path(sys.argv[1])
kept = []
for line in log.read_text().splitlines():
    config = re.match(r'Warning: (.+?/contents/).*Member "(\w+)" not found on type "KConfigPropertyMap" \[missing-property\]', line)
    if config:
        schema = pathlib.Path(config.group(1), 'config/main.xml')
        if schema.is_file() and f'name="{config.group(2)}"' in schema.read_text():
            continue
    single = re.match(r'Warning: (.+)/(\w+)\.qml:: Type (\w+) not declared as singleton in qmldir but using pragma Singleton \[import\]', line)
    if single:
        qmldir = pathlib.Path(single.group(1), 'qmldir')
        if qmldir.is_file() and re.search(rf'^singleton {single.group(3)} (\S+ )?{single.group(2)}\.qml$', qmldir.read_text(), re.M):
            continue
    kept.append(line)
log.write_text('\n'.join(kept) + ('\n' if kept else ''))
PYLINT

  # These diagnostics indicate code that is likely to fail at load/runtime.
  if grep -Eq '(^Error:|\[(syntax|import|missing-property|unresolved-type|unresolved-alias|required-property|uncreatable-type)\])' "$tmp"; then
    blocking=1
  fi

  if (( blocking )); then
    cat "$tmp" >&2
    printf '\nBlocking QML diagnostics found. Validation failed.\n' >&2
    exit 1
  fi

  warning_count="$(grep -c '^Warning:' "$tmp" || true)"
  info_count="$(grep -c '^Info:' "$tmp" || true)"
  if [[ "${NOTHING_QMLLINT_VERBOSE:-0}" == "1" && -s "$tmp" ]]; then
    cat "$tmp"
  fi
  printf 'QML lint complete: no blocking diagnostics (%s warnings, %s info).\n' "$warning_count" "$info_count"
  if (( warning_count > 0 )); then
    printf 'Set NOTHING_QMLLINT_VERBOSE=1 to print non-blocking qmllint diagnostics.\n'
  fi
else
  printf 'qmllint not installed; skipped QML import/type validation.\n'
fi

python3 -m unittest discover -s "$ROOT/tests" -p 'test_*.py'
qml_test_runner="$(command -v qmltestrunner6 || true)"
if [[ -z "$qml_test_runner" && -x /usr/lib/qt6/bin/qmltestrunner ]]; then
  qml_test_runner=/usr/lib/qt6/bin/qmltestrunner
fi
[[ -n "$qml_test_runner" ]] || qml_test_runner="$(command -v qmltestrunner || true)"
if [[ -n "$qml_test_runner" ]]; then
  QT_FORCE_STDERR_LOGGING=1 QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software "$qml_test_runner" -input "$ROOT/tests/qml" -o -,txt
else
  printf 'Qt Quick Test runner unavailable; skipped mock keyboard interaction tests.\n'
fi
if [[ -n "${NOTHING_NATIVE_QML_RUNNER:-}" ]]; then
  QT_FORCE_STDERR_LOGGING=1 QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software "$NOTHING_NATIVE_QML_RUNNER" -input "$ROOT/tests/qml-native" -o -,txt
fi
printf 'Static package validation complete.\n'
