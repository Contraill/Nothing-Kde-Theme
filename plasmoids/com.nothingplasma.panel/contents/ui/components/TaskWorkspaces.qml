import QtQuick
import org.kde.taskmanager as TaskManager

QtObject {
    id: root
    property var tasksModel
    property int row: -1
    property bool grouped: false
    property int childCount: 1
    property var desktopInfo
    property int revision: 0
    readonly property var otherNames: {
        const update = revision;
        const info = desktopInfo;
        if (!tasksModel || row < 0 || !info) return [];
        const ids = info.desktopIds || [];
        const names = info.desktopNames || [];
        const current = String(info.currentDesktop);
        let found = [];
        for (let child = 0; child < (grouped ? childCount : 1); ++child) {
            const index = grouped ? tasksModel.makeModelIndex(row, child) : tasksModel.makeModelIndex(row);
            if (!index || !tasksModel.data(index, TaskManager.AbstractTasksModel.IsWindow)
                || tasksModel.data(index, TaskManager.AbstractTasksModel.IsOnAllVirtualDesktops)) continue;
            const desktops = tasksModel.data(index, TaskManager.AbstractTasksModel.VirtualDesktops) || [];
            for (const desktop of desktops) {
                const id = String(desktop);
                if (id !== current && !found.includes(id)) found.push(id);
            }
        }
        let result = [];
        for (let i = 0; i < ids.length; ++i) {
            if (found.includes(String(ids[i]))) result.push(names[i] || String(i + 1));
        }
        return result;
    }
    readonly property Connections changes: Connections {
        target: root.tasksModel
        ignoreUnknownSignals: true
        function onDataChanged() { ++root.revision; }
        function onRowsInserted() { ++root.revision; }
        function onRowsRemoved() { ++root.revision; }
        function onRowsMoved() { ++root.revision; }
        function onModelReset() { ++root.revision; }
        function onLayoutChanged() { ++root.revision; }
    }
}
