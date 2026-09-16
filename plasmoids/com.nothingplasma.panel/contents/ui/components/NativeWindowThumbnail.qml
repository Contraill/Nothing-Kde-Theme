// Native task preview only: no recording, files, or resident capture helper.
import QtQuick
import org.kde.taskmanager as TaskManager
import org.kde.pipewire as PipeWire
import org.kde.plasma.core as PlasmaCore
Item {
    id: root
    property var windowId: null
    readonly property bool waylandId: typeof windowId === "string" && windowId.includes("-")
    Loader {
        anchors.fill: parent
        active: root.windowId !== null
        sourceComponent: root.waylandId ? wayland : x11
    }
    Component {
        id: wayland
        PipeWire.PipeWireSourceItem {
            nodeId: stream.nodeId
            TaskManager.ScreencastingRequest { id: stream; uuid: String(root.windowId) }
        }
    }
    Component {
        id: x11
        PlasmaCore.WindowThumbnail { winId: Number(root.windowId) || 0 }
    }
}
