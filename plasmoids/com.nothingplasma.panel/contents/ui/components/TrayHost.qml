import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid

// Keep KDE's real tray, including DBus menus, hidden items and persisted config.
// Visibility never removes the applet, so settings can always restore an item.
Item {
    id: root
    required property var containment
    required property ContainmentItem containmentItem
    property var trayApplet: null
    property Item trayItem: null
    readonly property real iconScale: 0.82
    implicitWidth: trayItem ? Math.ceil(Math.max(0, trayItem.Layout.minimumWidth, trayItem.implicitWidth) * iconScale) : 0
    implicitHeight: 28 * iconScale

    // Scale the native surface together with its geometry and hit targets;
    // leave KDE's persisted icon preferences and popup implementation intact.
    Item {
        id: nativeSurface
        anchors.centerIn: parent
        width: root.width / root.iconScale
        height: root.height / root.iconScale
        scale: root.iconScale
    }

    function ensureTray() {
        if (containmentItem.loading) return;
        let found = null;
        for (const applet of containment.applets) {
            if (applet.metaData.pluginId === "org.kde.plasma.systemtray") { found = applet; break; }
        }
        if (!found) return;
        trayApplet = found;
        trayItem = containmentItem.itemFor(found);
        if (!trayItem) return;
        trayItem.parent = nativeSurface;
        trayItem.anchors.fill = nativeSurface;
        trayItem.visible = true;
    }
    function configure() {
        if (trayApplet) trayApplet.internalAction("configure").trigger();
    }
    Component.onCompleted: Qt.callLater(ensureTray)
    Connections {
        target: root.containmentItem
        function onIsLoadingChanged() { Qt.callLater(root.ensureTray); }
    }
    Connections {
        target: root.containment
        function onAppletAdded() { Qt.callLater(root.ensureTray); }
    }
}
