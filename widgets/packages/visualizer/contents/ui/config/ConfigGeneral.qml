// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import "../../../../../shared" as Glassy

KCM.SimpleKCM {
    id: page
    property int cfg_widgetVariant
    property alias cfg_sensitivity: sensitivity.value
    property alias cfg_transparent: theme.transparent
    property int cfg_glyphZone
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
                props: {layout: layout, transparent: theme.transparent, levels: Array.from({length: 25}, (_, k) => 0.3 + 0.6 * Math.abs(Math.sin(k * 1.3)))}
            })).concat(["ring", "arc", "strip", "line", "dot"].map((shape, i) => ({
                label: [i18n("Glyph ring"), i18n("Glyph arc"), i18n("Glyph strip"), i18n("Glyph line"), i18n("Glyph dot")][i], value: 3 + i,
                source: Qt.resolvedUrl("../GlyphLight.qml"),
                props: {shape: shape, transparent: theme.transparent, light: n => [0.9, 0.35, 0.7, 0.15][n % 4]}
            })))
        }
        // The glyph lights: which part of the interface this widget plays.
        RowLayout {
            visible: page.cfg_widgetVariant >= 3
            spacing: 10
            QQC2.Label { text: i18n("Zone:") }
            Repeater {
                model: 6
                QQC2.RadioButton {
                    required property int index
                    text: index === 0 ? i18n("Auto") : String(index)
                    checked: page.cfg_glyphZone === index
                    onToggled: {
                        page.cfg_glyphZone = index;
                        checked = Qt.binding(() => page.cfg_glyphZone === index);
                    }
                }
            }
        }
        QQC2.Label {
            Layout.fillWidth: true
            visible: page.cfg_widgetVariant >= 3
            text: i18n("Glyph widgets share one clock: put several side by side, each in its own zone, and they play together, every zone with its part of the sound. Auto takes the zone from where the widget sits across the screen.")
            wrapMode: Text.Wrap
            opacity: 0.7
            font.pointSize: 9
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
        Glassy.ThemeSettings { id: theme; cardOption: true }
    }
}
