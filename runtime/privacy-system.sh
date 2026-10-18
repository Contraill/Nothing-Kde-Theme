#!/usr/bin/env bash
# One-time system setup so the island can turn the camera off without a
# password. Run as root (through pkexec). Turning it back on still asks.
#   install: root-owned helper copy + polkit rule for "camera off" only
#   remove:  delete both
set -euo pipefail
HELPER=/usr/local/libexec/nothing-kde-privacy
RULE=/etc/polkit-1/rules.d/49-nothing-kde-privacy.rules
SOURCE="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/privacy.py"

[[ "$(id -u)" == 0 ]] || { echo 'run through pkexec' >&2; exit 1; }
case "${1:-}" in
  install)
    [[ -f "$SOURCE" ]] || { echo "missing $SOURCE" >&2; exit 1; }
    install -d -o root -g root -m 0755 /usr/local/libexec
    # A root-owned copy: the user must not be able to change what runs as root.
    # -I keeps Python from importing anything from the environment.
    tmp="$(mktemp "$HELPER.XXXXXX")"
    { printf '#!/usr/bin/python3 -I\n'; tail -n +2 -- "$SOURCE"; } > "$tmp"
    chown root:root "$tmp"; chmod 0755 "$tmp"; mv -f -- "$tmp" "$HELPER"
    cat > "$RULE.tmp" <<EOF
// Nothing KDE: the active local session may turn the camera off without a
// password. Turning it on, and every other action, keeps the default prompt.
polkit.addRule(function(action, subject) {
    if (action.id === "org.freedesktop.policykit.exec" &&
        action.lookup("program") === "$HELPER" &&
        action.lookup("command_line") === "$HELPER camera off" &&
        subject.local && subject.active) {
        return polkit.Result.YES;
    }
});
EOF
    chown root:root "$RULE.tmp"; chmod 0644 "$RULE.tmp"; mv -f -- "$RULE.tmp" "$RULE"
    echo 'Camera off now works without a password.'
    ;;
  remove)
    rm -f -- "$RULE" "$HELPER"
    echo 'Passwordless camera off removed.'
    ;;
  *) echo 'usage: privacy-system.sh install|remove' >&2; exit 2 ;;
esac
