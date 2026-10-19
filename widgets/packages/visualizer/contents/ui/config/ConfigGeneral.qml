// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import "../../../../../shared" as Glassy

KCM.SimpleKCM {
    property int cfg_widgetVariant
    property alias cfg_sensitivity: sensitivity.value
    property alias cfg_themeMode: theme.themeMode
    property alias cfg_useSystemAccent: theme.useSystemAccent
    property alias cfg_monochrome: theme.monochrome

    ColumnLayout {
        spacing: 10
        Glassy.StyleCards {
            Layout.fillWidth: true
            selected: cfg_widgetVariant
            onPicked: value => cfg_widgetVariant = value
            themeMode: theme.themeMode
            useSystemAccent: theme.useSystemAccent
            monochrome: theme.monochrome
            styles: ["circle", "bars", "pill"].map((layout, i) => ({
                label: [i18n("Circle"), i18n("Bars"), i18n("Short pill")][i], value: i,
                source: Qt.resolvedUrl("../everything/EveryVisualizer.qml"),
                props: {layout: layout, levels: Array.from({length: 25}, (_, k) => 0.3 + 0.6 * Math.abs(Math.sin(k * 1.3)))}
            }))
        }
        RowLayout {
            QQC2.Label { text: i18n("Sensitivity:") }
            QQC2.Slider {
                id: sensitivity
                Layout.fillWidth: true
                from: 25
                to: 400
                stepSize: 5
            }
            QQC2.Label { text: Math.round(sensitivity.value) + "%" }
        }
        QQC2.Label {
            Layout.fillWidth: true
            text: i18n("The bands follow how loud the sound output is; raise the sensitivity for quiet sound.")
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: 9
        }
        Glassy.ThemeSettings { id: theme }
    }
}
