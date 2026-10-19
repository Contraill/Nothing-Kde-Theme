// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.bluezqt as BluezQt
import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.plasma.private.volume as PA
import org.kde.plasma.private.batterymonitor as BatteryMonitor
import org.kde.plasma.private.brightnesscontrolplugin as Brightness
import org.kde.notificationmanager as NotificationManager
import "../../../../shared" as Glassy
import "components"
import "everything"

// The toggles you pick (Wi-Fi, Bluetooth, airplane mode, sound, microphone,
// do not disturb, night light, coffee mode, power profile, hotspot) as round
// tiles over a dotted volume bar, the volume alone as a pill, or one toggle as
// the adapted pill or circle. Plasma's own bindings do the work.
PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    NothingColors {
        id: nColors
        themeMode: Plasmoid.configuration.themeMode
        useSystemAccent: Plasmoid.configuration.useSystemAccent
        monochrome: Plasmoid.configuration.monochrome
    }
    Glassy.DotFont { id: dotFont }

    readonly property int variant: Plasmoid.configuration.widgetVariant

    readonly property PlasmaNM.Handler handler: PlasmaNM.Handler {}
    readonly property PlasmaNM.EnabledConnections connections: PlasmaNM.EnabledConnections {}
    readonly property bool airplane: PlasmaNM.Configuration.airplaneModeEnabled
    readonly property var bluetooth: BluezQt.Manager

    // The models connect to PulseAudio; PreferredDevice reads from them.
    readonly property PA.SinkModel sinks: PA.SinkModel {}
    readonly property PA.SourceModel sources: PA.SourceModel {}
    readonly property var sink: PA.PreferredDevice.sink
    readonly property var source: PA.PreferredDevice.source
    // PulseAudio's 100 % (PA_VOLUME_NORM).
    readonly property real volume: sink ? Math.min(1, sink.volume / 65536) : 0
    readonly property bool muted: sink?.muted ?? true

    readonly property NotificationManager.Settings notifications: NotificationManager.Settings {}
    readonly property BatteryMonitor.InhibitionControl inhibition: BatteryMonitor.InhibitionControl {}
    readonly property BatteryMonitor.PowerProfilesControl powerProfiles: BatteryMonitor.PowerProfilesControl {}

    // Night light: KWin says whether it is set up; Plasma's inhibitor pauses it.
    property bool nightLightEnabled: false
    P5Support.DataSource {
        id: shell
        engine: "executable"
        onNewData: (source, data) => {
            disconnectSource(source);
            if (source === root.nightLightQuery) root.nightLightEnabled = /enabled: true/.test(data.stdout ?? "");
        }
    }
    readonly property string nightLightQuery: "q=$(command -v qdbus6 || command -v qdbus); $q org.kde.KWin /org/kde/KWin/NightLight org.freedesktop.DBus.Properties.GetAll org.kde.KWin.NightLight"
    Timer {
        interval: 10000
        repeat: true
        running: root.shown.includes("nightlight")
        triggeredOnStart: true
        onTriggered: shell.connectSource(root.nightLightQuery)
    }

    readonly property var allToggles: ["wifi", "bluetooth", "airplane", "sound", "microphone", "dnd", "nightlight", "coffee", "power", "hotspot"]
    // The tiles, or the one toggle of the pill and circle; 4 to 7 were
    // Bluetooth and airplane mode before any toggle could be picked.
    readonly property var tileList: String(Plasmoid.configuration.tileToggles).split(",").filter(k => allToggles.includes(k) || k === "volume")
    readonly property string single: variant >= 4 && variant <= 7 ? ["bluetooth", "airplane"][Math.floor((variant - 4) / 2)]
        : allToggles.includes(Plasmoid.configuration.singleToggle) ? Plasmoid.configuration.singleToggle : "wifi"
    readonly property var shown: variant === 0 ? tileList : variant >= 2 && variant <= 7 ? [single] : []
    readonly property var tiles: tileList.filter(k => k !== "volume")

    function glyphOf(key) {
        return {wifi: "wifi", bluetooth: "bluetooth", airplane: "airplane", sound: muted ? "mute" : "volume",
                microphone: isOn("microphone") ? "mic" : "mic-off", dnd: "moon", nightlight: "nightlight",
                coffee: "coffee", power: "bolt", hotspot: "hotspot"}[key] ?? "wifi";
    }
    function labelOf(key) {
        if (key === "power") {
            const profile = powerProfiles.activeProfile;
            return profile === "performance" ? i18n("Performance") : profile === "power-saver" ? i18n("Power saver") : i18n("Balanced");
        }
        return {wifi: i18n("Wi-Fi"), bluetooth: i18n("Bluetooth"), airplane: i18n("Airplane"), sound: i18n("Sound"),
                microphone: i18n("Microphone"), dnd: i18n("Do not disturb"), nightlight: i18n("Night light"),
                coffee: i18n("Coffee"), hotspot: i18n("Hotspot")}[key] ?? key;
    }
    function isOn(key) {
        switch (key) {
        case "wifi": return connections.wirelessEnabled;
        case "bluetooth": return bluetooth.bluetoothOperational;
        case "airplane": return airplane;
        case "sound": return !muted;
        case "microphone": return !(source?.muted ?? true);
        case "dnd": return notifications.notificationsInhibitedUntil > new Date();
        case "nightlight": return nightLightEnabled && !Brightness.NightLightInhibitor.inhibited;
        case "coffee": return inhibition.isManuallyInhibited;
        case "power": return powerProfiles.activeProfile !== "" && powerProfiles.activeProfile !== "balanced";
        case "hotspot": return handler.hotspotActive;
        }
        return false;
    }
    function isAvailable(key) {
        switch (key) {
        case "wifi": return connections.wirelessHwEnabled;
        case "bluetooth": return bluetooth.adapters.length > 0;
        case "sound": return !!sink;
        case "microphone": return !!source;
        case "power": return powerProfiles.isPowerProfileDaemonInstalled && powerProfiles.profiles.length > 1;
        case "hotspot": return handler.hotspotSupported;
        }
        return true;
    }
    function toggle(key) {
        switch (key) {
        case "wifi": handler.enableWireless(!connections.wirelessEnabled); break;
        case "bluetooth": {
            // Same as Plasma's Bluetooth applet: clear the soft block and power every adapter.
            const enable = !bluetooth.bluetoothOperational;
            bluetooth.bluetoothBlocked = !enable;
            for (const adapter of bluetooth.adapters) adapter.powered = enable;
            break;
        }
        case "airplane": {
            const enable = !airplane;
            handler.enableAirplaneMode(enable);
            PlasmaNM.Configuration.airplaneModeEnabled = enable;
            break;
        }
        case "sound": if (sink) sink.muted = !sink.muted; break;
        case "microphone": if (source) source.muted = !source.muted; break;
        case "dnd":
            // As Plasma's notification applet: a year ahead, or back to normal.
            if (isOn("dnd")) {
                notifications.notificationsInhibitedUntil = undefined;
                notifications.revokeApplicationInhibitions();
            } else {
                const until = new Date();
                until.setFullYear(until.getFullYear() + 1);
                notifications.notificationsInhibitedUntil = until;
            }
            notifications.save();
            break;
        case "nightlight":
            // Not set up: switch it on in KWin's settings; set up: pause it, as Plasma's own button.
            if (!nightLightEnabled) {
                shell.connectSource("kwriteconfig6 --file kwinrc --group NightColor --key Active true && q=$(command -v qdbus6 || command -v qdbus) && $q org.kde.KWin /KWin reconfigure");
                nightLightEnabled = true;
            } else {
                Brightness.NightLightInhibitor.toggleInhibition();
            }
            break;
        case "coffee":
            if (inhibition.isManuallyInhibited) inhibition.uninhibit();
            else inhibition.inhibit(i18n("Coffee mode from the quick toggles"));
            break;
        case "power": {
            // Round the daemon's profiles: saver, balanced, performance.
            const list = powerProfiles.profiles.map(p => p.Profile ?? p).filter(p => typeof p === "string");
            const next = list[(list.indexOf(powerProfiles.activeProfile) + 1) % Math.max(1, list.length)];
            if (next) shell.connectSource("powerprofilesctl set " + next.replace(/[^a-z-]/g, ""));
            break;
        }
        case "hotspot":
            if (handler.hotspotActive) handler.stopHotspot();
            else handler.createHotspot();
            break;
        }
    }

    function setVolume(value) {
        if (!sink || !sink.volumeWritable) return;
        sink.volume = Math.round(Math.max(0, Math.min(1, value)) * 65536);
        if (value > 0 && sink.muted) sink.muted = false;
    }
    // One wheel notch (120) is 5 %.
    property real wheelRemainder: 0
    function wheel(event) {
        wheelRemainder += event.angleDelta.y;
        while (Math.abs(wheelRemainder) >= 120) {
            const direction = wheelRemainder > 0 ? 1 : -1;
            wheelRemainder -= direction * 120;
            setVolume(Math.round((volume + direction * 0.05) * 20) / 20);
        }
    }

    component Tile: ColumnLayout {
        id: tile
        required property string modelData
        readonly property bool on: root.isOn(modelData)
        readonly property bool available: root.isAvailable(modelData)
        readonly property string label: root.labelOf(modelData)
        spacing: 6
        opacity: available ? 1 : 0.4
        QQC2.AbstractButton {
            id: button
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 46
            implicitHeight: 46
            enabled: tile.available
            onClicked: root.toggle(tile.modelData)
            QQC2.ToolTip.text: tile.label
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: 600
            Accessible.name: tile.label
            Accessible.checkable: true
            Accessible.checked: tile.on
            background: Rectangle {
                radius: width / 2
                color: tile.on ? nColors.textPrimary : nColors.alpha(nColors.textPrimary, button.hovered ? 0.16 : 0.08)
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            contentItem: Glassy.DotGlyph {
                name: root.glyphOf(tile.modelData)
                color: tile.on ? nColors.background : nColors.textPrimary
                accentColor: nColors.accent
            }
            topPadding: 13
            bottomPadding: 13
            leftPadding: 13
            rightPadding: 13
        }
        Text {
            Layout.fillWidth: true
            text: tile.label
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.pixelSize: 10
            font.letterSpacing: 1
            color: nColors.textSecondary
        }
    }

    readonly property bool every: variant >= 2
    readonly property bool volumeDesign: variant >= 8
    readonly property string everyKind: volumeDesign ? "volume" : single
    readonly property bool everyRound: volumeDesign ? variant === 9 : variant === 3 || variant === 5 || variant === 7
    // Tiles in rows of four.
    readonly property int tileRows: Math.ceil(Math.max(1, tiles.length) / 4)
    readonly property bool volumeBar: tileList.includes("volume")

    fullRepresentation: Item {
        Layout.preferredWidth: root.every ? (root.everyRound && !root.volumeDesign ? 115 : 200) : root.variant === 1 ? 190 : 290
        Layout.preferredHeight: root.every ? (root.volumeDesign && !root.everyRound ? 200 : root.everyRound && !root.volumeDesign ? 115 : 110)
            : root.variant === 1 ? 84 : 48 + 80 * root.tileRows + (root.volumeBar ? 42 : 0)
        Layout.minimumWidth: root.every ? 80 : root.variant === 1 ? 150 : 240
        Layout.minimumHeight: root.every ? 80 : root.variant === 1 ? 64 : 110

        EveryToggle {
            anchors.fill: parent
            visible: root.every
            colors: nColors
            family: dotFont.name
            transparent: Plasmoid.configuration.transparent
            kind: root.everyKind
            glyph: ["wifi", "bluetooth", "airplane", "volume"].includes(root.everyKind) ? "" : root.glyphOf(root.everyKind)
            label: ["wifi", "bluetooth", "airplane", "volume"].includes(root.everyKind) ? "" : root.labelOf(root.everyKind)
            round: root.everyRound
            on: root.volumeDesign ? !root.muted : root.isOn(root.everyKind)
            volume: root.volume
            muted: root.muted
            onToggled: root.volumeDesign ? root.toggle("sound") : root.toggle(root.everyKind)
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                enabled: root.volumeDesign
                onWheel: wheel => root.wheel(wheel)
            }
        }

        Glassy.GlassySurface {
            id: card
            visible: !root.every
            bare: Plasmoid.configuration.transparent
            anchors.fill: parent
            anchors.margins: 10
            cornerRadius: root.variant === 1 ? height / 2 : 20
            backgroundColor: nColors.background
            foregroundColor: nColors.textPrimary
        }

        // 0: the chosen toggles over the volume.
        ColumnLayout {
            anchors.fill: card
            anchors.margins: 14
            visible: root.variant === 0
            spacing: 12
            GridLayout {
                Layout.fillWidth: true
                columns: 4
                rowSpacing: 10
                Repeater {
                    model: root.variant === 0 ? root.tiles : []
                    // Equal columns whatever the labels say.
                    Tile { Layout.fillWidth: true; Layout.preferredWidth: 1 }
                }
            }
            Item { Layout.fillHeight: true }
            Glassy.DotMeter {
                Layout.fillWidth: true
                visible: root.volumeBar
                colors: nColors
                label: i18n("VOLUME")
                percent: root.muted ? 0 : root.volume * 100
                opacity: root.sink ? 1 : 0.4
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    onPressed: mouse => root.setVolume(mouse.x / width)
                    onPositionChanged: mouse => { if (pressed) root.setVolume(mouse.x / width) }
                    onWheel: wheel => root.wheel(wheel)
                }
            }
        }

        // 1: the volume as a pill; click to mute, scroll to change.
        MouseArea {
            anchors.fill: card
            visible: root.variant === 1
            onClicked: root.toggle("sound")
            onWheel: wheel => root.wheel(wheel)
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 20
                spacing: 12
                Item {
                    Layout.preferredWidth: card.height - 24
                    Layout.preferredHeight: card.height - 24
                    Glassy.DotRing {
                        anchors.fill: parent
                        count: 20
                        value: root.muted ? 0 : root.volume
                        litColor: nColors.accent
                        dimColor: nColors.divider
                    }
                    Glassy.DotGlyph {
                        anchors.centerIn: parent
                        width: parent.width * 0.42
                        height: width
                        name: root.muted ? "mute" : "volume"
                        color: nColors.textPrimary
                        accentColor: nColors.accent
                    }
                }
                Column {
                    Layout.fillWidth: true
                    Text { text: Math.round(root.volume * 100) + "%"; color: root.muted ? nColors.textMuted : nColors.textPrimary; font.family: dotFont.name; font.pixelSize: Math.max(14, card.height * 0.26) }
                    Text { text: root.muted ? i18n("MUTED") : i18n("VOL"); color: root.muted ? nColors.accent : nColors.textSecondary; font.pixelSize: 10; font.letterSpacing: 1.5 }
                }
            }
        }
    }
}
