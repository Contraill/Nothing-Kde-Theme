// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "../../../../shared" as Glassy
import "components"

// The KDE Connect phone and its battery; a click opens it in KDE Connect.
// KDE Connect is optional, so its view is loaded on demand and a missing
// module shows a hint instead.
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

    fullRepresentation: Item {
        Layout.preferredWidth: 220
        Layout.preferredHeight: 220
        Layout.minimumWidth: 170
        Layout.minimumHeight: 170

        Glassy.GlassySurface {
            id: card
            anchors.fill: parent
            anchors.margins: 10
            backgroundColor: nColors.background
            foregroundColor: nColors.textPrimary
        }
        Loader {
            id: view
            anchors.fill: card
            anchors.margins: 14
            source: "PhoneView.qml"
            onLoaded: { item.colors = nColors; item.dotFamily = Qt.binding(() => dotFont.name); }
        }
        Text {
            anchors.fill: card
            anchors.margins: 18
            visible: view.status === Loader.Error
            text: i18n("Install KDE Connect to see your phone here.")
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: nColors.textSecondary
        }
    }
}
