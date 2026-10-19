// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import "../../../../../shared" as Glassy

KCM.SimpleKCM {
    property int cfg_pet
    property alias cfg_transparent: theme.transparent
    property alias cfg_themeMode: theme.themeMode
    property alias cfg_useSystemAccent: theme.useSystemAccent
    property alias cfg_monochrome: theme.monochrome

    ColumnLayout {
        spacing: 10
        Glassy.StyleCards {
            Layout.fillWidth: true
            selected: cfg_pet
            onPicked: value => cfg_pet = value
            title: i18n("Pet:")
            themeMode: theme.themeMode
            useSystemAccent: theme.useSystemAccent
            monochrome: theme.monochrome
            styles: ["cat", "dog", "hamster", "robo"].map((name, i) => ({
                label: [i18n("Cat"), i18n("Dog"), i18n("Hamster"), i18n("Robot")][i], value: i,
                source: Qt.resolvedUrl("../everything/EveryPet.qml"), props: {pet: name, transparent: theme.transparent}
            }))
        }
        Glassy.ThemeSettings { id: theme; cardOption: true }
    }
}
