import QtQuick
import "."

Item {
    id: root
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    signal configureRequested()
    Accessible.role: Accessible.Button
    Accessible.onPressAction: configureRequested()
    Accessible.name: Weather.detail

    Row {
    id: content
    spacing: 5
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Weather.icon
        color: Theme.tertiary
        font.family: Theme.fontIcons
        font.pixelSize: 18
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Weather.temp
        color: Theme.fgVariant
        font.family: Theme.font
        font.pixelSize: Theme.labelMedium
    }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.configureRequested()
    }
}
