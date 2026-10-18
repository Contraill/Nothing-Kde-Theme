// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.ksysguard.sensors as Sensors
import "../../../../shared" as Glassy
import "components"

// CPU and memory as dot rings with temperature and network speed, as
// dotted bars with the disk, or as a pill.
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

    Sensors.Sensor { id: cpu; sensorId: "cpu/all/usage"; updateRateLimit: 2000 }
    Sensors.Sensor { id: memory; sensorId: "memory/physical/usedPercent"; updateRateLimit: 2000 }
    Sensors.Sensor { id: temperature; sensorId: "cpu/all/averageTemperature"; updateRateLimit: 4000 }
    Sensors.Sensor { id: download; sensorId: "network/all/download"; updateRateLimit: 2000 }
    Sensors.Sensor { id: upload; sensorId: "network/all/upload"; updateRateLimit: 2000 }
    Sensors.Sensor { id: disk; sensorId: "disk/all/usedPercent"; updateRateLimit: 30000 }
    Sensors.Sensor { id: diskUsed; sensorId: "disk/all/used"; updateRateLimit: 30000 }
    Sensors.Sensor { id: diskTotal; sensorId: "disk/all/total"; updateRateLimit: 30000 }
    readonly property int variant: Plasmoid.configuration.widgetVariant

    // Bytes per second, short enough for the dot face: 940 B, 12 K, 3.4 M.
    function rate(bytes) {
        const value = Number(bytes) || 0;
        if (value < 1000) return Math.round(value) + " B";
        if (value < 1000 * 1024) return Math.round(value / 1024) + " K";
        return Qt.locale().toString(value / 1048576, "f", 1) + " M";
    }

    component Gauge: Item {
        id: gauge
        property real percent: 0
        property string label: ""
        readonly property real size: Math.min(width, height - caption.height - 6)
        Glassy.DotRing {
            id: ring
            anchors.horizontalCenter: parent.horizontalCenter
            width: gauge.size
            height: gauge.size
            count: 28
            value: gauge.percent / 100
            // Nothing's red signal for a busy machine; the accent when linked to KDE.
            litColor: gauge.percent >= 85 ? nColors.accent : nColors.textPrimary
            dimColor: nColors.divider
        }
        Row {
            anchors.centerIn: ring
            Text {
                id: number
                text: Math.round(gauge.percent)
                font.family: dotFont.name
                font.pixelSize: ring.width * 0.32
                color: nColors.textPrimary
            }
            Text {
                anchors.baseline: number.baseline
                text: "%"
                font.family: dotFont.name
                font.pixelSize: ring.width * 0.14
                color: nColors.textSecondary
            }
        }
        Text {
            id: caption
            anchors.top: ring.bottom
            anchors.topMargin: 6
            anchors.horizontalCenter: parent.horizontalCenter
            text: gauge.label
            font.pixelSize: 11
            font.letterSpacing: 1.5
            color: nColors.textSecondary
        }
    }

    // A labelled row of dots filled to `percent`.
    component Meter: ColumnLayout {
        id: meter
        property string label: ""
        property real percent: 0
        property string detail: ""
        spacing: 4
        RowLayout {
            Layout.fillWidth: true
            Text { text: meter.label; color: nColors.textSecondary; font.pixelSize: 11; font.letterSpacing: 1.5 }
            Item { Layout.fillWidth: true }
            Text { text: meter.detail; color: nColors.textMuted; font.pixelSize: 10 }
            Text { text: Math.round(meter.percent) + "%"; color: meter.percent >= 85 ? nColors.accent : nColors.textPrimary; font.family: dotFont.name; font.pixelSize: 14 }
        }
        Row {
            id: dotsRow
            Layout.fillWidth: true
            Layout.preferredHeight: 5
            readonly property int count: 22
            spacing: (width - count * height) / (count - 1)
            Repeater {
                model: dotsRow.count
                Rectangle {
                    required property int index
                    width: dotsRow.height
                    height: width
                    radius: width / 2
                    color: index < Math.round(meter.percent / 100 * dotsRow.count) ? (meter.percent >= 85 ? nColors.accent : nColors.textPrimary) : nColors.divider
                }
            }
        }
    }

    fullRepresentation: Item {
        Layout.preferredWidth: root.variant === 2 ? 260 : 220
        Layout.preferredHeight: root.variant === 2 ? 96 : 220
        Layout.minimumWidth: root.variant === 2 ? 180 : 170
        Layout.minimumHeight: root.variant === 2 ? 72 : 170

        Glassy.GlassySurface {
            id: card
            anchors.fill: parent
            anchors.margins: 10
            cornerRadius: root.variant === 2 ? height / 2 : 20
            backgroundColor: nColors.background
            foregroundColor: nColors.textPrimary
        }
        ColumnLayout {
            anchors.fill: card
            anchors.margins: 14
            spacing: 10
            visible: root.variant === 0
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12
                Gauge {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    percent: cpu.value || 0
                    label: i18n("CPU")
                }
                Gauge {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    percent: memory.value || 0
                    label: i18n("MEMORY")
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Text {
                    text: temperature.value > 0 ? Math.round(temperature.value) + "°" : "–°"
                    font.family: dotFont.name
                    font.pixelSize: 20
                    color: temperature.value >= 85 ? nColors.accent : nColors.textPrimary
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "↓ " + root.rate(download.value) + "   ↑ " + root.rate(upload.value)
                    font.family: dotFont.name
                    font.pixelSize: 14
                    color: nColors.textSecondary
                }
            }
        }

        // 1: CPU, memory and disk as dotted bars.
        ColumnLayout {
            anchors.fill: card
            anchors.margins: 16
            visible: root.variant === 1
            spacing: 10
            Meter { Layout.fillWidth: true; label: i18n("CPU"); percent: cpu.value || 0 }
            Meter { Layout.fillWidth: true; label: i18n("MEMORY"); percent: memory.value || 0 }
            Meter {
                Layout.fillWidth: true
                label: i18n("DISK")
                percent: disk.value || 0
                detail: diskUsed.formattedValue && diskTotal.formattedValue ? diskUsed.formattedValue.replace(/\u200b/g, "") + " / " + diskTotal.formattedValue.replace(/\u200b/g, "") : ""
            }
            Item { Layout.fillHeight: true }
            Text {
                text: "↓ " + root.rate(download.value) + "   ↑ " + root.rate(upload.value)
                color: nColors.textSecondary
                font.family: dotFont.name
                font.pixelSize: 13
            }
        }

        // 2: a pill, CPU as a ring next to both levels.
        RowLayout {
            anchors.fill: card
            anchors.leftMargin: 12
            anchors.rightMargin: 20
            visible: root.variant === 2
            spacing: 12
            Glassy.DotRing {
                Layout.preferredWidth: card.height - 24
                Layout.preferredHeight: card.height - 24
                count: 20
                value: (cpu.value || 0) / 100
                litColor: nColors.accent
                dimColor: nColors.divider
            }
            Column {
                Layout.fillWidth: true
                Text { text: Math.round(cpu.value || 0) + "% " + i18n("CPU"); color: nColors.textPrimary; font.family: dotFont.name; font.pixelSize: Math.max(13, card.height * 0.2) }
                Text { text: Math.round(memory.value || 0) + "% " + i18n("MEMORY"); color: nColors.textSecondary; font.family: dotFont.name; font.pixelSize: Math.max(11, card.height * 0.14) }
            }
        }
    }
}
