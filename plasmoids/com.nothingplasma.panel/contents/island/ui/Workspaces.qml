import QtQuick
import org.kde.taskmanager as TaskManager
import org.kde.plasma.workspace.dbus as DBus
import "."
Item {
    id: root

    implicitWidth: dots.implicitWidth
    implicitHeight: dots.implicitHeight

    function activate(id) {
        if (!id)
            return;
        if (Backend.preview) return;
        // Set KWin's property over D-Bus directly instead of spawning qdbus6.
        DBus.SessionBus.asyncCall({service: "org.kde.KWin", path: "/VirtualDesktopManager",
            iface: "org.freedesktop.DBus.Properties", member: "Set", signature: "(ssv)",
            arguments: ["org.kde.KWin.VirtualDesktopManager", "current", new DBus.variant(String(id))]});
    }

    function step(delta) {
        const ids = desktops.desktopIds;
        if (ids.length === 0)
            return;
        let idx = ids.indexOf(desktops.currentDesktop);
        if (idx === -1)
            idx = 0;
        idx = Math.max(0, Math.min(ids.length - 1, idx + delta));
        root.activate(ids[idx]);
    }

    TaskManager.VirtualDesktopInfo {
        id: desktops
    }
    TaskManager.TasksModel {
        id: tasks
        groupMode: TaskManager.TasksModel.GroupDisabled
    }

    readonly property var occupied: {
        const set = {};
        for (var i = 0; i < tasks.count; i++) {
            const vd = tasks.data(tasks.index(i, 0), TaskManager.AbstractTasksModel.VirtualDesktops);
            if (!vd)
                continue;
            for (var j = 0; j < vd.length; j++)
                set[vd[j]] = true;
        }
        return set;
    }

    Row {
        id: dots
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Repeater {
            model: desktops.desktopIds

            Rectangle {
                required property int index
                required property var modelData

                readonly property bool focused: desktops.currentDesktop === modelData
                readonly property bool occupied: root.occupied[modelData] === true

                width: focused ? 22 : 8
                height: 8
                radius: height / 2
                anchors.verticalCenter: parent.verticalCenter
                color: focused ? Theme.primary : occupied ? Theme.fgDim : Theme.surfaceHigh

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.durMedium
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Theme.emphasized
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durShort
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activate(parent.modelData)
                }
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        acceptedButtons: Qt.NoButton
        onWheel: wheel => root.step(wheel.angleDelta.y > 0 ? -1 : 1)
    }
}
