// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick

// One line of text that, when it does not fit, pauses, scrolls to its end,
// pauses and returns; any change of text, size or font starts over.
Item {
    id: marquee
    property alias text: label.text
    property alias color: label.color
    property alias fontFamily: label.font.family
    property real fontSize: 14
    property int pause: 1600
    property real speed: 0.035 // pixels per millisecond
    readonly property alias label: label
    readonly property bool overflowing: label.implicitWidth > width + 0.5
    clip: true
    implicitHeight: label.implicitHeight

    Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: marquee.fontSize
        onImplicitWidthChanged: Qt.callLater(marquee.restart)
    }
    function restart() {
        scroll.stop();
        label.x = 0;
        if (overflowing && visible) scroll.start();
    }
    // After bindings settle, so `overflowing` already reflects the change.
    onWidthChanged: Qt.callLater(restart)
    onVisibleChanged: Qt.callLater(restart)
    onOverflowingChanged: Qt.callLater(restart)
    SequentialAnimation {
        id: scroll
        loops: Animation.Infinite
        PauseAnimation { duration: marquee.pause }
        NumberAnimation {
            target: label
            property: "x"
            to: marquee.width - label.implicitWidth
            duration: Math.max(1, (label.implicitWidth - marquee.width) / marquee.speed)
        }
        PauseAnimation { duration: marquee.pause }
        NumberAnimation { target: label; property: "x"; to: 0; duration: 350; easing.type: Easing.InOutQuad }
    }
}
