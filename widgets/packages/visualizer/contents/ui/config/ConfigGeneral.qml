// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import "../../../../../shared" as Glassy

KCM.SimpleKCM {
    property alias cfg_widgetVariant: style.currentIndex
    property alias cfg_themeMode: theme.themeMode
    property alias cfg_useSystemAccent: theme.useSystemAccent

    ColumnLayout {
        spacing: 10
        RowLayout {
            QQC2.Label { text: i18n("Style:") }
            QQC2.ComboBox {
                id: style
                model: [i18n("Circle"), i18n("Bars"), i18n("Short pill")]
            }
        }
        Glassy.EveryStyleCards {
            Layout.fillWidth: true
            selected: style.currentIndex
            onPicked: value => style.currentIndex = value
            styles: ["circle", "bars", "pill"].map((layout, i) => ({
                label: [i18n("Circle"), i18n("Bars"), i18n("Short pill")][i], value: i,
                source: Qt.resolvedUrl("../everything/EveryVisualizer.qml"),
                props: {layout: layout, levels: Array.from({length: 25}, (_, k) => 0.3 + 0.6 * Math.abs(Math.sin(k * 1.3)))}
            }))
        }
        QQC2.Label {
            Layout.fillWidth: true
            text: i18n("The bands follow how loud the sound output is.")
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: 9
        }
        Glassy.ThemeSettings { id: theme }
    }
}
