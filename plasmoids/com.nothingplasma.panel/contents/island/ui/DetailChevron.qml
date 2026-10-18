import QtQuick
import "."

// Visible way into a card's detail panel; right-click on the card works as well.
Text {
    id: chevron
    signal triggered
    text: "chevron_right"
    font.family: Theme.fontIcons
    font.pixelSize: 18
    Accessible.role: Accessible.Button
    Accessible.onPressAction: chevron.triggered()
    MouseArea {
        anchors.fill: parent
        anchors.margins: -8
        cursorShape: Qt.PointingHandCursor
        onClicked: chevron.triggered()
    }
}
