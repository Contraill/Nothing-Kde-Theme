// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import org.kde.bluezqt as BluezQt
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import "../../../../shared" as Glassy
import "components"

// This computer's battery and those of connected Bluetooth devices: a grid
// of rings, one large ring, or a block with the time left.
PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    NothingColors {
        id: nColors
        themeMode: Plasmoid.configuration.themeMode
        useSystemAccent: Plasmoid.configuration.useSystemAccent
    }
    Glassy.DotFont { id: dots }
    Glassy.DotFont { id: bigDots; light: true }

    readonly property int variant: Plasmoid.configuration.widgetVariant
    P5Support.DataSource {
        id: power
        engine: "powermanagement"
        connectedSources: ["Battery", "AC Adapter"]
        interval: Math.max(1000, Plasmoid.configuration.updateInterval)
    }
    readonly property var battery: power.data["Battery"] ?? ({})
    readonly property bool hasBattery: battery["Has Battery"] === true
    readonly property int percent: battery["Percent"] ?? 0
    readonly property string state: battery["State"] ?? ""
    readonly property bool charging: state === "Charging"
    readonly property bool plugged: power.data["AC Adapter"]?.["Plugged in"] === true
    readonly property real remaining: battery["Smoothed Remaining msec"] || battery["Remaining msec"] || 0

    // Connected Bluetooth devices that report a battery level.
    readonly property var devices: BluezQt.Manager.devices.filter(d => d.connected && d.battery)
    function glyphFor(device) {
        switch (device.type) {
        case BluezQt.Device.Phone: return "phone";
        case BluezQt.Device.Computer: return "laptop";
        case BluezQt.Device.Keyboard: return "keyboard";
        case BluezQt.Device.Mouse: return "mouse";
        case BluezQt.Device.Joypad: return "gamepad";
        case BluezQt.Device.Headset: case BluezQt.Device.Headphones: return device.name.toLowerCase().includes("buds") ? "earbuds" : "headphones";
        case BluezQt.Device.AudioVideo: return "speaker";
        case BluezQt.Device.Wearable: return "watch";
        default: return "bluetooth";
        }
    }
    readonly property var entries: (hasBattery ? [{glyph: Plasmoid.configuration.deviceType === "computer" ? "computer" : "laptop",
                                                   percent: percent, charging: charging, name: i18n("This computer")}] : [])
        .concat(devices.map(d => ({glyph: glyphFor(d), percent: d.battery.percentage, charging: false, name: d.name})))

    function duration(msec) {
        const minutes = Math.round(msec / 60000);
        return minutes >= 60 ? i18n("%1 h %2 min", Math.floor(minutes / 60), minutes % 60) : i18n("%1 min", minutes);
    }
    readonly property string statusText: state === "FullyCharged" ? i18n("Fully charged")
        : charging ? (remaining > 0 ? i18n("Full in %1", duration(remaining)) : i18n("Charging"))
        : state === "NoCharge" ? i18n("Plugged in, not charging")
        : remaining > 0 ? i18n("%1 left", duration(remaining)) : ""

    // One device: a ring of dots around its picture and level.
    component DeviceRing: Item {
        id: ring
        required property var entry
        Glassy.DotRing {
            anchors.fill: parent
            count: 30
            value: ring.entry.percent / 100
            litColor: ring.entry.charging ? nColors.accent : ring.entry.percent <= 15 ? nColors.error : nColors.textPrimary
            dimColor: nColors.divider
        }
        Column {
            anchors.centerIn: parent
            spacing: ring.height * 0.04
            Glassy.DotGlyph {
                anchors.horizontalCenter: parent.horizontalCenter
                width: ring.width * 0.32
                height: ring.height * 0.25
                name: ring.entry.charging ? "bolt" : ring.entry.glyph
                color: ring.entry.charging ? nColors.accent : nColors.textPrimary
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: ring.entry.percent + "%"
                color: nColors.textPrimary
                font.family: dots.name
                font.pixelSize: ring.height * 0.15
            }
        }
    }

    fullRepresentation: Item {
        Layout.preferredWidth: root.variant === 2 ? 260 : 200
        Layout.preferredHeight: root.variant === 2 ? 130 : 200
        Layout.minimumWidth: 140
        Layout.minimumHeight: root.variant === 2 ? 100 : 140

        Glassy.GlassySurface {
            id: card
            anchors.fill: parent
            anchors.margins: 10
            cornerRadius: root.variant === 1 ? Math.min(width, height) / 2 : 22
            backgroundColor: nColors.background
            foregroundColor: nColors.textPrimary
        }
        Text {
            anchors.centerIn: card
            visible: root.entries.length === 0
            text: i18n("No batteries")
            color: nColors.textSecondary
        }

        // 0: every device; one fills the card, two sit side by side, more make a grid.
        Grid {
            id: grid
            anchors.centerIn: card
            visible: root.variant === 0
            readonly property int shown: Math.min(4, root.entries.length)
            columns: shown > 1 ? 2 : 1
            spacing: 10
            readonly property real cell: Math.min((card.width - 24 - (columns - 1) * spacing) / columns,
                                                  (card.height - 24 - (shown > 2 ? spacing : 0)) / (shown > 2 ? 2 : 1))
            Repeater {
                model: root.entries.slice(0, 4)
                DeviceRing {
                    required property var modelData
                    entry: modelData
                    width: grid.cell
                    height: grid.cell
                }
            }
        }

        // 1: this computer as one large ring.
        DeviceRing {
            anchors.centerIn: card
            width: Math.min(card.width, card.height) - 24
            height: width
            visible: root.variant === 1 && root.entries.length > 0
            entry: root.entries[0] ?? {glyph: "laptop", percent: 0, charging: false}
        }

        // 2: a block: level, status and a dotted bar.
        ColumnLayout {
            anchors.fill: card
            anchors.margins: 16
            visible: root.variant === 2 && root.hasBattery
            spacing: 4
            RowLayout {
                Text {
                    text: root.percent + "%"
                    color: nColors.textPrimary
                    font.family: bigDots.name
                    font.pixelSize: card.height * 0.36
                }
                Item { Layout.fillWidth: true }
                Glassy.DotGlyph {
                    Layout.preferredWidth: card.height * 0.22
                    Layout.preferredHeight: card.height * 0.3
                    name: "bolt"
                    color: root.charging ? nColors.accent : nColors.divider
                }
            }
            Text {
                Layout.fillWidth: true
                text: root.upper(root.statusText)
                color: root.charging ? nColors.accent : nColors.textSecondary
                font.pixelSize: Math.max(10, card.height * 0.09)
                font.letterSpacing: 1.2
                // Long states ("Plugged in, not charging") shrink before they elide.
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 9
                elide: Text.ElideRight
            }
            Row {
                id: bar
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                readonly property int count: 20
                spacing: (width - count * height) / (count - 1)
                Repeater {
                    model: bar.count
                    Rectangle {
                        required property int index
                        width: bar.height
                        height: width
                        radius: width / 2
                        color: index < Math.round(root.percent / 100 * bar.count) ? (root.percent <= 15 && !root.charging ? nColors.error : nColors.textPrimary) : nColors.divider
                    }
                }
            }
        }
    }
    function upper(text) { return text.toLocaleUpperCase(Qt.locale().name); }
}
