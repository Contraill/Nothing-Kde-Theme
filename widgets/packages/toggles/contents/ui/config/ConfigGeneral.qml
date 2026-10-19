// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import "../../../../../shared" as Glassy

KCM.SimpleKCM {
    id: page
    property int cfg_widgetVariant
    property string cfg_tileToggles
    property string cfg_singleToggle
    property alias cfg_themeMode: theme.themeMode
    property alias cfg_useSystemAccent: theme.useSystemAccent
    property alias cfg_monochrome: theme.monochrome
    property alias cfg_transparent: theme.transparent

    readonly property var keys: ["wifi", "bluetooth", "airplane", "sound", "microphone", "dnd", "nightlight", "coffee", "power", "hotspot"]
    readonly property var names: [i18n("Wi-Fi"), i18n("Bluetooth"), i18n("Airplane"), i18n("Sound"), i18n("Microphone"), i18n("Do not disturb"),
        i18n("Night light"), i18n("Coffee"), i18n("Power profile"), i18n("Hotspot")]
    readonly property var glyphs: ["wifi", "bluetooth", "airplane", "volume", "mic", "moon", "nightlight", "coffee", "bolt", "hotspot"]
    readonly property var tiles: String(cfg_tileToggles).split(",")
    readonly property bool single: cfg_widgetVariant === 2 || cfg_widgetVariant === 3
    readonly property int singleIndex: Math.max(0, keys.indexOf(cfg_singleToggle))

    // 4 to 7 were Bluetooth and airplane mode as a pill and a circle.
    Component.onCompleted: if (cfg_widgetVariant >= 4 && cfg_widgetVariant <= 7) {
        cfg_singleToggle = ["bluetooth", "airplane"][Math.floor((cfg_widgetVariant - 4) / 2)];
        cfg_widgetVariant = cfg_widgetVariant % 2 === 1 ? 3 : 2;
    }
    function toggleTile(key, on) {
        const now = tiles.filter(k => k !== key).concat(on ? [key] : []);
        cfg_tileToggles = keys.concat(["volume"]).filter(k => now.includes(k)).join(",");
    }

    ColumnLayout {
        spacing: 10
        Glassy.StyleCards {
            Layout.fillWidth: true
            selected: page.cfg_widgetVariant
            onPicked: value => page.cfg_widgetVariant = value
            themeMode: theme.themeMode
            useSystemAccent: theme.useSystemAccent
            monochrome: theme.monochrome
            // The pill and circle show the toggle picked below.
            readonly property var pick: ({kind: page.keys[page.singleIndex], on: true, volume: 0.4,
                glyph: page.singleIndex < 3 ? "" : page.glyphs[page.singleIndex],
                label: page.singleIndex < 3 ? "" : page.names[page.singleIndex].toLocaleUpperCase(Qt.locale().name)})
            styles: [
                {label: i18n("Toggles"), value: 0, image: Qt.resolvedUrl("../previews/style-0-dark.png")},
                {label: i18n("Volume dots"), value: 1, image: Qt.resolvedUrl("../previews/style-1-dark.png")},
                {label: i18n("%1 pill", page.names[page.singleIndex]), value: 2, source: Qt.resolvedUrl("../everything/EveryToggle.qml"), props: Object.assign({round: false}, pick)},
                {label: i18n("%1 circle", page.names[page.singleIndex]), value: 3, source: Qt.resolvedUrl("../everything/EveryToggle.qml"), props: Object.assign({round: true}, pick)},
                {label: i18n("Volume ring"), value: 8, source: Qt.resolvedUrl("../everything/EveryToggle.qml"), props: {kind: "volume", round: false, volume: 0.4}},
                {label: i18n("Volume pill"), value: 9, source: Qt.resolvedUrl("../everything/EveryToggle.qml"), props: {kind: "volume", round: true, volume: 0.4}}
            ]
        }
        // What the chosen style shows.
        QQC2.Label {
            visible: page.cfg_widgetVariant === 0 || page.single
            text: page.single ? i18n("Toggle:") : i18n("Shows:")
            font.weight: Font.Medium
        }
        GridLayout {
            visible: page.cfg_widgetVariant === 0 || page.single
            columns: 2
            columnSpacing: 16
            Repeater {
                model: page.keys
                Item {
                    id: choice
                    required property string modelData
                    required property int index
                    implicitWidth: box.visible ? box.implicitWidth : radio.implicitWidth
                    implicitHeight: box.implicitHeight
                    QQC2.CheckBox {
                        id: box
                        visible: !page.single
                        text: page.names[choice.index]
                        checked: page.tiles.includes(choice.modelData)
                        onToggled: {
                            page.toggleTile(choice.modelData, checked);
                            checked = Qt.binding(() => page.tiles.includes(choice.modelData));
                        }
                    }
                    QQC2.RadioButton {
                        id: radio
                        visible: page.single
                        text: page.names[choice.index]
                        checked: page.singleIndex === choice.index
                        onToggled: {
                            page.cfg_singleToggle = choice.modelData;
                            checked = Qt.binding(() => page.singleIndex === choice.index);
                        }
                    }
                }
            }
            QQC2.CheckBox {
                visible: !page.single
                text: i18n("Volume bar")
                checked: page.tiles.includes("volume")
                onToggled: {
                    page.toggleTile("volume", checked);
                    checked = Qt.binding(() => page.tiles.includes("volume"));
                }
            }
        }
        Glassy.ThemeSettings { id: theme; cardOption: true }
    }
}
