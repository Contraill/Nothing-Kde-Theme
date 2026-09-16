import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "components"

PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    property date today: new Date()
    NothingColors {
        id: nColors
        themeMode: Plasmoid.configuration.themeMode
        useSystemAccent: Plasmoid.configuration.useSystemAccent
    }
    FontLoader { id: serifFont; source: Qt.resolvedUrl("../fonts/serif.otf") }
    FontLoader { id: serifLightFont; source: Qt.resolvedUrl("../fonts/serif-light.otf") }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: root.today = new Date() }
    fullRepresentation: DatePages {
        Layout.preferredWidth: 200; Layout.preferredHeight: 200
        Layout.minimumWidth: 200; Layout.minimumHeight: 200
        colors: nColors; today: root.today
        numberFont: serifFont.status === FontLoader.Ready ? serifFont.name : "serif"
        labelFont: serifLightFont.status === FontLoader.Ready ? serifLightFont.name : "sans-serif"
    }
}
