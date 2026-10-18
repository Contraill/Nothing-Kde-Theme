#!/usr/bin/env bash
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
PANEL_ONLY=0
APPLY_LAYOUT=0
NOTIFICATION_ARGS=()
INSTALL_ARGS=()
for arg in "$@"; do
  case "$arg" in
    --force-notifications|--restart-plasma) NOTIFICATION_ARGS+=("$arg") ;;
    *) INSTALL_ARGS+=("$arg") ;;
  esac
done
set -- "${INSTALL_ARGS[@]}"

case "${1:-}" in
  "") ;;
  --panel-only) PANEL_ONLY=1 ;;
  --apply-layout) APPLY_LAYOUT=1 ;;
  --widgets-only) exec bash "$ROOT/widgets/install.sh" ;;
  --accent-links) shift; exec python3 "$ROOT/runtime/accent-links.py" "$@" ;;
  --dolphin) shift; exec python3 "$ROOT/dolphin/manage.py" "$@" ;;
  --appearance) shift; exec python3 "$ROOT/runtime/appearance.py" "$@" ;;
  --kitty-theme) shift; exec python3 "$ROOT/runtime/kitty-theme.py" "$@" ;;
  --login-wallpaper) shift; exec pkexec /usr/bin/python3 -I "$ROOT/runtime/login-wallpaper.py" "$@" ;;
  --notifications-only) shift; exec "$ROOT/notification-skin/install-native.sh" "${NOTIFICATION_ARGS[@]}" "$@" ;;
  --help|-h) printf 'Usage: %s [--apply-layout | --panel-only | --widgets-only | --accent-links ACTION | --kitty-theme ACTION | --login-wallpaper dark|light|remove | --dolphin ACTION | --appearance ACTION [--qt5] | --notifications-only] [--restart-plasma] [--force-notifications]\n--force-notifications bypasses only the notification compatibility check, not validation or rollback.\n' "$0"; exit 0 ;;
  *) printf 'Unknown option: %s. Use --help.\n' "$1" >&2; exit 2 ;;
esac

if (( APPLY_LAYOUT )); then
  mkdir -p "$DATA_HOME/nothing-plasma/backups"
  migration_backup="$(mktemp -d "$DATA_HOME/nothing-plasma/backups/island-migration-$(date +%Y%m%d-%H%M%S)-XXXXXX")"
  for name in plasma-org.kde.plasma.desktop-appletsrc plasmashellrc; do
    config_file="${XDG_CONFIG_HOME:-$HOME/.config}/$name"
    [[ ! -f "$config_file" ]] || cp -p "$config_file" "$migration_backup/$name"
  done
  [[ ! -d "$DATA_HOME/plasma/plasmoids/com.nothingplasma.panel" ]] || cp -a "$DATA_HOME/plasma/plasmoids/com.nothingplasma.panel" "$migration_backup/"
  printf 'Pre-migration backup: %s\n' "$migration_backup"
fi

if command -v plasmashell >/dev/null 2>&1; then
  version="$(plasmashell --version 2>/dev/null | awk '{print $2}' | head -n1 || true)"
  major="${version%%.*}"
  if [[ -n "$major" && "$major" != "6" ]]; then
    printf 'Nothing KDE requires Plasma 6.x (detected: %s)\n' "$version" >&2
    exit 1
  fi
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

install_applet_package() {
  local id="$1" package="$2"
  if [[ -d "$DATA_HOME/plasma/plasmoids/$id" ]] && diff -qr -- "$package" "$DATA_HOME/plasma/plasmoids/$id" >/dev/null; then
    printf 'Already current: %s\n' "$id"
    return
  fi
  if command -v kpackagetool6 >/dev/null 2>&1; then
    if kpackagetool6 --type Plasma/Applet --list 2>/dev/null | grep -Fq "$id"; then
      kpackagetool6 --type Plasma/Applet --upgrade "$package"
    else
      kpackagetool6 --type Plasma/Applet --install "$package"
    fi
  else
    local dst="$DATA_HOME/plasma/plasmoids/$id"
    mkdir -p "$(dirname "$dst")"
    local stage="${dst}.nothing-stage-$$"
    rm -rf "$stage"
    cp -a "$package" "$stage"
    if [[ -d "$dst" ]]; then mv "$dst" "${dst}.nothing-previous-$$"; fi
    mv "$stage" "$dst"
  fi
}

install_panel_package() {
  printf 'Installing/upgrading Nothing Island + Dock without removing live panels...\n'
  install_applet_package com.nothingplasma.panel "$ROOT/plasmoids/com.nothingplasma.panel"
}

install_launcher_bridge() {
  printf 'Installing/upgrading Nothing launcher bridge...\n'
  install_applet_package com.nothingplasma.launcherbridge "$ROOT/plasmoids/com.nothingplasma.launcherbridge"
}

install_layout_template() {
  local package="$ROOT/plasma/layout-templates/com.nothingplasma.island.panel"
  if [[ -d "$DATA_HOME/plasma/layout-templates/com.nothingplasma.island.panel" ]] && diff -qr -- "$package" "$DATA_HOME/plasma/layout-templates/com.nothingplasma.island.panel" >/dev/null; then
    return
  fi
  if command -v kpackagetool6 >/dev/null 2>&1; then
    if kpackagetool6 --type Plasma/LayoutTemplate --list 2>/dev/null | grep -Fq 'com.nothingplasma.island.panel'; then
      printf 'Upgrading Nothing Island + Dock preset...\n'
      kpackagetool6 --type Plasma/LayoutTemplate --upgrade "$package" >/dev/null
    else
      printf 'Installing Nothing Island + Dock preset...\n'
      kpackagetool6 --type Plasma/LayoutTemplate --install "$package" >/dev/null
    fi
  else
    mkdir -p "$DATA_HOME/plasma/layout-templates"
    rm -rf "$DATA_HOME/plasma/layout-templates/com.nothingplasma.island.panel"
    cp -a "$package" "$DATA_HOME/plasma/layout-templates/com.nothingplasma.island.panel"
  fi
}

install_dir() {
  local src="$1" dst="$2"
  if [[ -d "$dst" ]] && diff -qr -- "$src" "$dst" >/dev/null; then return; fi
  mkdir -p "$(dirname "$dst")"
  rm -rf "$dst"
  cp -a "$src" "$dst"
}

install_notification_skin() {
  local result=0
  local mode=(--package-only)
  for arg in "${NOTIFICATION_ARGS[@]}"; do
    if [[ "$arg" == --restart-plasma ]]; then mode=(); fi
  done
  "$ROOT/notification-skin/install-native.sh" "${mode[@]}" "${NOTIFICATION_ARGS[@]}" || result=$?
  # An unknown private API is an optional-skin skip, not a bundle failure.
  if (( result == 3 )); then
    printf 'KDE native notification appearance retained (compatibility not established).\n'
  elif (( result != 0 )); then
    return "$result"
  fi
}

# The island and dock use Plasma's own QML bindings for these services; a
# missing one leaves its controls empty. Warn instead of failing the install.
check_plasma_modules() {
  local qml missing=() entry
  qml="$(qtpaths6 --query QT_INSTALL_QML 2>/dev/null || true)"
  [[ -n "$qml" && -d "$qml" ]] || qml=/usr/lib/qt6/qml
  for entry in "org/kde/plasma/networkmanagement:plasma-nm" "org/kde/bluezqt:bluez-qt" \
               "org/kde/plasma/private/volume:plasma-pa" "org/kde/plasma/private/brightnesscontrolplugin:powerdevil" \
               "org/kde/ksysguard/sensors:libksysguard" "org/kde/plasma/workspace/dbus:plasma-workspace"; do
    [[ -d "$qml/${entry%%:*}" ]] || missing+=("${entry##*:}")
  done
  if (( ${#missing[@]} )); then
    printf 'Warning: missing Plasma components (install for full island controls): %s\n' "${missing[*]}" >&2
  fi
}
check_plasma_modules

# Capture original appearance before any bundle settings change. Partial panel
# or widget installs do not claim ownership of the application/decorations.
if (( ! PANEL_ONLY )); then python3 "$ROOT/runtime/appearance.py" install; fi

install_panel_package
install_launcher_bridge
install_layout_template

if command -v kbuildsycoca6 >/dev/null 2>&1; then
  kbuildsycoca6 >/dev/null 2>&1 || true
fi

if command -v kpackagetool6 >/dev/null 2>&1; then
  kpackagetool6 --type Plasma/Applet --list 2>/dev/null | grep -Fq 'com.nothingplasma.panel' || {
    printf 'Nothing Island + Dock containment is not discoverable after install.\n' >&2; exit 1; }
  kpackagetool6 --type Plasma/Applet --list 2>/dev/null | grep -Fq 'com.nothingplasma.launcherbridge' || {
    printf 'Nothing native Meta launcher bridge is not discoverable after install.\n' >&2; exit 1; }
  kpackagetool6 --type Plasma/LayoutTemplate --list 2>/dev/null | grep -Fq 'com.nothingplasma.island.panel' || {
    printf 'Nothing Island + Dock preset is not discoverable after install.\n' >&2; exit 1; }
fi

# Runtime helpers and the user-provided paired wallpapers used by the quick
# control light/dark switch.
mkdir -p "$DATA_HOME/nothing-plasma/bin" "$DATA_HOME/nothing-plasma/wallpapers"
install -m 0755 "$ROOT/runtime/nothing-control.sh" "$DATA_HOME/nothing-plasma/bin/nothing-control.sh"
"$DATA_HOME/nothing-plasma/bin/nothing-control.sh" retire-inhibitors
# Wi-Fi now goes through Plasma's NetworkManager bindings; drop the retired helper.
rm -f "$DATA_HOME/nothing-plasma/bin/wifi.py"
install -m 0755 "$ROOT/runtime/privacy.py" "$DATA_HOME/nothing-plasma/bin/privacy.py"
install -m 0755 "$ROOT/runtime/accent-links.py" "$DATA_HOME/nothing-plasma/bin/accent-links.py"
install -m 0755 "$ROOT/runtime/kitty-theme.py" "$DATA_HOME/nothing-plasma/bin/kitty-theme.py"
install -m 0644 "$ROOT/runtime/jsonc_edit.py" "$DATA_HOME/nothing-plasma/bin/jsonc_edit.py"
install -m 0644 "$ROOT/wallpapers/dark/wallpaper.jpeg" "$DATA_HOME/nothing-plasma/wallpapers/dark.jpeg"
install -m 0644 "$ROOT/wallpapers/light/wallpaper.jpeg" "$DATA_HOME/nothing-plasma/wallpapers/light.jpeg"
install_notification_skin

# Meta is a PlasmaShell-owned special shortcut. Initialize it once, but honor
# the persisted user preference on every later install (including OFF).
"$DATA_HOME/nothing-plasma/bin/nothing-control.sh" launcher-meta init >/dev/null 2>&1 || \
  printf 'Warning: could not synchronize the Meta launcher shortcut yet. It can be changed from Launcher Settings.\n' >&2

if (( PANEL_ONLY )); then
  printf '\nInstalled Nothing Island + Dock v0.6.0-rc35, native Meta bridge, and Add Panel preset.\n'
  exit 0
fi

bash "$ROOT/widgets/install.sh"

mkdir -p \
  "$DATA_HOME/plasma/desktoptheme" \
  "$DATA_HOME/plasma/look-and-feel" \
  "$DATA_HOME/color-schemes"

install_dir "$ROOT/plasma/desktoptheme/NothingPlasmaDark" "$DATA_HOME/plasma/desktoptheme/NothingPlasmaDark"
install_dir "$ROOT/plasma/desktoptheme/NothingPlasmaLight" "$DATA_HOME/plasma/desktoptheme/NothingPlasmaLight"
install_dir "$ROOT/plasma/look-and-feel/com.nothingplasma.dark" "$DATA_HOME/plasma/look-and-feel/com.nothingplasma.dark"
install_dir "$ROOT/plasma/look-and-feel/com.nothingplasma.light" "$DATA_HOME/plasma/look-and-feel/com.nothingplasma.light"
[[ -f "$DATA_HOME/color-schemes/NothingPlasmaDark.colors" ]] || cp -a "$ROOT/color-schemes/NothingPlasmaDark.colors" "$DATA_HOME/color-schemes/"
[[ -f "$DATA_HOME/color-schemes/NothingPlasmaLight.colors" ]] || cp -a "$ROOT/color-schemes/NothingPlasmaLight.colors" "$DATA_HOME/color-schemes/"
if command -v kwriteconfig6 >/dev/null; then
  for title in Dark Light; do
    kwriteconfig6 --file "$DATA_HOME/color-schemes/NothingPlasma${title}.colors" --group General --key Name "Nothing KDE $title"
  done
fi

# Make both Nothing scheme files reflect the user's live KDE accent so the
# System Settings preview and the panels use the same color from first install.
"$DATA_HOME/nothing-plasma/bin/nothing-control.sh" accent init >/dev/null 2>&1 || true
"$DATA_HOME/nothing-plasma/bin/nothing-control.sh" cleanup-shortcuts >/dev/null 2>&1 || true
if (( ! PANEL_ONLY )); then python3 "$ROOT/runtime/kitty-theme.py" install; fi

if command -v kbuildsycoca6 >/dev/null 2>&1; then
  kbuildsycoca6 >/dev/null 2>&1 || true
fi

printf '\nInstalled Nothing KDE v0.6.0-rc35.\n'
printf 'Notifications: installed when native QML/API checks pass. On an existing layout run ./install.sh --notifications-only --restart-plasma\n'
printf 'Panel containment: com.nothingplasma.panel\n'
printf 'Meta launcher:     com.nothingplasma.launcherbridge\n'
printf 'Panel preset:      Nothing Island + Dock Layout\n'

if (( APPLY_LAYOUT )); then
  printf 'Applying two-panel layout; only Nothing left/right panels will be removed.\n'
  plasma_eval "$(<"$ROOT/runtime/ensure-panels.js")" || { printf 'Layout migration failed; backup: %s\n' "$migration_backup" >&2; exit 1; }
  systemctl --user restart plasma-plasmashell.service || {
    printf 'Packages installed; please log out/in to load the new QML. Backup: %s\n' "$migration_backup" >&2
    exit 1
  }
  printf 'Island + dock applied. Removed side panels can be restored from: %s\n' "$migration_backup"
fi
