// SPDX-License-Identifier: GPL-3.0-or-later
.pragma library

function quote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'";
}

// Store packages carry these one-shot helpers. Source installs also support
// the existing data directory; neither path starts a custom daemon.
function command(url, file, interpreter, args) {
    const bundled = decodeURIComponent(String(url).replace(/^file:\/\//, ""));
    const legacy = '"${XDG_DATA_HOME:-$HOME/.local/share}/nothing-plasma/bin/' + file + '"';
    const script = "if [ -f " + quote(bundled) + " ]; then " + interpreter + " "
        + quote(bundled) + " " + args + "; else " + interpreter + " "
        + legacy + " " + args + "; fi";
    return "sh -c " + quote(script);
}
