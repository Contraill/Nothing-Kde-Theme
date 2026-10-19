// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.bluezqt as BluezQt
import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.plasma.private.volume as PA
import "../../../../shared" as Glassy
import "components"
import "everything"

// Wi-Fi, Bluetooth, airplane mode and sound as round tiles over a dotted
// volume bar, or the volume alone as a pill. Plasma's own network, Bluetooth
// and PulseAudio bindings do the work, as in the panel's island.
PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    NothingColors {
        id: nColors
        themeMode: Plasmoid.configuration.themeMode
        useSystemAccent: Plasmoid.configuration.useSystemAccent
    }
    Glassy.DotFont { id: dotFont }

    readonly property int variant: Plasmoid.configuration.widgetVariant

    readonly property PlasmaNM.Handler handler: PlasmaNM.Handler {}
    readonly property PlasmaNM.EnabledConnections connections: PlasmaNM.EnabledConnections {}
    readonly property bool airplane: PlasmaNM.Configuration.airplaneModeEnabled
    readonly property var bluetooth: BluezQt.Manager

    // The model connects to PulseAudio; PreferredDevice reads from it.
    readonly property PA.SinkModel sinks: PA.SinkModel {}
    readonly property var sink: PA.PreferredDevice.sink
    // PulseAudio's 100 % (PA_VOLUME_NORM).
    readonly property real volume: sink ? Math.min(1, sink.volume / 65536) : 0
    readonly property bool muted: sink?.muted ?? true

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
    function toggleBluetooth() {
        // Same as Plasma's Bluetooth applet: clear the soft block and power every adapter.
        const enable = !bluetooth.bluetoothOperational;
        bluetooth.bluetoothBlocked = !enable;
        for (const adapter of bluetooth.adapters) adapter.powered = enable;
    }
    function toggleAirplane() {
        const enable = !airplane;
        handler.enableAirplaneMode(enable);
        PlasmaNM.Configuration.airplaneModeEnabled = enable;
    }

    component Tile: ColumnLayout {
        id: tile
        property string glyph: ""
        property string label: ""
        property bool on: false
        property bool available: true
        signal toggled()
        spacing: 6
        opacity: available ? 1 : 0.4
        QQC2.AbstractButton {
            id: button
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 46
            implicitHeight: 46
            enabled: tile.available
            onClicked: tile.toggled()
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
                name: tile.glyph
                color: tile.on ? nColors.background : nColors.textPrimary
                accentColor: nColors.accent
            }
            topPadding: 13
            bottomPadding: 13
            leftPadding: 13
            rightPadding: 13
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: tile.label
            font.pixelSize: 10
            font.letterSpacing: 1
            color: nColors.textSecondary
        }
    }

    // EveryThing-UI's single utilities: 2 to 7 are Wi-Fi, Bluetooth and
    // airplane mode as a pill then a circle; 8 and 9 the volume block and pill.
    readonly property bool every: variant >= 2
    readonly property string everyKind: variant >= 8 ? "volume" : ["wifi", "bluetooth", "airplane"][Math.floor((variant - 2) / 2)] ?? "wifi"
    readonly property bool everyRound: variant >= 8 ? variant === 9 : variant % 2 === 1
    readonly property bool everyOn: everyKind === "wifi" ? connections.wirelessEnabled
        : everyKind === "bluetooth" ? bluetooth.bluetoothOperational : everyKind === "airplane" ? airplane : !muted
    function everyToggle() {
        if (everyKind === "wifi") handler.enableWireless(!connections.wirelessEnabled);
        else if (everyKind === "bluetooth") toggleBluetooth();
        else if (everyKind === "airplane") toggleAirplane();
        else if (sink) sink.muted = !sink.muted;
    }

    fullRepresentation: Item {
        Layout.preferredWidth: root.every ? (root.everyRound && root.everyKind !== "volume" ? 105 : 200) : root.variant === 1 ? 190 : 270
        Layout.preferredHeight: root.every ? (root.everyKind === "volume" && !root.everyRound ? 200 : 105) : root.variant === 1 ? 84 : 170
        Layout.minimumWidth: root.every ? 80 : root.variant === 1 ? 150 : 240
        Layout.minimumHeight: root.every ? 80 : root.variant === 1 ? 64 : 150

        EveryToggle {
            anchors.fill: parent
            anchors.margins: 4
            visible: root.every
            colors: nColors
            family: dotFont.name
            kind: root.everyKind
            round: root.everyRound
            on: root.everyOn
            volume: root.volume
            muted: root.muted
            onToggled: root.everyToggle()
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                enabled: root.everyKind === "volume"
                onWheel: wheel => root.wheel(wheel)
            }
        }

        Glassy.GlassySurface {
            id: card
            visible: !root.every
            anchors.fill: parent
            anchors.margins: 10
            cornerRadius: root.variant === 1 ? height / 2 : 20
            backgroundColor: nColors.background
            foregroundColor: nColors.textPrimary
        }

        // 0: four toggles over the volume.
        ColumnLayout {
            anchors.fill: card
            anchors.margins: 14
            visible: root.variant === 0
            spacing: 12
            RowLayout {
                Layout.fillWidth: true
                Tile {
                    Layout.fillWidth: true
                    glyph: "wifi"
                    label: i18n("Wi-Fi")
                    on: root.connections.wirelessEnabled
                    available: root.connections.wirelessHwEnabled
                    onToggled: root.handler.enableWireless(!root.connections.wirelessEnabled)
                }
                Tile {
                    Layout.fillWidth: true
                    glyph: "bluetooth"
                    label: i18n("Bluetooth")
                    on: root.bluetooth.bluetoothOperational
                    available: root.bluetooth.adapters.length > 0
                    onToggled: root.toggleBluetooth()
                }
                Tile {
                    Layout.fillWidth: true
                    glyph: "airplane"
                    label: i18n("Airplane")
                    on: root.airplane
                    onToggled: root.toggleAirplane()
                }
                Tile {
                    Layout.fillWidth: true
                    glyph: root.muted ? "mute" : "volume"
                    label: i18n("Sound")
                    on: !root.muted
                    available: !!root.sink
                    onToggled: root.sink.muted = !root.sink.muted
                }
            }
            Glassy.DotMeter {
                Layout.fillWidth: true
                colors: nColors
                alert: false
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
            onClicked: if (root.sink) root.sink.muted = !root.sink.muted
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
