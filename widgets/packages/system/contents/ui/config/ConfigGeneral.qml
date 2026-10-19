// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import "../../../../../shared" as Glassy

KCM.SimpleKCM {
    id: page
    property int cfg_widgetVariant
    property string cfg_ringMetrics
    property string cfg_barMetrics
    property string cfg_pillMetrics
    property string cfg_gaugeMetric
    property alias cfg_themeMode: theme.themeMode
    property alias cfg_useSystemAccent: theme.useSystemAccent
    property alias cfg_monochrome: theme.monochrome
    property alias cfg_transparent: theme.transparent

    readonly property var metricKeys: ["cpu", "gpu", "memory", "disk"]
    readonly property var metricNames: [i18n("CPU"), i18n("GPU"), i18n("Memory"), i18n("Disk")]
    // Rings, bars and the pill show several levels; the gauges one.
    readonly property string listKey: ["cfg_ringMetrics", "cfg_barMetrics", "cfg_pillMetrics"][cfg_widgetVariant] ?? ""
    readonly property bool single: cfg_widgetVariant === 4 || cfg_widgetVariant === 5
    readonly property var shown: listKey ? String(page[listKey]).split(",") : []
    readonly property string gaugeName: metricNames[Math.max(0, metricKeys.indexOf(cfg_gaugeMetric))]

    function toggle(key, on) {
        const now = shown.filter(k => metricKeys.includes(k) && k !== key).concat(on ? [key] : []);
        page[listKey] = metricKeys.filter(k => now.includes(k)).join(",");
    }

    ColumnLayout {
        spacing: 10
        Glassy.StyleCards {
            Layout.fillWidth: true
            selected: cfg_widgetVariant
            onPicked: value => cfg_widgetVariant = value
            themeMode: theme.themeMode
            useSystemAccent: theme.useSystemAccent
            monochrome: theme.monochrome
            styles: [{label: i18n("Rings"), value: 0, image: Qt.resolvedUrl("../previews/style-0-dark.png")}, {label: i18n("Bars"), value: 1, image: Qt.resolvedUrl("../previews/style-1-dark.png")}, {label: i18n("Pill"), value: 2, image: Qt.resolvedUrl("../previews/style-2-dark.png")}].concat(
                ["status", "cpu", "cpu-pill", "network", "network-pill"].map((layout, i) => ({
                    label: [i18n("Status"), page.gaugeName, i18n("%1 pill", page.gaugeName), i18n("Network"), i18n("Network pill")][i], value: 3 + i,
                    source: Qt.resolvedUrl("../everything/EverySystem.qml"),
                    props: {layout: layout, cpu: 23, gaugeLabel: page.gaugeName.toLocaleUpperCase(Qt.locale().name), memory: 61, diskUsed: 509e9, diskTotal: 920e9, battery: 78, download: "472.0 KB", upload: "8.9 KB"}
                })))
        }
        // What the chosen style shows.
        RowLayout {
            visible: page.listKey !== "" || page.single
            spacing: 12
            QQC2.Label { text: i18n("Shows:") }
            Repeater {
                model: page.metricKeys
                QQC2.CheckBox {
                    required property string modelData
                    required property int index
                    visible: page.listKey !== ""
                    text: page.metricNames[index]
                    checked: page.shown.includes(modelData)
                    // At least one level stays.
                    enabled: !checked || page.shown.filter(k => page.metricKeys.includes(k)).length > 1
                    onToggled: {
                        page.toggle(modelData, checked);
                        checked = Qt.binding(() => page.shown.includes(modelData));
                    }
                }
            }
            Repeater {
                model: page.metricKeys
                QQC2.RadioButton {
                    required property string modelData
                    required property int index
                    visible: page.single
                    text: page.metricNames[index]
                    checked: page.cfg_gaugeMetric === modelData
                    onToggled: {
                        page.cfg_gaugeMetric = modelData;
                        checked = Qt.binding(() => page.cfg_gaugeMetric === modelData);
                    }
                }
            }
        }
        QQC2.Label {
            Layout.fillWidth: true
            visible: page.listKey !== "" || page.single
            text: i18n("A sleeping graphics card stays asleep: it is read only while something else has woken it.")
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: 9
        }
        Glassy.ThemeSettings { id: theme; cardOption: true }
    }
}
