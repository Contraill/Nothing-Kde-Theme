// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.ksysguard.sensors as Sensors
import "../../../../shared" as Glassy
import "components"
import "everything"
import org.kde.plasma.plasma5support as P5Support

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
        monochrome: Plasmoid.configuration.monochrome
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

    // EveryThing-UI's styles (3 to 7) and what they show beyond the sensors above.
    readonly property bool every: variant >= 3
    readonly property string everyLayout: ["status", "cpu", "cpu-pill", "network", "network-pill"][variant - 3] ?? "status"
    readonly property bool everyPill: every && everyLayout.endsWith("pill")
    P5Support.DataSource {
        id: power
        engine: "powermanagement"
        connectedSources: root.every && root.everyLayout === "status" ? ["Battery"] : []
    }
    readonly property var battery: power.data["Battery"] ?? ({})
    // The design's own properties share the sensors' names; read them from here.
    readonly property real cpuNow: cpu.value || 0
    readonly property real memoryNow: memory.value || 0
    readonly property real diskUsedNow: diskUsed.value || 0
    readonly property real diskTotalNow: diskTotal.value || 0
    readonly property real downloadNow: download.value || 0
    readonly property real uploadNow: upload.value || 0
    // One decimal and a unit, as Rainmeter's AutoScale shows it.
    function bytes(value) {
        const v = Number(value) || 0;
        const units = ["B", "KB", "MB", "GB"];
        let i = 0, n = v;
        while (n >= 1024 && i < units.length - 1) { n /= 1024; ++i; }
        return Qt.locale().toString(n, "f", 1) + " " + units[i];
    }

    fullRepresentation: Item {
        Layout.preferredWidth: root.every ? (root.everyLayout === "status" ? 400 : 200) : root.variant === 2 ? 260 : 220
        Layout.preferredHeight: root.everyPill ? 110 : root.every ? 200 : root.variant === 2 ? 96 : 220
        Layout.minimumWidth: root.variant === 2 || root.everyPill ? 180 : 170
        Layout.minimumHeight: root.variant === 2 || root.everyPill ? 72 : 170

        EverySystem {
            anchors.fill: parent
            visible: root.every
            colors: nColors
            family: dotFont.name
            layout: root.everyLayout
            cpu: root.cpuNow
            memory: root.memoryNow
            diskUsed: root.diskUsedNow
            diskTotal: root.diskTotalNow
            battery: root.battery["Has Battery"] ? root.battery["Percent"] ?? -1 : -1
            charging: root.battery["State"] === "Charging"
            download: root.bytes(root.downloadNow)
            upload: root.bytes(root.uploadNow)
        }

        Glassy.GlassySurface {
            id: card
            visible: !root.every
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
            Glassy.DotMeter { colors: nColors; Layout.fillWidth: true; label: i18n("CPU"); percent: cpu.value || 0 }
            Glassy.DotMeter { colors: nColors; Layout.fillWidth: true; label: i18n("MEMORY"); percent: memory.value || 0 }
            Glassy.DotMeter {
                colors: nColors
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
                litColor: (cpu.value || 0) >= 85 ? nColors.accent : nColors.textPrimary
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
