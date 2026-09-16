pragma Singleton

import QtQuick
import org.kde.plasma.plasma5support as P5Support
import "../../ui/components/RuntimePaths.js" as RuntimePaths
QtObject {
    id: root
    property bool wifiEnabled: false
    property bool connected: false
    property bool isWifi: false
    property string connectionName: ""
    property int signal_: -1

    property var savedNets: []
    property var nearbyNets: []
    property bool btEnabled: false
    property var btKnown: []
    property var btNearby: []
    property int netWatchers: 0
    property int btWatchers: 0
    property string connecting: ""
    property string failed: ""
    property string activeCmd: ""

    // Read NetworkManager's cached signal even when the network menu is closed;
    // this does not trigger a Wi-Fi scan or alter the connection.
    readonly property string baseCmd: Exec.command('export LC_ALL=C; nmcli -t -f TYPE,STATE,CONNECTION device; echo ---; nmcli radio wifi; echo ---; bluetoothctl show | grep Powered; echo ---; nmcli -t -f IN-USE,SIGNAL device wifi list --rescan no')

    readonly property string netListCmd: wifiCommand("scan")

    readonly property string btListCmd: Exec.command('bluetoothctl devices Paired; echo ---; bluetoothctl devices Connected; echo ---; bluetoothctl devices')

    function wifiCommand(args) {
        return RuntimePaths.command(Qt.resolvedUrl("../../tools/wifi.py"), "wifi.py", "python3", args);
    }
    function fields(line) {
        let result = [], current = "", escaped = false;
        for (const c of line) {
            if (escaped) { current += c; escaped = false; }
            else if (c === "\\") escaped = true;
            else if (c === ":") { result.push(current); current = ""; }
            else current += c;
        }
        result.push(current);
        return result;
    }

    readonly property P5Support.DataSource source: P5Support.DataSource {
        engine: "executable"
        connectedSources: []

        onNewData: (cmd, data) => {
            disconnectSource(cmd);
            const out = data["stdout"] ?? "";
            if (cmd === root.baseCmd)
                root.readBase(out);
            else if (cmd === root.netListCmd)
                root.readNetList(out);
            else if (cmd === root.btListCmd)
                root.readBtList(out);
        }
    }

    function readBase(text) {
        const parts = text.split("---");
        if (parts.length < 3)
            return;

        let conn = false, wifi = false, name = "";
        for (const line of parts[0].split("\n")) {
            const p = fields(line);
            if (p.length < 3 || p[1] !== "connected" || p[0] === "loopback")
                continue;
            conn = true;
            wifi = p[0] === "wifi";
            name = p[2];
            if (wifi)
                break;
        }
        root.connected = conn;
        root.isWifi = wifi;
        root.connectionName = name;
        root.signal_ = -1;
        if (wifi && parts.length > 3) {
            for (const line of parts[3].split("\n")) {
                const row = fields(line);
                if ((row[0] === "*" || row[0] === "yes") && /^\d+$/.test(row[1] || "")) {
                    root.signal_ = Math.max(root.signal_, Math.min(100, Number(row[1])));
                }
            }
        }

        root.wifiEnabled = parts[1].trim() === "enabled";
        root.btEnabled = /Powered:\s*yes/.test(parts[2]);
    }

    function readNetList(text) {
        try {
            const data = JSON.parse(text);
            root.nearbyNets = (data.networks || []).map(n => ({
                name: n.ssid, signal: n.signal, secure: !!n.security && n.security !== "--",
                connected: n.active, saved: n.saved, uuid: n.uuid
            }));
            root.savedNets = root.nearbyNets.filter(n => n.saved);
            // The compact indicator is updated by readBase independently of scans.
        } catch (error) { root.failed = Cfg.t("Couldn't connect"); }
    }

    function readBtList(text) {
        const parts = text.split("---");
        if (parts.length < 3)
            return;

        const on = {};
        for (const d of root.parseDevices(parts[1]))
            on[d.mac] = true;

        const paired = {};
        const known = [];
        for (const d of root.parseDevices(parts[0])) {
            paired[d.mac] = true;
            known.push({
                mac: d.mac,
                name: d.name,
                connected: !!on[d.mac]
            });
        }
        root.btKnown = known;
        root.btNearby = root.parseDevices(parts[2]).filter(d => !paired[d.mac]);
    }

    function parseDevices(text) {
        const list = [];
        for (const line of text.split("\n")) {
            const m = line.match(/^Device ([0-9A-F:]+) (.*)$/i);
            if (m)
                list.push({
                    mac: m[1],
                    name: m[2],
                    connected: false
                });
        }
        return list;
    }

    function refreshLists() {
        if (Backend.preview) return;
        if (root.netWatchers > 0)
            root.source.connectSource(root.netListCmd);
        if (root.btWatchers > 0)
            root.source.connectSource(root.btListCmd);
    }

    function toggleWifi() {
        Exec.run(`nmcli radio wifi ${root.wifiEnabled ? "off" : "on"}`);
        root.wifiEnabled = !root.wifiEnabled;
    }

    function toggleBt() {
        Exec.run(`bluetoothctl power ${root.btEnabled ? "off" : "on"}`);
        root.btEnabled = !root.btEnabled;
    }
    readonly property P5Support.DataSource runner: P5Support.DataSource {
        engine: "executable"
        connectedSources: []

        onNewData: (cmd, data) => {
            disconnectSource(cmd);
            if (cmd !== root.activeCmd)
                return;
            let ok = (data["exit code"] ?? -1) === 0;
            if (root.activeCmd.indexOf("activate") >= 0) {
                try { ok = ok && JSON.parse(data["stdout"]).ok === true; } catch (e) { ok = false; }
            }
            root.settle(ok);
        }
    }
    function quote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'";
    }

    function attempt(id, cmd) {
        if (Backend.preview || root.connecting) return;
        root.failed = "";
        root.connecting = id;
        root.activeCmd = cmd;
        root.giveUp.restart();
        root.hurry.restart();
        root.runner.connectSource(cmd);
    }

    function settle(ok) {
        root.giveUp.stop();
        if (!ok)
            root.failed = root.connecting;
        root.connecting = "";
        root.activeCmd = "";
        root.refreshLists();
    }
    readonly property Timer giveUp: Timer {
        interval: 30000
        onTriggered: {
            root.runner.disconnectSource(root.activeCmd);
            root.settle(false);
        }
    }
    readonly property Timer hurry: Timer {
        interval: 1500
        repeat: true
        running: root.connecting !== ""
        onTriggered: root.refreshLists()
    }

    function connectNet(name) {
        const row = root.savedNets.find(n => n.name === name);
        if (row?.uuid) root.attempt(name, wifiCommand("activate " + root.quote(row.uuid)));
    }
    function joinNet(ssid, password) {
        const extra = password ? ` password ${root.quote(password)}` : "";
        root.attempt(ssid, Exec.command(`nmcli --wait 25 device wifi connect ${root.quote(ssid)}${extra}`));
    }

    function disconnectNet(name) {
        const row = root.savedNets.find(n => n.name === name);
        if (row?.uuid) Exec.run(`nmcli connection down uuid ${root.quote(row.uuid)}`, () => root.refreshLists());
    }

    function forgetNet(name) {
        const row = root.savedNets.find(n => n.name === name);
        if (row?.uuid) Exec.run(`nmcli connection delete uuid ${root.quote(row.uuid)}`, () => root.refreshLists());
    }

    function connectBt(mac) {
        root.attempt(mac, Exec.command(`bluetoothctl --timeout 25 connect ${root.quote(mac)}`));
    }

    function disconnectBt(mac) {
        Exec.run(`bluetoothctl disconnect ${root.quote(mac)}`, () => root.refreshLists());
    }
    function pairBt(mac) {
        const address = root.quote(mac);
        root.attempt(mac, Exec.command(`bluetoothctl --timeout 20 pair ${address} && bluetoothctl trust ${address} && bluetoothctl --timeout 5 connect ${address}`));
    }

    function forgetBt(mac) {
        Exec.run(`bluetoothctl remove ${root.quote(mac)}`, () => root.refreshLists());
    }
    function scanBt(on) {
        if (on)
            Exec.run('bluetoothctl --timeout 4 scan on', () => root.refreshLists());
    }

    readonly property Timer tick: Timer {
        interval: 8000
        running: !Backend.preview
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.source.connectSource(root.baseCmd);
            root.refreshLists();
        }
    }
}
