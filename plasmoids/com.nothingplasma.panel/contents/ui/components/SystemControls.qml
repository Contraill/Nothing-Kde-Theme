pragma ComponentBehavior: Bound

import QtQuick
import "RuntimePaths.js" as RuntimePaths
import org.kde.plasma.plasmoid

Item {
    id: root

    property bool active: false
    property bool autoWallpaper: true

    property bool wifiAvailable: false
    property bool wifiEnabled: false
    property string wifiSsid: "—"
    property var wifiNetworks: []
    property string selectedWifiSsid: ""
    property string selectedWifiSecurity: ""
    property string selectedWifiUuid: ""
    property bool wifiConnecting: false
    property bool wifiNeedsPassword: false
    property int wifiOperationEpoch: 0
    property string wifiPassword: ""

    property bool bluetoothAvailable: false
    property bool bluetoothEnabled: false
    property var bluetoothDevices: []

    property string statusMessage: ""
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

    property string powerProfile: "balanced"
    property bool powerAvailable: false
    property int batteryPercent: -1
    property string batteryState: "unknown"
    property string batteryTime: ""

    property int volume: 50
    property bool volumeAvailable: false
    property bool muted: false
    property var audioOutputs: []
    property var audioInputs: []
    property int defaultAudioOutputId: -1
    property int defaultAudioInputId: -1
    property int inputVolume: 50
    property bool inputMuted: false
    property bool inputAvailable: false

    property int brightness: 50
    property bool brightnessAvailable: false

    property string keyboardDevice: ""
    property int keyboardBrightness: 0
    property bool keyboardBrightnessAvailable: false
    property int keyboardBrightnessMax: 0
    property bool keyboardRefreshPending: false
    readonly property string keyboardCommand: "qdbus6 org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/KeyboardBrightnessControl "

    Exec { id: exec }

    readonly property string batteryText: root.batteryPercent >= 0 ? String(root.batteryPercent) + "%" : "—"

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'"
    }

    function helperCommand(args) {
        return RuntimePaths.command(Qt.resolvedUrl("../../tools/nothing-control.sh"), "nothing-control.sh", "bash", args)
    }

    function boolFromText(text) {
        const t = String(text).trim().toLowerCase()
        return t === "enabled" || t === "yes" || t === "on" || t === "true"
    }

    function splitNmcli(line) {
        const fields = []
        let current = ""
        let escaped = false
        for (let i = 0; i < line.length; ++i) {
            const ch = line[i]
            if (escaped) {
                current += ch
                escaped = false
            } else if (ch === "\\") {
                escaped = true
            } else if (ch === ":") {
                fields.push(current)
                current = ""
            } else {
                current += ch
            }
        }
        fields.push(current)
        return fields
    }

    function parseWifiList(text) {
        const rows = []
        const seen = ({})
        const lines = String(text).split("\n")
        for (let i = 0; i < lines.length; ++i) {
            if (!lines[i]) continue
            const parts = root.splitNmcli(lines[i])
            if (parts.length < 4) continue
            const activeNetwork = parts[0] === "yes" || parts[0] === "*"
            const ssid = parts[1]
            if (!ssid || seen[ssid]) continue
            seen[ssid] = true
            rows.push({
                "active": activeNetwork,
                "ssid": ssid,
                "security": parts[2],
                "signal": parseInt(parts[3]) || 0
            })
        }
        return rows
    }

    function parseBluetoothList(text, connectedText) {
        const connected = ({})
        const connectedLines = String(connectedText).split("\n")
        for (let i = 0; i < connectedLines.length; ++i) {
            const p = connectedLines[i].trim().split(/\s+/)
            if (p.length >= 2) connected[p[1]] = true
        }

        const rows = []
        const lines = String(text).split("\n")
        for (let j = 0; j < lines.length; ++j) {
            const line = lines[j].trim()
            if (!line.startsWith("Device ")) continue
            const p = line.split(/\s+/)
            if (p.length < 3) continue
            rows.push({
                "mac": p[1],
                "name": p.slice(2).join(" "),
                "connected": connected[p[1]] === true
            })
        }
        return rows
    }

    function parseAudioDevices(text) {
        const outputs = []
        const inputs = []
        let section = ""
        const lines = String(text).split("\n")
        for (let i = 0; i < lines.length; ++i) {
            const line = lines[i]
            if (line.indexOf("Sinks:") >= 0) {
                section = "sink"
                continue
            }
            if (line.indexOf("Sources:") >= 0) {
                section = "source"
                continue
            }
            if (section && (line.indexOf("Filters:") >= 0 || line.indexOf("Streams:") >= 0 || line.indexOf("Video") >= 0)) {
                section = ""
                continue
            }
            if (!section) continue
            const match = line.match(/(?:^|\s)(\*)?\s*(\d+)\.\s+(.+?)(?:\s+\[vol:.*)?$/)
            if (!match) continue
            const entry = {
                "id": parseInt(match[2]),
                "name": match[3].trim(),
                "active": match[1] === "*"
            }
            if (section === "sink") outputs.push(entry)
            else inputs.push(entry)
        }
        return {"outputs": outputs, "inputs": inputs}
    }

    function wifiBackendCommand(args) {
        return RuntimePaths.command(Qt.resolvedUrl("../../tools/wifi.py"), "wifi.py", "python3", args)
    }

    function refreshWifiNetworks() {
        if (root.wifiConnecting) return
        root.statusMessage = "CHECKING WI-FI…"
        exec.run("nmcli -t -f WIFI g", function(stateResult) {
            root.wifiAvailable = stateResult.exitCode === 0
            root.wifiEnabled = root.wifiAvailable && root.boolFromText(stateResult.stdout)
            if (!root.wifiEnabled) {
                root.wifiNetworks = []
                root.wifiSsid = "OFF"
                root.statusMessage = "WI-FI OFF"
                return
            }
            root.statusMessage = "SCANNING WI-FI…"
            exec.run(root.wifiBackendCommand("scan"), function(r) {
                if (root.wifiConnecting) return
                if (r.exitCode !== 0) {
                    root.statusMessage = "WI-FI SCAN FAILED"
                    return
                }
                try {
                    const data = JSON.parse(r.stdout)
                    root.wifiNetworks = data.networks || []
                    const active = (data.active || [])
                    root.wifiSsid = active.length ? active[0].ssid : "NOT CONNECTED"
                    root.statusMessage = data.error || String(root.wifiNetworks.length) + " NETWORKS"
                } catch (e) {
                    root.statusMessage = "WI-FI DATA ERROR"
                }
            })
        })
    }

    function refreshBluetoothDevices() {
        root.statusMessage = "CHECKING BLUETOOTH…"
        exec.run("sh -c 'command -v bluetoothctl >/dev/null 2>&1 && bluetoothctl show 2>/dev/null | sed -n \"s/^[[:space:]]*Powered: //p\" | head -n1'", function(stateResult) {
            root.bluetoothAvailable = stateResult.exitCode === 0 && stateResult.stdout.length > 0
            root.bluetoothEnabled = root.bluetoothAvailable && root.boolFromText(stateResult.stdout)
            if (!root.bluetoothEnabled) {
                root.bluetoothDevices = []
                root.statusMessage = "BLUETOOTH OFF"
                return
            }

            root.statusMessage = "SCANNING BLUETOOTH…"
            exec.run("sh -c 'bluetoothctl --timeout 4 scan on >/dev/null 2>&1; bluetoothctl devices 2>/dev/null'", function(devicesResult) {
                exec.run("sh -c 'bluetoothctl devices Connected 2>/dev/null'", function(connectedResult) {
                    root.bluetoothDevices = root.parseBluetoothList(devicesResult.stdout, connectedResult.stdout)
                    root.statusMessage = root.bluetoothDevices.length ? String(root.bluetoothDevices.length) + " DEVICES" : "NO DEVICES"
                })
            })
        })
    }

    function connectWifi() {
        if (!root.selectedWifiSsid || root.wifiConnecting) return
        const secure = root.selectedWifiSecurity && root.selectedWifiSecurity !== "--" && root.selectedWifiSecurity !== "NONE"
        // Saved connections must be activated by their UUID so NetworkManager
        // can use its existing credentials. Never demand a password just because
        // an access point advertises security.
        const useSaved = root.selectedWifiUuid.length > 0 && !root.wifiNeedsPassword
        if (!useSaved && secure && !root.wifiPassword) {
            root.wifiNeedsPassword = true
            root.statusMessage = "PASSWORD REQUIRED"
            return
        }
        root.wifiConnecting = true
        const epoch = ++root.wifiOperationEpoch
        root.statusMessage = "CONNECTING…"
        let cmd = useSaved
            ? root.wifiBackendCommand("activate " + root.shellQuote(root.selectedWifiUuid))
            : "nmcli --wait 30 dev wifi connect " + root.shellQuote(root.selectedWifiSsid)
        if (!useSaved && secure) cmd += " password " + root.shellQuote(root.wifiPassword)
        exec.run(cmd, function(r) {
            if (epoch !== root.wifiOperationEpoch) return
            // Never report success based only on an nmcli command exit code.
            // Verify that NetworkManager actually has an active Wi-Fi profile.
            exec.run(root.wifiBackendCommand("state"), function(stateResult) {
                if (epoch !== root.wifiOperationEpoch) return
                root.wifiConnecting = false
                let active = []
                try { active = JSON.parse(stateResult.stdout).active || [] } catch (e) {}
                const connected = active.some(function(v) { return v.ssid === root.selectedWifiSsid })
                if (connected) {
                    root.wifiNeedsPassword = false
                    root.wifiPassword = ""
                    root.statusMessage = "CONNECTED"
                    root.wifiSsid = root.selectedWifiSsid
                } else {
                    let needsPassword = false
                    if (useSaved) {
                        try { needsPassword = JSON.parse(r.stdout).needsPassword === true } catch (e) {}
                    }
                    root.wifiNeedsPassword = needsPassword
                    root.statusMessage = needsPassword ? "PASSWORD REQUIRED"
                        : (r.stderr.length ? r.stderr : "CONNECTION FAILED")
                }
                // Delay the next scan to keep the operation result visible.
                wifiRefreshDelay.restart()
            })
        })
    }

    Timer {
        id: wifiRefreshDelay
        interval: 1200
        repeat: false
        onTriggered: root.refreshWifiNetworks()
    }

    function toggleBluetoothDevice(mac, connected) {
        root.statusMessage = connected ? "DISCONNECTING…" : "PAIRING / CONNECTING…"
        const cmd = connected
            ? "bluetoothctl disconnect " + root.shellQuote(mac)
            : "sh -c 'bluetoothctl pair " + mac + "; bluetoothctl trust " + mac + "; bluetoothctl connect " + mac + "'"
        exec.run(cmd, function(r) {
            root.statusMessage = r.exitCode === 0 ? "DONE" : (r.stderr.length ? r.stderr : "BLUETOOTH ACTION FAILED")
            root.refreshBluetoothDevices()
            root.refresh()
        })
    }

    function setWifiEnabled(enabled) {
        root.statusMessage = enabled ? "WI-FI ON…" : "WI-FI OFF…"
        exec.run("nmcli radio wifi " + (enabled ? "on" : "off"), function() {
            root.wifiEnabled = enabled
            root.refresh()
            if (enabled) root.refreshWifiNetworks()
            else root.wifiNetworks = []
        })
    }

    function setBluetoothEnabled(enabled) {
        root.statusMessage = enabled ? "BLUETOOTH ON…" : "BLUETOOTH OFF…"
        exec.run("bluetoothctl power " + (enabled ? "on" : "off"), function() {
            root.bluetoothEnabled = enabled
            root.refresh()
            if (enabled) root.refreshBluetoothDevices()
            else root.bluetoothDevices = []
        })
    }

    function setPower(profile) {
        exec.run("powerprofilesctl set " + profile, function() {
            root.powerProfile = profile
            root.refresh()
        })
    }

    function cyclePowerProfile() {
        if (!root.powerAvailable) return
        if (root.powerProfile === "power-saver") root.setPower("balanced")
        else if (root.powerProfile === "balanced") root.setPower("performance")
        else root.setPower("power-saver")
    }

    function retireLegacyInhibitors() {
        exec.run(root.helperCommand("retire-inhibitors"), function() {})
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
        root.statusMessage = mode === "light" ? "LIGHT THEME…" : "DARK THEME…"
        exec.run(root.helperCommand("theme " + mode + " " + (root.autoWallpaper ? "1" : "0")), function(r) {
            root.themeBusy = false
            root.themeError = r.exitCode === 0 ? "" : (r.stderr || "THEME SWITCH FAILED")
            root.statusMessage = r.exitCode === 0 ? (mode.toUpperCase() + " THEME") : (r.stderr.length ? r.stderr : "THEME SWITCH FAILED")
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
        // observes Kirigami.Theme.highlightColor, including newly-created panels.
        root.statusMessage = "ACCENT " + hex + "…"
        exec.run(root.helperCommand("accent " + hex.slice(1)), function(r) {
            root.accentBusy = false
            root.accentError = r.exitCode === 0 ? "" : (r.stderr || "Accent change failed")
            root.statusMessage = r.exitCode === 0 ? ("ACCENT " + hex) : (r.stderr.length ? r.stderr : "ACCENT CHANGE FAILED")
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


    function setOutputVolume(value) {
        if (!root.volumeAvailable) return
        exec.run("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + Math.round(value) + "%", function() { root.refreshAudio() })
    }

    function toggleOutputMute() {
        exec.run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", function() { root.refreshAudio() })
    }

    function setInputVolume(value) {
        if (!root.inputAvailable) return
        exec.run("wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " + Math.round(value) + "%", function() { root.refreshAudio() })
    }

    function toggleInputMute() {
        if (!root.inputAvailable) return
        exec.run("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", function() { root.refreshAudio() })
    }

    function setDefaultAudioOutput(id) {
        const numericId = Number(id)
        if (!Number.isFinite(numericId) || numericId < 0) return
        root.statusMessage = "SWITCHING OUTPUT…"
        exec.run("wpctl set-default " + Math.round(numericId), function(r) {
            root.statusMessage = r.exitCode === 0 ? "OUTPUT UPDATED" : "OUTPUT SWITCH FAILED"
            root.refreshAudio()
        })
    }

    function setDefaultAudioInput(id) {
        const numericId = Number(id)
        if (!Number.isFinite(numericId) || numericId < 0) return
        root.statusMessage = "SWITCHING INPUT…"
        exec.run("wpctl set-default " + Math.round(numericId), function(r) {
            root.statusMessage = r.exitCode === 0 ? "INPUT UPDATED" : "INPUT SWITCH FAILED"
            root.refreshAudio()
        })
    }

    function refreshAudio() {
        exec.run("sh -c 'command -v wpctl >/dev/null 2>&1 && wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null'", function(r) {
            root.volumeAvailable = r.exitCode === 0 && r.stdout.length > 0
            if (root.volumeAvailable) {
                const m = r.stdout.match(/Volume:\s+([0-9.]+)/)
                if (m) root.volume = Math.max(0, Math.min(100, Math.round(parseFloat(m[1]) * 100)))
                root.muted = r.stdout.indexOf("MUTED") >= 0
            }
        })
        exec.run("sh -c 'command -v wpctl >/dev/null 2>&1 && wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null'", function(r) {
            root.inputAvailable = r.exitCode === 0 && r.stdout.length > 0
            if (root.inputAvailable) {
                const m = r.stdout.match(/Volume:\s+([0-9.]+)/)
                if (m) root.inputVolume = Math.max(0, Math.min(100, Math.round(parseFloat(m[1]) * 100)))
                root.inputMuted = r.stdout.indexOf("MUTED") >= 0
            }
        })
        exec.run("sh -c 'command -v wpctl >/dev/null 2>&1 && wpctl status 2>/dev/null'", function(r) {
            if (r.exitCode !== 0) {
                root.audioOutputs = []
                root.audioInputs = []
                root.defaultAudioOutputId = -1
                root.defaultAudioInputId = -1
                return
            }
            const parsed = root.parseAudioDevices(r.stdout)
            root.audioOutputs = parsed.outputs
            root.audioInputs = parsed.inputs
            root.defaultAudioOutputId = -1
            root.defaultAudioInputId = -1
            for (let i = 0; i < root.audioOutputs.length; ++i) {
                if (root.audioOutputs[i].active) root.defaultAudioOutputId = root.audioOutputs[i].id
            }
            for (let j = 0; j < root.audioInputs.length; ++j) {
                if (root.audioInputs[j].active) root.defaultAudioInputId = root.audioInputs[j].id
            }
        })
    }

    function setDisplayBrightness(value) {
        if (!root.brightnessAvailable) return
        exec.run("brightnessctl -c backlight set " + Math.round(value) + "%", function() { root.refreshDisplayBrightness() })
    }

    function refreshDisplayBrightness() {
        exec.run("sh -c 'command -v brightnessctl >/dev/null 2>&1 && brightnessctl -c backlight -m 2>/dev/null | head -n1 | awk -F, \"{gsub(/%/,\\\"\\\",\\$4); print \\$4}\"'", function(r) {
            root.brightnessAvailable = r.exitCode === 0 && r.stdout.length > 0
            if (root.brightnessAvailable) root.brightness = Math.max(0, Math.min(100, parseInt(r.stdout)))
        })
    }

    function setKeyboardBrightness(value) {
        if (!root.keyboardBrightnessAvailable || root.keyboardBrightnessMax <= 0 || !Number.isFinite(value)) return
        const level = Math.round(Math.max(0, Math.min(100, value)) * root.keyboardBrightnessMax / 100)
        exec.run(root.keyboardCommand + "setKeyboardBrightness " + level, function(r) {
            if (r.exitCode !== 0) root.keyboardBrightnessAvailable = false
            root.refreshKeyboardBrightness()
        })
    }

    function refreshKeyboardBrightness() {
        if (root.keyboardRefreshPending) return
        root.keyboardRefreshPending = true
        exec.run(root.keyboardCommand + "keyboardBrightnessMax", function(r) {
            const maximum = Number(r.stdout)
            if (r.exitCode !== 0 || !r.stdout.length || !Number.isInteger(maximum) || maximum <= 0) {
                root.keyboardRefreshPending = false
                root.keyboardBrightnessAvailable = false
                root.keyboardBrightnessMax = 0
                root.keyboardDevice = ""
                return
            }
            exec.run(root.keyboardCommand + "keyboardBrightness", function(k) {
                root.keyboardRefreshPending = false
                const current = Number(k.stdout)
                root.keyboardBrightnessAvailable = k.exitCode === 0 && k.stdout.length > 0
                    && Number.isInteger(current) && current >= 0 && current <= maximum
                root.keyboardBrightnessMax = root.keyboardBrightnessAvailable ? maximum : 0
                root.keyboardDevice = root.keyboardBrightnessAvailable ? "PowerDevil" : ""
                if (root.keyboardBrightnessAvailable) root.keyboardBrightness = Math.round(current * 100 / maximum)
            })
        })
    }

    function refresh() {
        exec.run("sh -c 'command -v nmcli >/dev/null 2>&1 && nmcli -t -f WIFI g'", function(r) {
            root.wifiAvailable = r.exitCode === 0 && r.stdout.length > 0
            if (root.wifiAvailable) root.wifiEnabled = root.boolFromText(r.stdout)
        })

        exec.run("sh -c 'command -v nmcli >/dev/null 2>&1 && nmcli -t --escape no -f ACTIVE,SSID dev wifi 2>/dev/null | sed -n \"s/^yes://p\" | head -n1'", function(r) {
            root.wifiSsid = r.stdout.length ? r.stdout : (root.wifiEnabled ? "NOT CONNECTED" : "OFF")
        })

        exec.run("sh -c 'command -v bluetoothctl >/dev/null 2>&1 && bluetoothctl show 2>/dev/null | sed -n \"s/^[[:space:]]*Powered: //p\" | head -n1'", function(r) {
            root.bluetoothAvailable = r.exitCode === 0 && r.stdout.length > 0
            if (root.bluetoothAvailable) root.bluetoothEnabled = root.boolFromText(r.stdout)
        })

        exec.run("sh -c 'command -v powerprofilesctl >/dev/null 2>&1 && powerprofilesctl get'", function(r) {
            root.powerAvailable = r.exitCode === 0 && r.stdout.length > 0
            if (root.powerAvailable) root.powerProfile = r.stdout
        })

        root.refreshAudio()
        root.refreshDisplayBrightness()
        root.refreshKeyboardBrightness()

        exec.run("sh -c 'b=$(upower -e 2>/dev/null | grep -m1 BAT); [ -n \"$b\" ] && upower -i \"$b\"'", function(r) {
            if (!r.stdout.length) {
                root.batteryPercent = -1
                root.batteryState = "unknown"
                root.batteryTime = ""
                return
            }
            const pm = r.stdout.match(/percentage:\s*([0-9]+)%/)
            const sm = r.stdout.match(/state:\s*([^\n]+)/)
            const tm = r.stdout.match(/time to (empty|full):\s*([^\n]+)/)
            root.batteryPercent = pm ? parseInt(pm[1]) : -1
            root.batteryState = sm ? sm[1].trim() : "unknown"
            root.batteryTime = tm ? tm[2].trim() : ""
        })
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    onActiveChanged: if (root.active) root.refresh()
}
