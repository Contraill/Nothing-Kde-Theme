import QtQuick
import org.kde.kirigami as Kirigami

// A row of dots fills in as Plasma starts; the newest one carries the accent.
// Colors come from the active scheme, so the light and dark packages share it.
Rectangle {
    id: root
    color: Kirigami.Theme.backgroundColor

    // Set by ksplashqml: 1 to 6 while the session starts.
    property int stage

    Row {
        anchors.centerIn: parent
        spacing: 14
        opacity: root.stage > 1 ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Kirigami.Units.veryLongDuration * 2; easing.type: Easing.InOutQuad }
        }

        Repeater {
            model: 6
            Rectangle {
                required property int index
                readonly property bool lit: index < root.stage
                width: 12
                height: 12
                radius: 6
                color: index === root.stage - 1 ? Kirigami.Theme.focusColor
                    : Qt.alpha(Kirigami.Theme.textColor, lit ? 0.9 : 0.16)
                Behavior on color {
                    ColorAnimation { duration: Kirigami.Units.longDuration }
                }
            }
        }
    }
}
