// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import "../../../../../shared" as Glassy

KCM.SimpleKCM {
    id: page
    property int cfg_widgetVariant
    property int cfg_glyphZone
    property alias cfg_sensitivity: sensitivity.value
    property alias cfg_themeMode: theme.themeMode
    property alias cfg_useSystemAccent: theme.useSystemAccent
    property alias cfg_monochrome: theme.monochrome
    property alias cfg_transparent: theme.transparent

    ColumnLayout {
        spacing: 10
        Glassy.StyleCards {
            Layout.fillWidth: true
            selected: page.cfg_widgetVariant
            onPicked: value => page.cfg_widgetVariant = value
            themeMode: theme.themeMode
            useSystemAccent: theme.useSystemAccent
            monochrome: theme.monochrome
            styles: ["ring", "arc", "strip", "line", "dot"].map((shape, i) => ({
                label: [i18n("Ring"), i18n("Arc"), i18n("Strip"), i18n("Line"), i18n("Dot")][i], value: i,
                source: Qt.resolvedUrl("../GlyphLight.qml"), props: {shape: shape, level: 0.62, threshold: 0.25, transparent: theme.transparent}
            }))
        }
        // Which part of the interface this light plays.
        RowLayout {
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
            text: i18n("Glyph widgets hear the same beat: zone 1 flashes on every hit, zone 5 only on the strongest, so several together light further the harder the music hits. Auto numbers them in the order they were added.")
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
                to: 300
                stepSize: 5
            }
            QQC2.Label { text: Math.round(sensitivity.value) + "%" }
        }
        Glassy.ThemeSettings { id: theme; cardOption: true }
    }
}
