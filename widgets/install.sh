#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export PYTHONDONTWRITEBYTECODE=1
stage="$(mktemp -d -t nothing-widgets-XXXXXXXX)"
trap 'rm -rf -- "$stage"' EXIT
python3 "$ROOT/prepare.py" --output "$stage/packages"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
command -v kpackagetool6 >/dev/null
for name in battery clock-analog clock-digital clock-digital-large date media photo weather; do
  id="org.nothingkde.widget.$name"
  if [[ -d "$DATA_HOME/plasma/plasmoids/$id" ]] && diff -qr -- "$stage/packages/$name" "$DATA_HOME/plasma/plasmoids/$id" >/dev/null; then
    printf 'Already current: %s\n' "$id"
    continue
  fi
  if kpackagetool6 --type Plasma/Applet --show "$id" >/dev/null 2>&1; then
    kpackagetool6 --type Plasma/Applet --upgrade "$stage/packages/$name"
  else
    kpackagetool6 --type Plasma/Applet --install "$stage/packages/$name"
  fi
done
printf 'Nothing KDE: 8 desktop widgets installed. Add Widgets / Gereç Ekle. No panels or services changed.\n'
