// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.ksysguard.sensors as Sensors
import "../../../../shared" as Glassy
import "components"

// CPU and memory as dot rings; temperature and network speed below.
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

    fullRepresentation: Item {
        Layout.preferredWidth: 220
        Layout.preferredHeight: 220
        Layout.minimumWidth: 170
        Layout.minimumHeight: 170

        Glassy.GlassySurface {
            id: card
            anchors.fill: parent
            anchors.margins: 10
            backgroundColor: nColors.background
            foregroundColor: nColors.textPrimary
        }
        ColumnLayout {
            anchors.fill: card
            anchors.margins: 14
            spacing: 10
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
    }
}
