#!/usr/bin/env bash
set -euo pipefail
# Remove only our bridge applets. Leave all native notifications and panels intact.
SCRIPT='var count=0;for(var i=0;i<panelIds.length;i++){var p=panelById(panelIds[i]);if(!p||p.type!=="com.nothingplasma.panel")continue;var ws=p.widgets("com.nothingplasma.notificationbridge");for(var j=0;j<ws.length;j++){ws[j].writeConfig("enabled",false);ws[j].reloadConfig();ws[j].remove();count++}}print("NOTHING_NOTIFICATION_BRIDGE_REMOVED:"+count)'
if command -v qdbus6 >/dev/null 2>&1; then
  qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$SCRIPT"
else
  printf 'qdbus6 is unavailable. No changes made.\n' >&2; exit 1
fi
printf 'Native notification service, native applet, and all panels were left untouched.\n'
