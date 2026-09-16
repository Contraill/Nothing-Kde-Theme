#!/usr/bin/env bash
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

# Restore external appearance overlays before removing the theme helpers.
python3 "$ROOT/runtime/appearance.py" uninstall
python3 "$ROOT/runtime/kitty-theme.py" disable
python3 "$ROOT/runtime/accent-links.py" disable all
python3 "$ROOT/dolphin/manage.py" restore

# Keep the recovery helper available while the persistent microphone gate is on.
if [[ -e /etc/udev/rules.d/71-nothing-plasma-microphone.rules ]]; then
  printf 'Mikrofon erişimini önce açın / Unblock the microphone before uninstalling.\n' >&2
  printf 'Recovery: pkexec /usr/bin/python3 -I "%s/runtime/privacy.py" microphone on\n' "$ROOT" >&2
  exit 1
fi

plasma_eval() {
  local script="$1"
  if command -v qdbus6 >/dev/null 2>&1; then
    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$script" >/dev/null 2>&1 || return 1
  elif command -v qdbus >/dev/null 2>&1; then
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$script" >/dev/null 2>&1 || return 1
  else
    return 1
  fi
}


# Release any transient sleep/idle inhibitors created by the quick controls.
systemctl --user stop nothing-plasma-prevent-sleep.service >/dev/null 2>&1 || true
systemctl --user stop nothing-plasma-prevent-lock.service >/dev/null 2>&1 || true
systemctl --user stop nothing-plasma-stay-awake.service >/dev/null 2>&1 || true

restore_notification_skin() {
  if command -v qdbus6 >/dev/null 2>&1; then
    "$ROOT/notification-skin/rollback-native.sh" || true
  fi
  python3 "$ROOT/notification-skin/restore-legacy.py"
}

# Remove live Nothing panel and legacy widget instances, but do not touch unrelated panels.
plasma_eval 'for (const pid of panelIds) { const p=panelById(pid); if (!p) continue; if (p.type === "com.nothingplasma.panel") { p.remove(); continue; } const ws=p.widgets("com.nothingplasma.island"); for (const w of ws) w.remove(); }' || true

if command -v kpackagetool6 >/dev/null 2>&1; then
  for id in com.nothingplasma.panel com.nothingplasma.launcherbridge com.nothingplasma.notificationbridge com.nothingplasma.island org.nothingkde.widget.battery org.nothingkde.widget.clock-analog org.nothingkde.widget.clock-digital org.nothingkde.widget.clock-digital-large org.nothingkde.widget.date org.nothingkde.widget.media org.nothingkde.widget.photo org.nothingkde.widget.weather; do
    if kpackagetool6 --type Plasma/Applet --list 2>/dev/null | grep -Fq "$id"; then
      kpackagetool6 --type Plasma/Applet --remove "$id" >/dev/null 2>&1 || true
    fi
  done
  if kpackagetool6 --type Plasma/LayoutTemplate --list 2>/dev/null | grep -Fq 'com.nothingplasma.island.panel'; then
    kpackagetool6 --type Plasma/LayoutTemplate --remove com.nothingplasma.island.panel >/dev/null 2>&1 || true
  fi
fi

restore_notification_skin

rm -rf \
  "$DATA_HOME/plasma/plasmoids/com.nothingplasma.panel" \
  "$DATA_HOME/plasma/plasmoids/com.nothingplasma.launcherbridge" \
  "$DATA_HOME/plasma/plasmoids/com.nothingplasma.notificationbridge" \
  "$DATA_HOME/plasma/plasmoids/com.nothingplasma.island" \
  "$DATA_HOME/plasma/desktoptheme/NothingPlasmaDark" \
  "$DATA_HOME/plasma/desktoptheme/NothingPlasmaLight" \
  "$DATA_HOME/plasma/look-and-feel/com.nothingplasma.dark" \
  "$DATA_HOME/plasma/look-and-feel/com.nothingplasma.light" \
  "$DATA_HOME/plasma/layout-templates/com.nothingplasma.island.panel" \
  "$DATA_HOME/nothing-plasma"
rm -f \
  "$DATA_HOME/color-schemes/NothingPlasmaDark.colors" \
  "$DATA_HOME/color-schemes/NothingPlasmaLight.colors"

command -v kbuildsycoca6 >/dev/null 2>&1 && kbuildsycoca6 >/dev/null 2>&1 || true
printf 'Nothing KDE panel, native Meta bridge, notification skin, legacy widget, preset, and theme files removed.\n'
