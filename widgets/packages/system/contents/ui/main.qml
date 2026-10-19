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

// The chosen levels (CPU, GPU, memory, disk) as dot rings with temperatures
// and network speed, as dotted bars, or as a pill; or one of the adapted
// designs. The rings, dots and icons take the accent; the numbers stay ink.
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
    // What the current style shows, in a fixed order.
    function metricList(text) {
        const chosen = String(text || "").split(",");
        const list = ["cpu", "gpu", "memory", "disk"].filter(k => chosen.includes(k));
        return list.length ? list : ["cpu"];
    }
    readonly property var metrics: variant === 0 ? metricList(Plasmoid.configuration.ringMetrics)
        : variant === 1 ? metricList(Plasmoid.configuration.barMetrics)
        : variant === 2 ? metricList(Plasmoid.configuration.pillMetrics)
        : variant === 4 || variant === 5 ? metricList(Plasmoid.configuration.gaugeMetric) : []
    // Polling an NVIDIA card can keep it awake: its sensors run only while shown.
    readonly property bool showsGpu: metrics.includes("gpu")

    Sensors.Sensor { id: cpu; sensorId: "cpu/all/usage"; updateRateLimit: 2000 }
    Sensors.Sensor { id: memory; sensorId: "memory/physical/usedPercent"; updateRateLimit: 2000 }
    Sensors.Sensor { id: temperature; sensorId: "cpu/all/averageTemperature"; updateRateLimit: 4000 }
    Sensors.Sensor { id: gpu; sensorId: root.showsGpu ? "gpu/all/usage" : ""; updateRateLimit: 2000 }
    // No "all" temperature: the hottest of the first three GPUs.
    Sensors.Sensor { id: gpuTemp0; sensorId: root.showsGpu ? "gpu/gpu0/temperature" : ""; updateRateLimit: 4000 }
    Sensors.Sensor { id: gpuTemp1; sensorId: root.showsGpu ? "gpu/gpu1/temperature" : ""; updateRateLimit: 4000 }
    Sensors.Sensor { id: gpuTemp2; sensorId: root.showsGpu ? "gpu/gpu2/temperature" : ""; updateRateLimit: 4000 }
    Sensors.Sensor { id: download; sensorId: "network/all/download"; updateRateLimit: 2000 }
    Sensors.Sensor { id: upload; sensorId: "network/all/upload"; updateRateLimit: 2000 }
    Sensors.Sensor { id: disk; sensorId: "disk/all/usedPercent"; updateRateLimit: 30000 }
    Sensors.Sensor { id: diskUsed; sensorId: "disk/all/used"; updateRateLimit: 30000 }
    Sensors.Sensor { id: diskTotal; sensorId: "disk/all/total"; updateRateLimit: 30000 }

    readonly property real gpuTemperature: Math.max(Number(gpuTemp0.value) || 0, Number(gpuTemp1.value) || 0, Number(gpuTemp2.value) || 0)
    function percent(key) {
        return Number(key === "cpu" ? cpu.value : key === "gpu" ? gpu.value : key === "memory" ? memory.value : disk.value) || 0;
    }
    function caption(key) {
        return key === "cpu" ? i18n("CPU") : key === "gpu" ? i18n("GPU") : key === "memory" ? i18n("MEMORY") : i18n("DISK");
    }
    function degrees(key) {
        const value = key === "cpu" ? Number(temperature.value) || 0 : key === "gpu" ? root.gpuTemperature : 0;
        return value > 0 ? Math.round(value) + "°" : "–°";
    }
    readonly property string diskDetail: diskUsed.formattedValue && diskTotal.formattedValue
        ? diskUsed.formattedValue.replace(/​/g, "") + " / " + diskTotal.formattedValue.replace(/​/g, "") : ""

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
            litColor: gauge.percent >= 85 ? nColors.error : nColors.accent
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
    // ↓ 12 K  ↑ 3 K: the arrows in the accent.
    component Speeds: Row {
        property real size: 14
        spacing: 4
        Text { text: "↓"; color: nColors.accent; font.family: dotFont.name; font.pixelSize: parent.size }
        Text { text: root.rate(download.value); color: nColors.textSecondary; font.family: dotFont.name; font.pixelSize: parent.size }
        Item { width: 8; height: 1 }
        Text { text: "↑"; color: nColors.accent; font.family: dotFont.name; font.pixelSize: parent.size }
        Text { text: root.rate(upload.value); color: nColors.textSecondary; font.family: dotFont.name; font.pixelSize: parent.size }
    }

    // The adapted designs (3 to 7) and what they show beyond the sensors above.
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
    readonly property real gaugeNow: metrics.length ? percent(metrics[0]) : 0
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

    // Rings in a row, four as a square.
    readonly property int ringColumns: metrics.length === 4 ? 2 : Math.max(1, metrics.length)
    fullRepresentation: Item {
        Layout.preferredWidth: root.every ? (root.everyLayout === "status" ? 400 : 200)
            : root.variant === 2 ? 260 : root.variant === 0 && root.metrics.length >= 3 ? 320 : 220
        Layout.preferredHeight: root.everyPill ? 110 : root.every ? 200 : root.variant === 2 ? 96
            : root.variant === 0 && root.metrics.length === 4 ? 320 : root.variant === 1 ? 90 + 40 * root.metrics.length : 220
        Layout.minimumWidth: root.variant === 2 || root.everyPill ? 180 : 170
        Layout.minimumHeight: root.variant === 2 || root.everyPill ? 72 : 170

        EverySystem {
            anchors.fill: parent
            visible: root.every
            colors: nColors
            family: dotFont.name
            layout: root.everyLayout
            cpu: root.gaugeNow
            gaugeLabel: root.metrics.length ? root.caption(root.metrics[0]) : "CPU"
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
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: root.ringColumns
                columnSpacing: 12
                rowSpacing: 8
                Repeater {
                    model: root.variant === 0 ? root.metrics : []
                    Gauge {
                        required property string modelData
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        percent: root.percent(modelData)
                        label: root.caption(modelData)
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                // A thermometer per processor shown, named when there are two.
                Repeater {
                    model: root.metrics.filter(k => k === "cpu" || k === "gpu")
                    Row {
                        id: reading
                        required property string modelData
                        spacing: 4
                        Glassy.DotGlyph {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 12
                            height: 16
                            name: "thermometer"
                            color: nColors.accent
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.degrees(reading.modelData)
                            font.family: dotFont.name
                            font.pixelSize: 18
                            color: nColors.textPrimary
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root.metrics.includes("cpu") && root.metrics.includes("gpu")
                            text: root.caption(reading.modelData)
                            font.pixelSize: 9
                            font.letterSpacing: 1.2
                            color: nColors.textMuted
                        }
                    }
                }
                Item { Layout.fillWidth: true }
                Speeds { size: 14 }
            }
        }

        // 1: the chosen levels as dotted bars; processors note their temperature.
        ColumnLayout {
            anchors.fill: card
            anchors.margins: 16
            visible: root.variant === 1
            spacing: 10
            Repeater {
                model: root.variant === 1 ? root.metrics : []
                Glassy.DotMeter {
                    required property string modelData
                    colors: nColors
                    Layout.fillWidth: true
                    label: root.caption(modelData)
                    percent: root.percent(modelData)
                    detail: modelData === "disk" ? root.diskDetail : modelData === "memory" ? "" : root.degrees(modelData)
                }
            }
            Item { Layout.fillHeight: true }
            Speeds { size: 13 }
        }

        // 2: a pill, the first level as a ring next to the first two.
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
                value: root.percent(root.metrics[0] ?? "cpu") / 100
                litColor: value >= 0.85 ? nColors.error : nColors.accent
                dimColor: nColors.divider
            }
            Column {
                Layout.fillWidth: true
                Repeater {
                    model: root.variant === 2 ? root.metrics.slice(0, 2) : []
                    Text {
                        required property string modelData
                        required property int index
                        text: Math.round(root.percent(modelData)) + "% " + root.caption(modelData)
                        color: index === 0 ? nColors.textPrimary : nColors.textSecondary
                        font.family: dotFont.name
                        font.pixelSize: index === 0 ? Math.max(13, card.height * 0.2) : Math.max(11, card.height * 0.14)
                    }
                }
            }
        }
    }
}
