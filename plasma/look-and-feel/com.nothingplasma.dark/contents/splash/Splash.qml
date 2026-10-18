// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import org.kde.kirigami as Kirigami

// Startup splash shared by the Nothing light and dark themes (the light
// package points here). A ring of dots: a comet in the KDE accent circles
// continuously, and the ring's dots fill in as Plasma's startup stages pass.
// Colours come from the active scheme and accent.
Rectangle {
    id: root
    color: Kirigami.Theme.backgroundColor

    // Set by ksplashqml: 1 to 6 while the session starts.
    property int stage

    readonly property int count: 24
    readonly property color ink: Kirigami.Theme.textColor
    readonly property color accent: Kirigami.Theme.focusColor
    readonly property real size: Math.min(width, height) * 0.16
    readonly property real dotSize: size * 0.085
    // Honour reduced animations: no spinning, the progress still shows.
    readonly property bool animate: Kirigami.Units.longDuration > 1
    property real head: 0

    NumberAnimation on head {
        running: root.animate
        from: 0
        to: root.count
        duration: 1600
        loops: Animation.Infinite
    }

    Item {
        id: ring
        anchors.centerIn: parent
        width: root.size
        height: root.size
        opacity: 0
        scale: 0.92
        Component.onCompleted: { opacity = 1; scale = 1; }
        Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

        Repeater {
            model: root.count
            Rectangle {
                required property int index
                readonly property real angle: 2 * Math.PI * index / root.count - Math.PI / 2
                readonly property real radiusPx: (ring.width - root.dotSize) / 2
                // Distance behind the comet's head, in dots.
                readonly property real behind: ((root.head - index) % root.count + root.count) % root.count
                readonly property real trail: root.animate ? Math.max(0, 1 - behind / 7) : 0
                readonly property bool filled: index < Math.round(Math.max(0, root.stage - 1) / 5 * root.count)
                width: root.dotSize * (1 + 0.35 * trail)
                height: width
                radius: width / 2
                x: ring.width / 2 + radiusPx * Math.cos(angle) - width / 2
                y: ring.height / 2 + radiusPx * Math.sin(angle) - height / 2
                color: behind < 1 && root.animate ? root.accent
                    : Qt.rgba(root.ink.r, root.ink.g, root.ink.b, Math.max(filled ? 0.55 : 0.14, trail * 0.9))
            }
        }
    }

    // Fade the ring away as the desktop takes over.
    states: State {
        when: root.stage >= 6
        PropertyChanges { ring.opacity: 0; ring.scale: 1.08 }
    }
}
