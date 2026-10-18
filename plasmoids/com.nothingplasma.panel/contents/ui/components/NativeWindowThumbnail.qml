// Native task preview only: no recording, files, or resident capture helper.
import QtQuick
import org.kde.taskmanager as TaskManager
import org.kde.pipewire as PipeWire
// Wayland streams the window through KWin's screencast; X11 window ids have no
// stream, so the card keeps the application icon behind this item.
// (Plasma 6 removed PlasmaCore.WindowThumbnail; referencing it failed the whole file.)
Item {
    id: root
    property var windowId: null
    readonly property bool waylandId: typeof windowId === "string" && windowId.includes("-")
    Loader {
        anchors.fill: parent
        active: root.waylandId
        sourceComponent: PipeWire.PipeWireSourceItem {
            nodeId: stream.nodeId
            TaskManager.ScreencastingRequest { id: stream; uuid: String(root.windowId) }
        }
    }
}
