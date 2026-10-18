import QtQuick
import "."

// Level bar shared by the sound card, the sound panel and the microphone row.
Rectangle {
    id: root

    property real value: 0          // 1.0 is 100 %
    property real maxValue: 1
    property bool muted: false
    property string accessibleName: ""
    signal moved(real value)

    // PulseAudio echoes each write asynchronously; show the pointer while dragging.
    readonly property real shown: drag.pressed ? drag.value : value

    height: 6
    radius: 3
    color: Theme.surfaceHigh
    Accessible.role: Accessible.Slider
    Accessible.name: root.accessibleName
    Accessible.description: Math.round(root.shown * 100) + "%"

    Rectangle {
        width: root.width * Math.min(root.shown, 1) / root.maxValue
        height: parent.height
        radius: parent.radius
        color: root.muted ? Theme.outline : Theme.fg
    }
    Rectangle {
        x: root.width / root.maxValue
        width: root.width * Math.max(root.shown - 1, 0) / root.maxValue
        height: parent.height
        radius: parent.radius
        color: root.muted ? Theme.outline : Theme.alert
    }

    MouseArea {
        id: drag
        property real value: 0
        anchors.fill: parent
        anchors.margins: -8
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton

        function apply(mx) {
            value = Math.max(0, Math.min(root.maxValue, (mx + anchors.margins) / root.width * root.maxValue));
            root.moved(value);
        }
        onPressed: mouse => apply(mouse.x)
        onPositionChanged: mouse => { if (pressed) apply(mouse.x); }
    }
}
