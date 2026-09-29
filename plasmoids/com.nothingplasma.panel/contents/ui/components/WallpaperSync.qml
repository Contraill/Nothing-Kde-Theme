import QtQuick

// Startup and hotplug can precede Plasma's desktop creation. Retry a bounded
// burst after topology/activity changes; do not poll or create a daemon.
QtObject {
    id: root
    property bool enabled: true
    property string mode: "dark"
    property var screens: Application.screens
    property string activity: ""
    property int remaining: 0
    property int delay: 500
    signal synchronize(string mode)
    function schedule() {
        retry.stop();
        remaining = enabled ? 4 : 0;
        delay = 500;
        if (remaining) retry.start();
    }
    onEnabledChanged: schedule()
    onModeChanged: schedule()
    onScreensChanged: schedule()
    onActivityChanged: schedule()
    Component.onCompleted: schedule()
    readonly property Timer retry: Timer {
        interval: root.delay
        onTriggered: {
            if (!root.enabled) return;
            root.synchronize(root.mode);
            --root.remaining;
            root.delay *= 2;
            if (root.remaining) restart();
        }
    }
}
