#!/usr/bin/env bash
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ID=com.nothingplasma.notificationbridge
RESTART_PLASMA=0
PACKAGE_ONLY=0
FORCE_NOTIFICATIONS=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --restart-plasma) RESTART_PLASMA=1; shift ;;
    --package-only) PACKAGE_ONLY=1; shift ;;
    --force-notifications) FORCE_NOTIFICATIONS=1; shift ;;
    --help|-h) printf 'Usage: %s [--restart-plasma] [--package-only] [--force-notifications]\nForce bypasses only compatibility, never parsing, native-service checks or rollback.\n' "$0"; exit 0 ;;
    *) printf 'Unknown option: %s. Use --help.\n' "$1" >&2; exit 2 ;;
  esac
done
BACKUP_BASE="${XDG_DATA_HOME:-$HOME/.local/share}/nothing-plasma/backups"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
INSTALLED="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids/$ID"
if ! command -v plasmashell >/dev/null 2>&1; then
  printf 'Plasma is not installed. Nothing was changed.\n' >&2; exit 1
fi
# diff tells a current package from one to replace; without it every run would reinstall.
for cmd in python3 kpackagetool6 qdbus6 diff qmlformat; do
  if [[ "$cmd" == qmlformat ]]; then
    if ! command -v qmlformat6 >/dev/null 2>&1 && ! command -v qmlformat >/dev/null 2>&1 && [[ ! -x /usr/lib/qt6/bin/qmlformat ]]; then
      printf 'Qt QML tools (qmlformat) are required to validate the adapter. No changes made.\n' >&2; exit 1
    fi
  elif ! command -v "$cmd" >/dev/null 2>&1; then
    printf 'Required command missing: %s. Nothing changed.\n' "$cmd" >&2; exit 1
  fi
done
if (( FORCE_NOTIFICATIONS )); then
  printf 'Warning: bypassing only the notification compatibility guard. Runtime activation must still succeed.\n' >&2
elif ! python3 "$ROOT/compatibility.py"; then
  # Retire only our live adapter if a Plasma upgrade invalidated its private
  # contract. Native applets and service remain in place; no layout is restored.
  "$ROOT/rollback-native.sh"
  # Do not leave a rejected adapter discoverable for a later Add Panel action.
  # Quarantine only our local package; preserve it for explicit rollback.
  if [[ -d "$INSTALLED" && ! -L "$INSTALLED" ]] && python3 -c 'import json,sys; sys.exit(json.load(open(sys.argv[1]))["KPlugin"]["Id"] != "com.nothingplasma.notificationbridge")' "$INSTALLED/metadata.json"; then
    mkdir -p "$BACKUP_BASE"
    rejected="$(mktemp -d "$BACKUP_BASE/native-notifications-incompatible-XXXXXXXX")"
    mv -- "$INSTALLED" "$rejected/$ID"
    printf 'Unverified adapter package preserved at: %s\n' "$rejected"
  fi
  printf 'KDE native appearance retained; use --force-notifications only to explicitly accept an unverified API.\n' >&2
  exit 3
fi
# Require the existing native service. Never install a replacement daemon.
if (( ! PACKAGE_ONLY )) && ! qdbus6 org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.Notifications.GetServerInformation >/dev/null 2>&1; then
  printf 'Native Plasma notifications are not responding. No changes made.\n' >&2; exit 1
fi
build_dir="$(mktemp -d -t nothing-kde-notifications-XXXXXXXX)"
MUTATING=0
COMMITTED=0
restore_package() {
  [[ ! -L "$INSTALLED" ]] || return 1
  if [[ -d "$BACKUP/$ID" ]]; then
    # Do not rely on KPackage after a failed/partial package upgrade.
    cp -a -- "$BACKUP/$ID" "$build_dir/restore" || return 1
    if [[ -e "$INSTALLED" ]]; then
      mv -- "$INSTALLED" "$build_dir/failed-package" || return 1
    fi
    mv -- "$build_dir/restore" "$INSTALLED" || return 1
  elif [[ -d "$INSTALLED" ]]; then
    mv -- "$INSTALLED" "$build_dir/failed-package" || return 1
  fi
}
cleanup() {
  local result=$?
  trap - EXIT
  if (( MUTATING && ! COMMITTED )); then
    "$ROOT/rollback-native.sh" || printf 'Could not detach the adapter; use rollback-native.sh when Plasma responds.\n' >&2
    # Restore only the package we replaced, never the user's layout/config.
    restore_package || printf 'Package restore failed; preserved snapshot: %s\n' "$BACKUP" >&2
    printf 'Notification installation failed; adapter detached and native appearance restored where Plasma responded.\n' >&2
  fi
  rm -rf -- "$build_dir"
  exit "$result"
}
trap cleanup EXIT
PACKAGE="$build_dir/$ID"
python3 "$ROOT/prepare-native.py" --output "$PACKAGE"
# Qt 6's qmlformat first: a Qt 5 one may come earlier on PATH and reject unversioned imports.
LINT="$(command -v qmlformat6 || { [[ -x /usr/lib/qt6/bin/qmlformat ]] && printf /usr/lib/qt6/bin/qmlformat; } || command -v qmlformat)"
# Compiled applet imports exist inside plasmashell, not on qmllint's search
# path. Parse every file here; check actual module loading in the live shell.
for file in "$PACKAGE/contents/ui/main.qml" "$PACKAGE/contents/ui/NothingNotificationPopup.qml" "$PACKAGE/contents/ui/delegates/"*.qml; do
  printf 'Parsing %s\n' "$(basename "$file")"
  "$LINT" "$file" >/dev/null
done
if [[ -L "$INSTALLED" ]]; then
  printf 'Refusing to replace a symlinked notification package. No changes made.\n' >&2
  exit 1
fi
CURRENT=0
if [[ -d "$INSTALLED" ]] && diff -qr -- "$PACKAGE" "$INSTALLED" >/dev/null; then
  CURRENT=1
  if (( PACKAGE_ONLY )); then
    printf 'Notification package already current.\n'
    exit 0
  fi
fi
# Resolve the host before installing anything.
HOST_SCRIPT='var found=false;for(var i=0;i<panelIds.length;i++){var p=panelById(panelIds[i]);if(p&&p.type==="com.nothingplasma.panel"&&p.location==="top"){found=true;print("NOTHING_HOST:"+p.id);break}}if(!found)print("NOTHING_HOST_MISSING")'
if (( ! PACKAGE_ONLY )) && [[ "$(qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$HOST_SCRIPT")" == *NOTHING_HOST_MISSING* ]]; then
  PACKAGE_ONLY=1
  printf 'No Nothing top panel yet; installing the package for the Add Panel layout.\n'
fi
if (( CURRENT && ! RESTART_PLASMA && ! PACKAGE_ONLY )); then
  PRESENT_SCRIPT='var found=false;for(var i=0;i<panelIds.length;i++){var p=panelById(panelIds[i]);if(!p||p.type!=="com.nothingplasma.panel"||p.location!=="top"||!p.widgets("org.kde.plasma.notifications").length)continue;var ws=p.widgets("com.nothingplasma.notificationbridge");for(var j=0;j<ws.length;j++){if(ws[j].readConfig("enabled",true)!==false)found=true}}if(found)print("NOTHING_BRIDGE_PRESENT")'
  if [[ "$(qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$PRESENT_SCRIPT")" == *NOTHING_BRIDGE_PRESENT* ]]; then
    printf 'Compatible notification package already current and attached.\n'
    exit 0
  fi
fi
if (( RESTART_PLASMA && ! PACKAGE_ONLY )) && ! systemctl --user is-active --quiet plasma-plasmashell.service; then
  printf 'Plasma is not managed by plasma-plasmashell.service. Install without --restart-plasma, then log out and back in. No installed files changed.\n' >&2
  exit 1
fi
mkdir -p "$BACKUP_BASE"
BACKUP="$(mktemp -d "$BACKUP_BASE/native-notifications-$(date +%Y%m%d-%H%M%S)-XXXXXX")"
for file in plasma-org.kde.plasma.desktop-appletsrc plasmashellrc; do
  [[ ! -f "$CONFIG_HOME/$file" ]] || cp -p "$CONFIG_HOME/$file" "$BACKUP/$file"
done
if [[ -d "${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids/$ID" ]]; then
  cp -a "${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids/$ID" "$BACKUP/$ID"
fi
printf 'Pre-change backup: %s\n' "$BACKUP"
MUTATING=1
if (( CURRENT )); then
  printf 'Notification package already current; checking live attachment.\n'
elif [[ -d "$INSTALLED" ]]; then
  # The package list also matches retired "$ID.rcNN" ids; trust the directory.
  kpackagetool6 --type Plasma/Applet --upgrade "$PACKAGE"
else
  kpackagetool6 --type Plasma/Applet --install "$PACKAGE"
fi
if (( PACKAGE_ONLY )); then
  COMMITTED=1
  printf 'Notification package installed. Add the Nothing Island + Dock layout to activate it.\n'
  exit 0
fi
# The SNI tray strip does not host Plasma applets. The real KDE notifications
# applet supplies screen geometry, settings and history for its Globals object.
NATIVE_SCRIPT='for(var i=0;i<panelIds.length;i++){var p=panelById(panelIds[i]);if(p&&p.type==="com.nothingplasma.panel"&&p.location==="top"){if(!p.widgets("org.kde.plasma.notifications").length)p.addWidget("org.kde.plasma.notifications");break}}'
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$NATIVE_SCRIPT"
# Remove only the old appearance adapter before reattaching it. Its
# reversible bindings restore KDE immediately; the native applet stays alive.
"$ROOT/rollback-native.sh"
SINCE="$(date --iso-8601=seconds)"
SCRIPT='var found=false; for (var i=0;i<panelIds.length;i++){var p=panelById(panelIds[i]);if(p&&p.type==="com.nothingplasma.panel"&&p.location==="top"){var n=p.addWidget("com.nothingplasma.notificationbridge");if(n){found=true;print("NOTHING_NOTIFICATION_BRIDGE_CREATED:"+n.id)}break}}if(!found)print("NOTHING_NOTIFICATION_BRIDGE_NOT_ATTACHED")'
RESULT="$(qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$SCRIPT")"
printf '%s\n' "$RESULT"
if [[ "$RESULT" != *NOTHING_NOTIFICATION_BRIDGE_CREATED:* ]]; then
  printf 'No existing Nothing top panel was found. No panel was created or removed.\n' >&2; exit 1
fi
if (( RESTART_PLASMA )); then
  printf 'Reloading Plasma to clear its cached QML; open applications are retained.\n'
  if systemctl --user is-active --quiet plasma-plasmashell.service; then
    systemctl --user restart plasma-plasmashell.service
  else
    printf 'This session is not managed by plasma-plasmashell.service. Log out and back in to reload cached QML.\n' >&2
    exit 1
  fi
fi
if command -v journalctl >/dev/null 2>&1; then
  ACTIVE=0
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    SHELL_PID="$(systemctl --user show plasma-plasmashell.service -p MainPID --value 2>/dev/null || true)"
    if [[ "$SHELL_PID" =~ ^[1-9][0-9]*$ ]]; then
      LOG="$(journalctl --user --since "$SINCE" "_PID=$SHELL_PID" --no-pager -o cat 2>/dev/null)"
    else
      LOG="$(journalctl --user --since "$SINCE" --no-pager -o cat 2>/dev/null)"
    fi
    if [[ "$LOG" == *NOTHING_NOTIFICATION_BRIDGE_ACTIVE:true* ]]; then ACTIVE=1; break; fi
    sleep 1
  done
  if (( ! ACTIVE )); then
    "$ROOT/rollback-native.sh"
    printf 'Adapter activation was not confirmed; restored native appearance. Check the plasmashell journal. Backup: %s\n' "$BACKUP" >&2
    exit 1
  fi
else
  printf 'Cannot confirm adapter activation without the Plasma journal.\n' >&2
  exit 1
fi
COMMITTED=1
printf 'Nothing notification adapter active. Native service and panel geometry retained.\n'
printf 'Rollback: %s/rollback-native.sh\n' "$ROOT"
