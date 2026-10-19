import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "components"
import "everything"
import "../../../../shared" as Glassy

PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    property date today: new Date()
    NothingColors {
        id: nColors
        themeMode: Plasmoid.configuration.themeMode
        useSystemAccent: Plasmoid.configuration.useSystemAccent
        monochrome: Plasmoid.configuration.monochrome
    }
    FontLoader { id: serifFont; source: Qt.resolvedUrl("../fonts/serif.otf") }
    FontLoader { id: serifLightFont; source: Qt.resolvedUrl("../fonts/serif-light.otf") }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: root.today = new Date() }
    // 2 and 3, the month of dots and of numbers, are now the pages' calendar.
    readonly property int variant: Plasmoid.configuration.widgetVariant === 1 ? 1 : 0
    readonly property int monthStyle: Plasmoid.configuration.widgetVariant >= 2 ? Plasmoid.configuration.widgetVariant - 1 : Plasmoid.configuration.monthStyle
    Glassy.DotFont { id: dotFont }
    fullRepresentation: Loader {
        Layout.preferredWidth: 200; Layout.preferredHeight: root.variant === 1 ? 110 : 200
        Layout.minimumWidth: root.variant === 1 ? 150 : 200; Layout.minimumHeight: root.variant === 1 ? 80 : 200
        sourceComponent: root.variant > 0 ? everyComponent : pagesComponent
        // The pages turn over on a click; the renderer's calendar check asks for it too.
        function togglePage() { item?.togglePage?.() }
    }
    Component {
        id: pagesComponent
        DatePages {
            colors: nColors; today: root.today
            monthStyle: root.monthStyle
            dotFamily: dotFont.name
            numberFont: serifFont.status === FontLoader.Ready ? serifFont.name : "serif"
            labelFont: serifLightFont.status === FontLoader.Ready ? serifLightFont.name : "sans-serif"
        }
    }
    Component {
        id: everyComponent
        EveryDate {
            colors: nColors
            family: dotFont.name
            now: root.today
            layout: "pill"
        }
    }
}
