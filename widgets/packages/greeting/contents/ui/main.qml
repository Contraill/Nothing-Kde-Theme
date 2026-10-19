// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "../../../../shared" as Glassy
import "components"
import "everything"

// Good morning, afternoon or evening with the time (EveryThing-UI's greeting).
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

    readonly property bool square: Plasmoid.configuration.widgetVariant === 1
    property date now: new Date()
    // KDE's region settings decide: a 12-hour format has AM/PM in it.
    readonly property bool clock24: !/a/i.test(Qt.locale().timeFormat(Locale.ShortFormat).replace(/'[^']*'/g, ""))
    Timer {
        running: true
        repeat: true
        interval: 60000 - root.now.getSeconds() * 1000
        onTriggered: root.now = new Date()
    }

    fullRepresentation: EveryGreeting {
        Layout.preferredWidth: root.square ? 200 : 400
        Layout.preferredHeight: root.square ? 200 : 115
        Layout.minimumWidth: root.square ? 150 : 240
        Layout.minimumHeight: root.square ? 150 : 60
        colors: nColors
        family: dotFont.name
        square: root.square
        now: root.now
        clock24: root.clock24
        showTime: Plasmoid.configuration.showTime
        transparent: Plasmoid.configuration.transparent
    }
}
