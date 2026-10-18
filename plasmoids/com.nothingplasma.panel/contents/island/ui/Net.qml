pragma Singleton

import QtQuick
import org.kde.bluezqt as BluezQt
import org.kde.kcmutils as KCMUtils
import org.kde.plasma.networkmanagement as PlasmaNM
import "."

// Network and Bluetooth state from Plasma's own NetworkManager and BlueZ bindings.
// Everything is event driven; passwords go to NetworkManager over D-Bus and never
// appear on a command line.
QtObject {
    id: root

    // ---- Wi-Fi and Ethernet (plasma-nm)
    readonly property PlasmaNM.NetworkModel networkModel: PlasmaNM.NetworkModel {}
    readonly property PlasmaNM.AppletProxyModel networks: PlasmaNM.AppletProxyModel { sourceModel: root.networkModel }
    readonly property PlasmaNM.EnabledConnections enabledConnections: PlasmaNM.EnabledConnections {}
    readonly property PlasmaNM.AvailableDevices availableDevices: PlasmaNM.AvailableDevices {}
    readonly property PlasmaNM.Handler handler: PlasmaNM.Handler {
        onConnectionActivationFailed: (connectionPath, message) => {
            const row = root.allRows.find(r => r.connectionPath === connectionPath);
            root.failed = row ? row.name : root.connecting;
            root.connecting = "";
        }
        onWifiCodeReceived: (data, ssid) => {
            root.wifiCode = data;
            root.wifiCodeSsid = ssid;
        }
    }
    readonly property Instantiator rows: Instantiator {
        model: root.networks
        delegate: QtObject {
            required property var model
            readonly property int type: model.Type
            readonly property bool wireless: type === PlasmaNM.Enums.Wireless
            readonly property string name: wireless ? (model.Ssid || model.ItemUniqueName) : model.ItemUniqueName
            readonly property string ssid: model.Ssid
            readonly property int signal: model.Signal
            readonly property int securityType: model.SecurityType
            readonly property bool secure: securityType !== PlasmaNM.Enums.NoneSecurity
                && securityType !== PlasmaNM.Enums.UnknownSecurity && securityType !== PlasmaNM.Enums.OWE
            // Plasma asks for a typed key only for these; EAP and others open KDE's own dialog.
            readonly property bool staticPassword: [PlasmaNM.Enums.StaticWep, PlasmaNM.Enums.WpaPsk,
                PlasmaNM.Enums.Wpa2Psk, PlasmaNM.Enums.SAE].includes(securityType)
            readonly property bool connected: model.ConnectionState === PlasmaNM.Enums.Activated
            readonly property bool activating: model.ConnectionState === PlasmaNM.Enums.Activating
            readonly property string uuid: model.Uuid
            readonly property bool saved: uuid.length > 0
            readonly property string connectionPath: model.ConnectionPath
            readonly property string devicePath: model.DevicePath
            readonly property string specificPath: model.SpecificPath
        }
    }
    readonly property var allRows: {
        const list = [];
        for (let i = 0; i < rows.count; ++i) {
            const row = rows.objectAt(i);
            if (row) list.push(row);
        }
        return list;
    }
    readonly property var wifiRows: allRows.filter(r => r.wireless)
    readonly property var activeWifi: wifiRows.find(r => r.connected) ?? null
    readonly property var activeWired: allRows.find(r => r.connected && r.type === PlasmaNM.Enums.Wired) ?? null

    readonly property bool wifiAvailable: availableDevices.wirelessDeviceAvailable
    readonly property bool wifiEnabled: enabledConnections.wirelessEnabled
    readonly property bool wifiHardwareEnabled: enabledConnections.wirelessHwEnabled
    readonly property bool connected: activeWifi !== null || activeWired !== null
    readonly property bool isWifi: activeWifi !== null
    readonly property bool wifiConnecting: wifiRows.some(r => r.activating) || connecting !== ""
    readonly property string connectionName: activeWifi?.name ?? activeWired?.name ?? ""
    readonly property int signal_: activeWifi?.signal ?? -1
    readonly property var nearbyNets: wifiRows
    readonly property var savedNets: wifiRows.filter(r => r.saved)

    readonly property bool scanning: handler.scanning
    readonly property bool hotspotSupported: handler.hotspotSupported
    readonly property bool hotspotActive: handler.hotspotActive
    readonly property bool airplaneMode: PlasmaNM.Configuration.airplaneModeEnabled

    property string connecting: ""
    property string failed: ""
    property string wifiCode: ""
    property string wifiCodeSsid: ""
    // While a password is typed the list must not reorder or rebuild its rows.
    property bool holdNetworkUpdates: false
    onHoldNetworkUpdatesChanged: networkModel.delayModelUpdates = holdNetworkUpdates

    readonly property Timer giveUp: Timer {
        interval: 30000
        onTriggered: {
            if (root.connecting) root.failed = root.connecting;
            root.connecting = "";
        }
    }
    function begin(ident) {
        root.failed = "";
        root.connecting = ident;
        root.giveUp.restart();
    }
    function wifiRow(name, saved) {
        return root.wifiRows.find(r => r.name === name && (saved === undefined || r.saved === saved)) ?? null;
    }
    onActiveWifiChanged: if (activeWifi && activeWifi.name === connecting) { connecting = ""; giveUp.stop(); }

    function refreshLists() {
        if (!Backend.preview && root.wifiEnabled) root.handler.requestScan();
    }
    function toggleWifi() {
        if (!Backend.preview) root.handler.enableWireless(!root.wifiEnabled);
    }
    function connectNet(name) {
        const row = root.wifiRow(name, true);
        if (!row || Backend.preview) return;
        root.begin(name);
        root.handler.activateConnection(row.connectionPath, row.devicePath, row.specificPath);
    }
    function joinNet(name, password) {
        const row = root.wifiRow(name, false);
        if (!row || Backend.preview) return;
        root.begin(name);
        if (password) root.handler.addAndActivateConnection(row.devicePath, row.specificPath, password);
        else root.handler.addAndActivateConnection(row.devicePath, row.specificPath);
    }
    function disconnectNet(name) {
        const row = root.wifiRow(name);
        if (row && !Backend.preview) root.handler.deactivateConnection(row.connectionPath, row.devicePath);
    }
    function forgetNet(name) {
        const row = root.wifiRow(name, true);
        if (row && !Backend.preview) root.handler.removeConnection(row.connectionPath);
    }
    function shareNet(name) {
        const row = root.wifiRow(name, true);
        root.wifiCode = "";
        if (row && !Backend.preview) root.handler.requestWifiCode(row.connectionPath, row.ssid, row.securityType);
    }
    function toggleHotspot() {
        if (Backend.preview) return;
        if (root.hotspotActive) root.handler.stopHotspot();
        else root.handler.createHotspot();
    }
    function toggleAirplaneMode() {
        if (Backend.preview) return;
        const enable = !root.airplaneMode;
        root.handler.enableAirplaneMode(enable);
        PlasmaNM.Configuration.airplaneModeEnabled = enable;
    }
    // Hidden, enterprise and VPN profiles are edited in KDE's own network settings.
    function openNetworkSettings() {
        if (!Backend.preview) KCMUtils.KCMLauncher.openSystemSettings("kcm_networkmanagement");
    }

    function openBluetoothSettings() {
        if (!Backend.preview) KCMUtils.KCMLauncher.openSystemSettings("kcm_bluetooth");
    }

    // ---- Bluetooth (BluezQt)
    readonly property var btManager: BluezQt.Manager
    readonly property bool btAvailable: btManager.adapters.length > 0
    readonly property bool btEnabled: btManager.bluetoothOperational
    readonly property bool btDiscovering: btManager.usableAdapter?.discovering ?? false
    readonly property var btDevices: btManager.devices.map(d => ({
        device: d,
        mac: d.address,
        name: d.name,
        type: d.type,
        paired: d.paired,
        connected: d.connected,
        battery: d.battery ? d.battery.percentage : -1
    }))
    readonly property var btKnown: btDevices.filter(d => d.paired)
    // Unnamed devices only report their address; they are noise in a picker.
    readonly property var btNearby: btDevices.filter(d => !d.paired && d.name
        && !/^([0-9A-F]{2}[-:]){5}[0-9A-F]{2}$/i.test(d.name))
    property bool ownsDiscovery: false

    function btDevice(mac) {
        return root.btManager.deviceForAddress(mac);
    }
    function settleCall(call, mac, after) {
        call.finished.connect(() => {
            if (call.error !== 0 && root.connecting === mac) root.failed = mac;
            if (root.connecting === mac) root.connecting = "";
            if (call.error === 0 && after) after();
        });
    }
    function toggleBt() {
        if (Backend.preview) return;
        // Same as Plasma's Bluetooth applet: clear the soft block and power every adapter.
        const enable = !root.btEnabled;
        root.btManager.bluetoothBlocked = !enable;
        for (const adapter of root.btManager.adapters) adapter.powered = enable;
    }
    function connectBt(mac) {
        const device = root.btDevice(mac);
        if (!device || Backend.preview) return;
        root.begin(mac);
        root.settleCall(device.connectToDevice(), mac);
    }
    function pairBt(mac) {
        const device = root.btDevice(mac);
        if (!device || Backend.preview) return;
        root.begin(mac);
        // Confirmation prompts come from KDE's Bluetooth agent (bluedevil).
        root.settleCall(device.pair(), mac, () => {
            device.trusted = true;
            root.begin(mac);
            root.settleCall(device.connectToDevice(), mac);
        });
    }
    function disconnectBt(mac) {
        const device = root.btDevice(mac);
        if (device && !Backend.preview) device.disconnectFromDevice();
    }
    function forgetBt(mac) {
        const device = root.btDevice(mac);
        if (device && device.adapter && !Backend.preview) device.adapter.removeDevice(device);
    }
    // Discovery runs only while the Bluetooth list is open, and only ours is stopped.
    function scanBt(on) {
        const adapter = root.btManager.usableAdapter;
        if (Backend.preview || !adapter) return;
        if (on && !adapter.discovering) {
            adapter.startDiscovery();
            root.ownsDiscovery = true;
        } else if (!on && root.ownsDiscovery) {
            if (adapter.discovering) adapter.stopDiscovery();
            root.ownsDiscovery = false;
        }
    }
}
