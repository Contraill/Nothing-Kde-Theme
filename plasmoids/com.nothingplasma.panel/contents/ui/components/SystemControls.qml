pragma ComponentBehavior: Bound

import QtQuick
import "RuntimePaths.js" as RuntimePaths
import org.kde.plasma.plasmoid
import org.kde.plasma.private.brightnesscontrolplugin as Brightness

Item {
    id: root

    property bool autoWallpaper: true

    property bool themeBusy: false
    property string themeError: ""
    property bool accentBusy: false
    property string accentError: ""
    property color activeAccent: "transparent"
    property bool accentReady: false
    property int accentReadRevision: 0
    property var accentLinks: ({enabled: {}, available: {}})
    property bool linksBusy: false
    property string linksError: ""

    function accentLinksCommand(args) {
        return RuntimePaths.command(Qt.resolvedUrl("../../tools/accent-links.py"), "accent-links.py", "python3", args)
    }
    function refreshAccentLinks() {
        exec.run(root.accentLinksCommand("status"), function(r) {
            if (r.exitCode === 0) {
                try { root.accentLinks = JSON.parse(r.stdout) } catch (e) { root.linksError = String(e) }
            } else root.linksError = r.stderr
        })
    }
    function setAccentLink(target, enabled) {
        if (root.linksBusy || ["starship", "spaceship", "fastfetch"].indexOf(target) < 0) return
        root.linksBusy = true
        root.linksError = ""
        exec.run(root.accentLinksCommand((enabled ? "enable " : "disable ") + target), function(r) {
            root.linksBusy = false
            root.linksError = r.exitCode === 0 ? "" : r.stderr
            root.refreshAccentLinks()
        })
    }

    // PowerDevil's brightness API: every display (external DDC/CI monitors too)
    // and the keyboard backlight, with change notifications instead of polling.
    Brightness.ScreenBrightnessControl { id: screenControl; isSilent: true }
    Brightness.KeyboardBrightnessControl { id: keyboardControl; isSilent: true }
    Instantiator {
        id: displayRows
        model: screenControl.displays
        delegate: QtObject {
            required property string displayName
            required property string label
            required property int brightness
            required property int maxBrightness
            required property bool isInternal
            readonly property int percent: maxBrightness > 0 ? Math.round(brightness * 100 / maxBrightness) : 0
        }
    }
    readonly property var displays: {
        const list = [];
        for (let i = 0; i < displayRows.count; ++i) {
            const display = displayRows.objectAt(i);
            if (display) list.push(display);
        }
        return list;
    }
    readonly property var primaryDisplay: displays.find(d => d.isInternal) ?? displays[0] ?? null
    readonly property bool brightnessAvailable: screenControl.isBrightnessAvailable && primaryDisplay !== null
    readonly property int brightness: primaryDisplay?.percent ?? 0

    readonly property bool keyboardBrightnessAvailable: keyboardControl.isBrightnessAvailable && keyboardControl.brightnessMax > 0
    readonly property int keyboardBrightnessMax: keyboardControl.brightnessMax
    readonly property int keyboardBrightness: keyboardBrightnessMax > 0 ? Math.round(keyboardControl.brightness * 100 / keyboardBrightnessMax) : 0
    // Right-click on the brightness card lists every display and the keyboard.
    readonly property bool brightnessDetailsAvailable: keyboardBrightnessAvailable || displays.length > 1

    Exec { id: exec }

    function helperCommand(args) {
        return RuntimePaths.command(Qt.resolvedUrl("../../tools/nothing-control.sh"), "nothing-control.sh", "bash", args)
    }

    function retireLegacyInhibitors() {
        exec.run(root.helperCommand("retire-inhibitors"), function() {})
    }

    // The island draws volume/mute changes itself; keep Plasma's audio OSD in step.
    function setAudioOsd(inIsland) {
        exec.run(root.helperCommand("audio-osd " + (inIsland ? "island" : "plasma")), function(r) {
            if (r.exitCode !== 0) console.warn("Nothing audio OSD switch failed:", r.stderr)
        })
    }

    function ensureTray() {
        exec.run(root.helperCommand("ensure-tray"), function(r) {
            if (r.exitCode !== 0) console.warn("Nothing tray initialization failed:", r.stderr)
        })
    }

    function syncDesktopWallpaper(mode) {
        if (!root.autoWallpaper) return
        exec.run(root.helperCommand("wallpaper " + mode), function(r) {
            if (r.exitCode !== 0) console.warn("Nothing desktop wallpaper update failed:", r.stderr)
        })
    }

    function syncLockWallpaper() {
        if (!root.autoWallpaper) return
        const mode = Plasmoid.configuration.appearanceMode === "light" ? "light" : "dark"
        exec.run(root.helperCommand("lockscreen-wallpaper " + mode), function(r) {
            if (r.exitCode !== 0) console.warn("Nothing lock-screen wallpaper update failed:", r.stderr)
        })
    }

    function applyTheme(mode) {
        if (root.themeBusy || root.accentBusy || ["light", "dark"].indexOf(mode) < 0) return
        root.themeBusy = true
        root.themeError = ""
        // Update this instance immediately; the helper mirrors the mode
        // to the other installed Nothing panels.
        Plasmoid.configuration.appearanceMode = mode
        exec.run(root.helperCommand("theme " + mode + " " + (root.autoWallpaper ? "1" : "0")), function(r) {
            root.themeBusy = false
            root.themeError = r.exitCode === 0 ? "" : (r.stderr || "THEME SWITCH FAILED")
        })
    }

    function hexByte(value) {
        let s = Math.max(0, Math.min(255, Math.round(value * 255))).toString(16).toUpperCase()
        return s.length < 2 ? "0" + s : s
    }

    function colorToHex(value) {
        return "#" + root.hexByte(value.r) + root.hexByte(value.g) + root.hexByte(value.b)
    }

    function applyAccent(value) {
        if (root.accentBusy) return
        root.accentReadRevision++
        root.accentBusy = true
        root.accentError = ""
        const hex = root.colorToHex(value)
        // KDE is the single source of truth for accent. Every Nothing panel
        // observes Kirigami.Theme.focusColor (DecorationFocus), including newly-created panels.
        exec.run(root.helperCommand("accent " + hex.slice(1)), function(r) {
            root.accentBusy = false
            root.accentError = r.exitCode === 0 ? "" : (r.stderr || "Accent change failed")
            if (r.exitCode === 0) { root.activeAccent = hex; root.accentReady = true; }
        })
    }

    function syncAccentSchemeFiles() {
        // Kirigami already follows KDE's live accent. This mirrors that same
        // value into the paired Nothing .colors files so System Settings and
        // the panel never drift apart.
        exec.run(root.helperCommand("accent sync"), function() { root.refreshAccent(); })
    }

    function refreshAccent() {
        const revision = ++root.accentReadRevision
        exec.run(root.helperCommand("accent get"), function(r) {
            if (revision !== root.accentReadRevision) return
            const hex = r.stdout.trim();
            if (r.exitCode === 0 && /^#[0-9a-fA-F]{6}$/.test(hex)) {
                root.activeAccent = hex; root.accentReady = true;
            }
        })
    }
    function initAccent() {
        exec.run(root.helperCommand("accent init"), function() { root.refreshAccent(); })
    }


    function setDisplayBrightness(value, displayName) {
        const display = displayName ? root.displays.find(d => d.displayName === displayName) : root.primaryDisplay
        if (!display || !root.brightnessAvailable || !Number.isFinite(value)) return
        // Never fully dark: 1 % of the hardware range is the lowest value.
        const level = Math.round(Math.max(1, Math.min(100, value)) * display.maxBrightness / 100)
        screenControl.setBrightness(display.displayName, Math.max(1, level))
    }

    function setKeyboardBrightness(value) {
        if (!root.keyboardBrightnessAvailable || !Number.isFinite(value)) return
        keyboardControl.brightness = Math.round(Math.max(0, Math.min(100, value)) * root.keyboardBrightnessMax / 100)
    }
}
