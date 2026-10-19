// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import org.kde.taskmanager as TaskManager
import org.kde.plasma.workspace.dbus as DBus
import "."

// Virtual desktops as dots: the current one a wide accent pill, the ones
// with windows brighter. Click a dot to go there, scroll to step.
Item {
    id: root
    implicitWidth: dots.implicitWidth
    implicitHeight: dots.implicitHeight

    TaskManager.VirtualDesktopInfo { id: desktops }
    TaskManager.TasksModel {
        id: tasks
        groupMode: TaskManager.TasksModel.GroupDisabled
    }
    // Desktop id -> true for every desktop that has a window.
    readonly property var occupied: {
        const used = {};
        for (let i = 0; i < tasks.count; ++i)
            for (const id of tasks.data(tasks.index(i, 0), TaskManager.AbstractTasksModel.VirtualDesktops) ?? [])
                used[id] = true;
        return used;
    }

    // KWin's property is set over D-Bus directly rather than through qdbus6.
    function activate(id) {
        if (!id || Backend.preview) return;
        DBus.SessionBus.asyncCall({service: "org.kde.KWin", path: "/VirtualDesktopManager",
            iface: "org.freedesktop.DBus.Properties", member: "Set", signature: "(ssv)",
            arguments: ["org.kde.KWin.VirtualDesktopManager", "current", new DBus.variant(String(id))]});
    }
    function step(delta) {
        const ids = desktops.desktopIds;
        if (ids.length === 0) return;
        const here = Math.max(0, ids.indexOf(desktops.currentDesktop));
        activate(ids[Math.max(0, Math.min(ids.length - 1, here + delta))]);
    }

    Row {
        id: dots
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        Repeater {
            model: desktops.desktopIds
            Rectangle {
                id: dot
                required property var modelData
                readonly property bool current: desktops.currentDesktop === modelData
                anchors.verticalCenter: parent.verticalCenter
                width: current ? 22 : 8
                height: 8
                radius: 4
                color: current ? Theme.primary : root.occupied[modelData] === true ? Theme.fgDim : Theme.surfaceHigh
                Behavior on width { NumberAnimation { duration: Theme.durMedium; easing.type: Easing.Bezier; easing.bezierCurve: Theme.emphasized } }
                Behavior on color { ColorAnimation { duration: Theme.durShort } }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activate(dot.modelData)
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
