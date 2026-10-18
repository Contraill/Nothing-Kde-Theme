import QtQuick
import "."
Row {
    id: root
    spacing: 8

    property bool showDate: false

    Timer {
        id: clock
        property date now: new Date()
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: now = new Date()
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        // Qt rounds the dot face's ascent and descent up separately; at 17 px
        // that leaves the digits a pixel above the island's middle.
        anchors.verticalCenterOffset: 1
        text: Qt.formatDateTime(clock.now, Cfg.timeFormat)
        color: Theme.fg
        font.family: Theme.fontDots
        font.pixelSize: 17
        font.weight: Font.Bold
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.showDate
        text: Cfg.locale.toString(clock.now, "ddd d MMM").toLocaleUpperCase(Cfg.locale.name)
        color: Theme.fgDim
        font.family: Theme.font
        font.pixelSize: Theme.labelSmall
        font.letterSpacing: Theme.labelSpacing
    }
}
