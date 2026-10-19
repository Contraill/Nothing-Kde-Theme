// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "components"
import "everything"

// A dot-matrix pet peeking over the edge (EveryThing-UI's pets). It rests
// while the desktop is covered, so it costs nothing out of sight.
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

    fullRepresentation: EveryPet {
        Layout.preferredWidth: 200
        Layout.preferredHeight: 200
        Layout.minimumWidth: 120
        Layout.minimumHeight: 120
        colors: nColors
        pet: ["cat", "dog", "hamster", "robo"][Plasmoid.configuration.pet] ?? "cat"
        transparent: Plasmoid.configuration.transparent
        running: visible
    }
}
