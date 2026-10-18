#!/usr/bin/env bash
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
build_dir="$(mktemp -d -t nothing-kde-package-XXXXXXXX)"
trap 'rm -rf -- "$build_dir"' EXIT
python3 "$ROOT/notification-skin/prepare-native.py" --output "$build_dir/notifications"
if command -v msgfmt >/dev/null; then python3 "$ROOT/po/build.py"; fi
if command -v msgfmt >/dev/null && [[ -f "$ROOT/plasma/aurorae/i18n/tr.po" ]]; then
  msgfmt "$ROOT/plasma/aurorae/i18n/tr.po" -o "$ROOT/plasma/aurorae/i18n/glassydecoration.mo"
fi
python3 "$ROOT/packaging/prepare-store.py" --notification-package "$build_dir/notifications" "$@"
