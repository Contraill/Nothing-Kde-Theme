import QtQuick
import "."

MouseArea {
    id: root

    readonly property int percent: Audio.percent
    readonly property bool muted: Audio.muted

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton

    onClicked: Audio.toggleMute()
    onWheel: wheel => Audio.step(wheel.angleDelta.y > 0 ? 0.05 : -0.05)

    Row {
        id: row
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.muted || root.percent === 0 ? Icons.volMute : root.percent > 50 ? Icons.volHigh : Icons.volLow
            color: root.muted ? Theme.outline : root.percent > 100 ? Theme.alert : Theme.fg
            font.family: Theme.fontIcons
            font.pixelSize: 18
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.percent
            color: Theme.fgVariant
            font.family: Theme.font
            font.pixelSize: Theme.labelMedium
        }
    }
}
