#!/usr/bin/env bash
set -euo pipefail

DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
# Serialize palette writers: a startup sync must never observe the intermediate
# scheme palette and overwrite an explicit user selection during a switch.
if [[ "${1:-}" == theme || "${1:-}" == accent ]]; then
  mkdir -p "$CONFIG_HOME/nothing-kde"
  exec 9>"$CONFIG_HOME/nothing-kde/appearance-switch.lock"
  flock -x 9
fi

plasma_eval() {
  local script="$1"
  if command -v qdbus6 >/dev/null 2>&1; then
    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$script"
  elif command -v qdbus >/dev/null 2>&1; then
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$script"
  else
    return 127
  fi
}

wallpaper_uri() {
  local mode="$1"
  [[ "$mode" == "dark" || "$mode" == "light" ]] || return 2
  local path="$DATA_HOME/nothing-plasma/wallpapers/${mode}.jpeg"
  if [[ ! -f "$path" ]]; then
    path="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../wallpapers" 2>/dev/null && pwd)/${mode}.jpeg"
  fi
  [[ -f "$path" ]] || return 1
  python3 - "$path" <<'PY'
import pathlib, sys
print(pathlib.Path(sys.argv[1]).resolve().as_uri())
PY
}

apply_wallpaper() {
  local mode="$1"
  local uri
  uri="$(wallpaper_uri "$mode")"
  local js dark_uri light_uri
  dark_uri="$(wallpaper_uri dark)" || return $?
  light_uri="$(wallpaper_uri light)" || return $?
  # Stock/new desktops and our own paired images are managed. A custom image,
  # slideshow, live wallpaper, etc. is a user override, even with auto mode on.
  js="for (const d of desktops()) {
    if (d.wallpaperPlugin && d.wallpaperPlugin !== 'org.kde.image') continue;
    d.currentConfigGroup = ['Wallpaper','org.kde.image','General'];
    const current = String(d.readConfig('Image', ''));
    const stock = /^(file:\\/\\/)?\\/usr\\/share\\/wallpapers\\/Next(\\/|$)/.test(current);
    if (current && current !== '${dark_uri}' && current !== '${light_uri}' && !stock) continue;
    if (current !== '${uri}') {
      d.wallpaperPlugin = 'org.kde.image';
      d.writeConfig('Image', '${uri}');
      d.writeConfig('PreviewImage', 'null');
      d.reloadConfig();
    }
  }"
  plasma_eval "$js" >/dev/null
}

apply_lock_wallpaper() {
  local mode="$1" uri config backup current plugin
  uri="$(wallpaper_uri "$mode")" || return $?
  command -v kwriteconfig6 >/dev/null 2>&1 || return 127
  config="${XDG_CONFIG_HOME:-$HOME/.config}/kscreenlockerrc"
  current="$(kreadconfig6 --file "$config" --group Greeter --group Wallpaper --group org.kde.image --group General --key Image 2>/dev/null || true)"
  plugin="$(kreadconfig6 --file "$config" --group Greeter --key WallpaperPlugin 2>/dev/null || true)"
  [[ "$current" != "$uri" || "$plugin" != "org.kde.image" ]] || return 0
  backup="$DATA_HOME/nothing-plasma/backups/lockscreen-before-theme"
  mkdir -p "$backup"
  if [[ ! -e "$backup/kscreenlockerrc" && ! -e "$backup/previously-absent" ]]; then
    if [[ -f "$config" ]]; then cp -p -- "$config" "$backup/kscreenlockerrc";
    else touch "$backup/previously-absent"; fi
  fi
  # Only appearance keys: never change Daemon, password or automatic-lock policy.
  kwriteconfig6 --file "$config" --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "$uri" || return $?
  kwriteconfig6 --file "$config" --group Greeter --group Wallpaper --group org.kde.image --group General --key PreviewImage "$uri" || return $?
  kwriteconfig6 --file "$config" --group Greeter --key WallpaperPlugin org.kde.image || return $?
  if command -v qdbus6 >/dev/null 2>&1; then
    qdbus6 org.kde.screensaver /ScreenSaver org.kde.screensaver.configure >/dev/null 2>&1 || true
  fi
}

sync_panel_appearance() {
  local mode="$1"
  [[ "$mode" == "light" || "$mode" == "dark" ]] || return 2
  local js
  js="for (const pid of panelIds) { const p=panelById(pid); if (!p || p.type !== 'com.nothingplasma.panel') continue; p.currentConfigGroup=['General']; p.writeConfig('appearanceMode','${mode}'); p.reloadConfig(); }"
  plasma_eval "$js" >/dev/null 2>&1 || true
}

sync_panel_accent() {
  local hex="$1"
  [[ "$hex" =~ ^#[0-9A-Fa-f]{6}$ ]] || return 2
  local js
  js="for (const pid of panelIds) { const p=panelById(pid); if (!p || p.type !== 'com.nothingplasma.panel') continue; p.currentConfigGroup=['General']; p.writeConfig('accentColor','${hex}'); p.reloadConfig(); }"
  plasma_eval "$js" >/dev/null 2>&1 || true
}

current_accent_hex() {
  local value raw r g b scheme file

  if command -v kreadconfig6 >/dev/null 2>&1; then
    value="$(kreadconfig6 --file kdeglobals --group General --key AccentColor 2>/dev/null || true)"
    if [[ -z "$value" ]]; then
      value="$(kreadconfig6 --file kdeglobals --group Colors:Selection --key BackgroundNormal 2>/dev/null || true)"
    fi
  else
    value=""
  fi

  if [[ "$value" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
    printf '%s\n' "${value^^}"
    return 0
  fi
  if [[ "$value" =~ ^([0-9]{1,3}),([0-9]{1,3}),([0-9]{1,3})$ ]]; then
    r="${BASH_REMATCH[1]}"; g="${BASH_REMATCH[2]}"; b="${BASH_REMATCH[3]}"
    (( r <= 255 && g <= 255 && b <= 255 )) || return 1
    printf '#%02X%02X%02X\n' "$r" "$g" "$b"
    return 0
  fi

  if command -v kreadconfig6 >/dev/null 2>&1; then
    scheme="$(kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null || true)"
  else
    scheme=""
  fi
  [[ -n "$scheme" ]] || return 1

  for file in "$DATA_HOME/color-schemes/${scheme}.colors" "/usr/share/color-schemes/${scheme}.colors"; do
    [[ -r "$file" ]] || continue
    raw="$(python3 - "$file" <<'PYACC'
import configparser, sys
cp=configparser.RawConfigParser(interpolation=None, strict=False)
cp.optionxform=str
try:
    cp.read(sys.argv[1], encoding='utf-8')
    print(cp.get('Colors:Selection','BackgroundNormal',fallback=''))
except Exception:
    print('')
PYACC
)"
    if [[ "$raw" =~ ^([0-9]{1,3}),([0-9]{1,3}),([0-9]{1,3})$ ]]; then
      r="${BASH_REMATCH[1]}"; g="${BASH_REMATCH[2]}"; b="${BASH_REMATCH[3]}"
      (( r <= 255 && g <= 255 && b <= 255 )) || continue
      printf '#%02X%02X%02X\n' "$r" "$g" "$b"
      return 0
    fi
  done
  return 1
}

patch_nothing_color_schemes() {
  local raw="${1:-}" file
  raw="${raw#\#}"
  [[ "$raw" =~ ^[0-9A-Fa-f]{6}$ ]] || return 2
  raw="${raw^^}"

  for file in "$DATA_HOME/color-schemes/NothingPlasmaDark.colors" "$DATA_HOME/color-schemes/NothingPlasmaLight.colors"; do
    [[ -f "$file" ]] || continue
    python3 - "$file" "$raw" <<'PYSCHEME'
from pathlib import Path
import sys
path=Path(sys.argv[1])
h=sys.argv[2]
rgb=','.join(str(int(h[i:i+2],16)) for i in (0,2,4))
accent_keys={
    'Colors:Window': {'DecorationFocus','DecorationHover','ForegroundActive','ForegroundLink'},
    'Colors:View': {'DecorationFocus','DecorationHover','ForegroundActive','ForegroundLink'},
    'Colors:Button': {'DecorationFocus','DecorationHover','ForegroundActive','ForegroundLink'},
    'Colors:Selection': {'BackgroundNormal','BackgroundAlternate','DecorationFocus','DecorationHover'},
    'Colors:Tooltip': {'DecorationFocus','DecorationHover'},
    'Colors:Complementary': {'DecorationFocus','DecorationHover'},
}
lines=path.read_text(encoding='utf-8').splitlines()
section=''
out=[]
changed=False
for line in lines:
    stripped=line.strip()
    if stripped.startswith('[') and stripped.endswith(']'):
        section=stripped[1:-1]
        out.append(line)
        continue
    if '=' in line and section in accent_keys:
        key=line.split('=',1)[0].strip()
        if key in accent_keys[section]:
            newline=f'{key}={rgb}'
            changed |= newline != line
            out.append(newline)
            continue
    out.append(line)
if changed:
    path.write_text('\n'.join(out)+'\n', encoding='utf-8')
PYSCHEME
  done
}

sync_accent_from_kde() {
  local hex
  hex="$(current_accent_hex)" || return 1
  patch_nothing_color_schemes "$hex"
  mkdir -p "$DATA_HOME/nothing-plasma"
  printf '%s\n' "$hex" > "$DATA_HOME/nothing-plasma/accent"
  sync_panel_accent "$hex"
  sync_accent_links "$hex"
  printf '%s\n' "$hex"
}

sync_accent_links() {
  local helper
  helper="$(dirname -- "${BASH_SOURCE[0]}")/appearance.py"
  if [[ -f "$helper" ]]; then
    python3 "$helper" sync >/dev/null || printf 'Application palette sync failed\n' >&2
  fi
  helper="$(dirname -- "${BASH_SOURCE[0]}")/accent-links.py"
  [[ ! -f "$helper" ]] || python3 "$helper" sync --accent "$1" >/dev/null
}

apply_accent() {
  local raw="${1:-}"
  raw="${raw#\#}"
  [[ "$raw" =~ ^[0-9A-Fa-f]{6}$ ]] || { echo 'accent must be RRGGBB' >&2; return 2; }
  raw="${raw^^}"
  local hex="#${raw}"
  command -v kwriteconfig6 >/dev/null && command -v plasma-apply-colorscheme >/dev/null || {
    echo 'KDE accent backend unavailable' >&2; return 127;
  }
  local key result old_values=()
  local keys=(accentColorFromWallpaper AccentColor LastUsedCustomAccentColor)
  for key in "${keys[@]}"; do
    old_values+=("$(kreadconfig6 --file kdeglobals --group General --key "$key" --default __NOTHING_ABSENT__)")
  done

  # The CLI applies colors but does not save the KCM's AccentColor preference.
  # Persist BEFORE broadcasting a palette change or reloading either panel.
  local rgb="$((16#${raw:0:2})),$((16#${raw:2:2})),$((16#${raw:4:2}))"
  if kwriteconfig6 --file kdeglobals --group General --key accentColorFromWallpaper false &&
     kwriteconfig6 --file kdeglobals --group General --key AccentColor "$rgb" &&
     kwriteconfig6 --file kdeglobals --group General --key LastUsedCustomAccentColor "$rgb" &&
     plasma-apply-colorscheme --accent-color "$hex" >/dev/null; then
    :
  else
    result=$?
    local i
    for i in "${!keys[@]}"; do
      if [[ "${old_values[i]}" == __NOTHING_ABSENT__ ]]; then
        kwriteconfig6 --file kdeglobals --group General --key "${keys[i]}" --delete
      else
        kwriteconfig6 --file kdeglobals --group General --key "${keys[i]}" "${old_values[i]}"
      fi
    done
    return "$result"
  fi

  patch_nothing_color_schemes "$hex"
  mkdir -p "$DATA_HOME/nothing-plasma"
  printf '%s\n' "$hex" > "$DATA_HOME/nothing-plasma/accent"
  sync_panel_accent "$hex"
  sync_accent_links "$hex"
}

init_accent() {
  local saved migrated
  saved="$(kreadconfig6 --file kdeglobals --group General --key AccentColor)"
  # One-time recovery: old panel accentColor was written only by Apply, whereas
  # the old data/accent file was overwritten by startup palette observations.
  if [[ -z "$saved" ]]; then
    migrated="$(python3 - "$CONFIG_HOME/plasma-org.kde.plasma.desktop-appletsrc" <<'PYMIGRATE'
import configparser, pathlib, re, sys
p=pathlib.Path(sys.argv[1]); c=configparser.ConfigParser(interpolation=None, strict=False); c.optionxform=str
c.read(p)
values=set()
for section in c.sections():
    if re.fullmatch(r'Containments\]\[\d+', section) and c.get(section,'plugin',fallback='')=='com.nothingplasma.panel':
        value=c.get(section+'][General','accentColor',fallback='').upper()
        if re.fullmatch(r'#[0-9A-F]{6}',value) and value not in ('#D71920','#D71921'): values.add(value)
if len(values)==1: print(values.pop())
PYMIGRATE
)"
    if [[ "$migrated" =~ ^#[0-9A-Fa-f]{6}$ ]]; then apply_accent "$migrated"; return; fi
  fi
  # Native KDE preferences win; do not create a custom preference from a default.
  sync_accent_from_kde
}

launcher_meta_action=(plasmashell 'activate application launcher' plasmashell 'Activate Application Launcher')
META_KEY=16777250

launcher_meta_keys() {
  command -v busctl >/dev/null 2>&1 || { echo 'busctl unavailable' >&2; return 127; }
  local output count i
  output="$(busctl --user call org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel shortcut \
    as 4 "${launcher_meta_action[@]}" 2>/dev/null)" || return 1
  read -r -a fields <<<"$output"
  [[ "${fields[0]:-}" == "ai" && "${fields[1]:-}" =~ ^[0-9]+$ ]] || return 1
  count="${fields[1]}"
  for ((i=0; i<count; i++)); do
    [[ "${fields[i+2]:-}" =~ ^-?[0-9]+$ ]] && printf '%s\n' "${fields[i+2]}"
  done
}

launcher_meta_write_keys() {
  local -a keys=("$@")
  command -v busctl >/dev/null 2>&1 || { echo 'busctl unavailable' >&2; return 127; }
  busctl --user call org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel setForeignShortcut \
    asai 4 "${launcher_meta_action[@]}" "${#keys[@]}" "${keys[@]}" >/dev/null
}

launcher_meta_status() {
  local key keys_text
  keys_text="$(launcher_meta_keys)" || return 1
  while IFS= read -r key; do
    [[ "$key" == "$META_KEY" ]] && { echo on; return 0; }
  done <<<"$keys_text"
  echo off
}

launcher_meta_set() {
  local enabled="$1" key seen=0 keys_text
  local -a keys=() updated=()
  keys_text="$(launcher_meta_keys)" || { echo 'could not read Plasma launcher shortcuts' >&2; return 1; }
  while IFS= read -r key; do
    [[ -n "$key" ]] && keys+=("$key")
  done <<<"$keys_text"

  if [[ "$enabled" == "on" ]]; then
    for key in "${keys[@]}"; do [[ "$key" == "$META_KEY" ]] && seen=1; done
    updated=("${keys[@]}")
    (( seen )) || updated+=("$META_KEY")
  else
    for key in "${keys[@]}"; do [[ "$key" != "$META_KEY" ]] && updated+=("$key"); done
  fi

  launcher_meta_write_keys "${updated[@]}"
  mkdir -p "$DATA_HOME/nothing-plasma"
  printf '%s\n' "$enabled" > "$DATA_HOME/nothing-plasma/meta-launcher-pref"
}

launcher_meta_init() {
  local pref_file="$DATA_HOME/nothing-plasma/meta-launcher-pref" pref
  if [[ -r "$pref_file" ]]; then
    pref="$(head -n1 "$pref_file" 2>/dev/null || true)"
    [[ "$pref" == "on" || "$pref" == "off" ]] || pref=on
  else
    pref=on
  fi
  launcher_meta_set "$pref"
}

apply_theme() {
  local mode="$1"
  local auto_wallpaper="${2:-1}"
  local scheme
  case "$mode" in
    dark) scheme="NothingPlasmaDark" ;;
    light) scheme="NothingPlasmaLight" ;;
    *)
      printf 'unknown theme mode: %s\n' "$mode" >&2
      exit 2
      ;;
  esac

  # Preserve the live KDE accent (including changes made in System Settings)
  # before applying either paired Nothing color scheme.
  local live_accent
  live_accent="$(current_accent_hex 2>/dev/null || true)"

  # Mirror appearanceMode to the installed Nothing panels before applying
  # the KDE color scheme.
  sync_panel_appearance "$mode"

  local previous_scheme appearance_helper
  previous_scheme="$(kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null || true)"
  appearance_helper="$(dirname -- "${BASH_SOURCE[0]}")/appearance.py"

  if command -v plasma-apply-colorscheme >/dev/null 2>&1; then
    plasma-apply-colorscheme "$scheme" >/dev/null || return $?
  elif command -v kwriteconfig6 >/dev/null 2>&1; then
    kwriteconfig6 --file kdeglobals --group General --key ColorScheme "$scheme"
  fi

  if [[ "$live_accent" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
    apply_accent "$live_accent" || return $?
  else
    sync_accent_from_kde >/dev/null 2>&1 || true
  fi

  if [[ -f "$appearance_helper" && -n "$previous_scheme" ]]; then
    python3 "$appearance_helper" record-scheme --previous-scheme "$previous_scheme" || true
  fi
  local kitty_helper="$(dirname -- "${BASH_SOURCE[0]}")/kitty-theme.py"
  if [[ -f "$kitty_helper" ]]; then python3 "$kitty_helper" sync || true; fi

  if [[ "$auto_wallpaper" == "1" ]]; then
    apply_wallpaper "$mode" || true
    apply_lock_wallpaper "$mode"
  fi
}

retire_legacy_inhibitors() {
  # Migration only: the island now uses KDE InhibitionControl, never a daemon.
  # Exact old Nothing unit names; unrelated applications are not affected.
  local unit
  for unit in nothing-plasma-prevent-sleep.service nothing-plasma-prevent-lock.service nothing-plasma-stay-awake.service; do
    systemctl --user stop "$unit" >/dev/null 2>&1 || true
  done
}

cleanup_widget_shortcuts() {
  # "activate widget N" shortcuts outlive their applets. Dead ones keep holding
  # keys (old Nothing launchers held Alt+F1), so drop entries whose applet or
  # containment id no longer exists. Shortcuts of live widgets are untouched.
  command -v busctl >/dev/null 2>&1 || return 0
  command -v qdbus6 >/dev/null 2>&1 || return 0
  local appletsrc="$CONFIG_HOME/plasma-org.kde.plasma.desktop-appletsrc" names name id
  [[ -f "$appletsrc" ]] || return 0
  names="$(qdbus6 org.kde.kglobalaccel /component/plasmashell org.kde.kglobalaccel.Component.shortcutNames 2>/dev/null)" || return 0
  while IFS= read -r name; do
    [[ "$name" =~ ^activate\ widget\ ([0-9]+)$ ]] || continue
    id="${BASH_REMATCH[1]}"
    grep -qE "^\[Containments\]\[$id\]$|\]\[Applets\]\[$id\]$" "$appletsrc" && continue
    busctl --user call org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel unregister ss plasmashell "$name" >/dev/null 2>&1 || true
  done <<< "$names"
}

audio_osd() {
  # "island": the island shows volume/mute changes, so Plasma's audio OSD is
  # switched off; "plasma": back to Plasma's defaults. plasma-pa watches this
  # file, so --notify applies it without a restart.
  local key
  for key in VolumeOsd MuteOsd MicrophoneSensitivityOsd; do
    if [[ "${1:-}" == island ]]; then
      kwriteconfig6 --file plasmaparc --group General --key "$key" --notify false
    else
      kwriteconfig6 --file plasmaparc --group General --key "$key" --notify --delete
    fi
  done
}

gpu_power() {
  # One line per GPU: PCI vendor, boot_vga (1 = integrated/primary) and runtime
  # PM state. Reading sysfs never wakes a suspended discrete GPU.
  local card vendor boot state
  for card in /sys/class/drm/card*; do
    [[ "${card##*/}" =~ ^card[0-9]+$ && -r "$card/device/vendor" ]] || continue
    vendor="$(<"$card/device/vendor")"
    boot="$(cat "$card/device/boot_vga" 2>/dev/null || echo 0)"
    state="$(cat "$card/device/power/runtime_status" 2>/dev/null || echo unsupported)"
    printf '%s %s %s\n' "$vendor" "$boot" "$state"
  done
}

case "${1:-}" in
  theme)
    apply_theme "${2:-}" "${3:-1}"
    ;;
  accent)
    if [[ "${2:-}" == "sync" ]]; then
      sync_accent_from_kde
    elif [[ "${2:-}" == "init" ]]; then
      init_accent
    elif [[ "${2:-}" == "get" ]]; then
      current_accent_hex
    else
      apply_accent "${2:-}"
    fi
    ;;
  launcher-meta)
    case "${2:-}" in
      on) launcher_meta_set on ;;
      off) launcher_meta_set off ;;
      status) launcher_meta_status ;;
      init) launcher_meta_init ;;
      *) echo 'usage: nothing-control.sh launcher-meta <on|off|status|init>' >&2; exit 2 ;;
    esac
    ;;
  ensure-tray)
    plasma_eval "for (const id of panelIds) {
      const p = panelById(id);
      if (!p || p.type !== 'com.nothingplasma.panel' || p.location !== 'top') continue;
      if (p.widgets('org.kde.plasma.systemtray').length) continue;
      const tray = p.addWidget('org.kde.plasma.systemtray');
      tray.currentConfigGroup = ['General'];
      tray.writeConfig('extraItems', []);
      tray.reloadConfig();
    }" >/dev/null
    ;;
  wallpaper)
    apply_wallpaper "${2:-}"
    ;;
  lockscreen-wallpaper)
    apply_lock_wallpaper "${2:-}"
    ;;
  retire-inhibitors)
    retire_legacy_inhibitors
    ;;
  gpu-power)
    gpu_power
    ;;
  cleanup-shortcuts)
    cleanup_widget_shortcuts
    ;;
  audio-osd)
    [[ "${2:-}" == island || "${2:-}" == plasma ]] || { echo 'usage: audio-osd island|plasma' >&2; exit 2; }
    audio_osd "$2"
    ;;
  *)
    cat >&2 <<'USAGE'
usage:
  nothing-control.sh theme <dark|light> [auto-wallpaper:0|1]
  nothing-control.sh accent <RRGGBB|sync|init|get>
  nothing-control.sh launcher-meta <on|off|status|init>
  nothing-control.sh ensure-tray
  nothing-control.sh wallpaper <dark|light>
  nothing-control.sh lockscreen-wallpaper <dark|light>
  nothing-control.sh retire-inhibitors
  nothing-control.sh gpu-power
  nothing-control.sh cleanup-shortcuts
  nothing-control.sh audio-osd <island|plasma>
USAGE
    exit 2
    ;;
esac
