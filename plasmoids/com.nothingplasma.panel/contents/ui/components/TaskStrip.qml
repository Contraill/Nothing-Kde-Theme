pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Shapes
import QtQuick.Window
import QtQml.Models
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.taskmanager as TaskManager
import "../../island/ui" as Island

Item {
    id: root
    property var tasksModel
    TaskManager.VirtualDesktopInfo { id: nativeDesktopInfo }
    property var desktopInfo: nativeDesktopInfo
    property int maximumWidth: 420
    property color accentColor: Island.Theme.fg
    property real uiScale: 1
    property int previewWidthPercent: 44
    property int previewHeightPercent: 20
    property int selectedRow: -1
    property var dragStyleHints: Qt.styleHints
    property int dragRow: -1
    property int dropRow: -1
    property real dragX: 0
    property real dragY: 0
    property var dragIcon: ""
    readonly property bool dragging: dragRow >= 0 && dropRow >= 0
    function finishDrag(commit) {
        const from = dragRow, to = dropRow;
        dragRow = -1; dropRow = -1;
        if (commit) moveTask(from, to);
    }
    function updateDrag(x, y) {
        dragX = x; dragY = y;
        dropRow = Math.max(0, Math.min(taskList.count - 1, Math.floor((x + taskList.contentX) / cellStep)));
    }
    property int selectedCount: 0
    property string selectedName: ""
    property var selectedIcon: ""
    signal pinToggleRequested(var launcherUrl)

    function launcherUrlFor(data) {
        for (const url of [data?.LauncherUrlWithoutIcon, data?.LauncherUrl]) {
            if (url !== null && url !== undefined && String(url).length > 0) return url;
        }
        return null;
    }
    function isPinned(data) {
        const url = launcherUrlFor(data);
        return url !== null && tasksModel && tasksModel.launcherPosition(url) >= 0;
    }
    function activateOrMinimize(index) {
        if (!tasksModel || !index) return;
        if (tasksModel.data(index, TaskManager.AbstractTasksModel.IsLauncher) === true) {
            tasksModel.requestActivate(index);
        } else if (tasksModel.data(index, TaskManager.AbstractTasksModel.IsActive) === true
                   && tasksModel.data(index, TaskManager.AbstractTasksModel.IsMinimizable) !== false) {
            tasksModel.requestToggleMinimized(index);
        } else tasksModel.requestActivate(index);
    }
    function chooseWindows(row, count, name, icon, anchor) {
        if (chooser.visible && selectedRow === row) { chooser.closePopup(); return; }
        selectedRow = row;
        selectedCount = count;
        selectedName = name;
        selectedIcon = icon;
        chooser.anchorItem = anchor;
        chooser.openPopup();
    }
    // Next/previous window of a task (wheel, Meta+N on groups); a lone window or launcher is just activated.
    function cycleTask(row, direction) {
        if (!tasksModel || row < 0 || row >= taskList.count) return;
        const parent = tasksModel.makeModelIndex(row);
        const count = Number(tasksModel.data(parent, TaskManager.AbstractTasksModel.ChildCount)) || 0;
        if (tasksModel.data(parent, TaskManager.AbstractTasksModel.IsGroupParent) !== true || count < 2) {
            tasksModel.requestActivate(parent);
            return;
        }
        let active = -1;
        for (let i = 0; i < count; ++i) {
            if (tasksModel.data(tasksModel.makeModelIndex(row, i), TaskManager.AbstractTasksModel.IsActive) === true) {
                active = i;
                break;
            }
        }
        const next = active < 0 ? 0 : (active + direction + count) % count;
        tasksModel.requestActivate(tasksModel.makeModelIndex(row, next));
    }
    // Meta+1…9 as in Plasma's task manager: launch, raise or minimise; groups cycle.
    function activateEntry(row) {
        if (!tasksModel || row < 0 || row >= taskList.count) return;
        const index = tasksModel.makeModelIndex(row);
        Island.Notifs.markSeen(String(tasksModel.data(index, TaskManager.AbstractTasksModel.AppId) ?? ""));
        const count = Number(tasksModel.data(index, TaskManager.AbstractTasksModel.ChildCount)) || 0;
        if (tasksModel.data(index, TaskManager.AbstractTasksModel.IsGroupParent) === true && count > 1) cycleTask(row, 1);
        else activateOrMinimize(index);
    }
    function moveTask(from, to) {
        if (!tasksModel || from < 0 || to < 0 || from === to) return;
        chooser.closePopup();
        if (tasksModel.move(from, to)) tasksModel.syncLaunchers();
    }
    function activateCurrent() {
        const row = taskList.currentIndex;
        if (!tasksModel || row < 0) return;
        const index = tasksModel.makeModelIndex(row);
        const count = Number(tasksModel.data(index, TaskManager.AbstractTasksModel.ChildCount));
        if (tasksModel.data(index, TaskManager.AbstractTasksModel.IsGroupParent) === true && count > 1)
            chooseWindows(row, count, String(tasksModel.data(index, TaskManager.AbstractTasksModel.AppName)), tasksModel.data(index, 1), taskList.currentItem);
        else activateOrMinimize(index);
    }

    readonly property int cellSize: Math.round(38 * uiScale)
    readonly property int cellStep: Math.round(44 * uiScale)
    implicitWidth: Math.min(maximumWidth, taskList.count * cellStep)
    implicitHeight: cellSize

    Connections {
        target: root.tasksModel
        ignoreUnknownSignals: true
        function onRowsAboutToBeRemoved() { root.finishDrag(false); chooser.closePopup(); }
        function onRowsAboutToBeInserted() { root.finishDrag(false); chooser.closePopup(); }
        function onRowsAboutToBeMoved() { root.finishDrag(false); chooser.closePopup(); }
        function onModelAboutToBeReset() { root.finishDrag(false); chooser.closePopup(); }
        function onLayoutAboutToBeChanged() { root.finishDrag(false); chooser.closePopup(); }
    }

    ListView {
        id: taskList
        anchors.fill: parent
        orientation: ListView.Horizontal
        spacing: root.cellStep - root.cellSize
        clip: true
        model: root.tasksModel
        boundsBehavior: Flickable.StopAtBounds
        interactive: !root.dragging
        objectName: "dockTaskList"
        activeFocusOnTab: true
        QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AsNeeded }
        Keys.onLeftPressed: decrementCurrentIndex()
        Keys.onRightPressed: incrementCurrentIndex()
        Keys.onReturnPressed: root.activateCurrent()
        Keys.onEnterPressed: root.activateCurrent()

        delegate: Item {
            id: task
            objectName: "dockTask-" + index
            required property var model
            required property int index
            readonly property bool isGroup: model.IsGroupParent === true && Number(model.ChildCount) > 1
            readonly property int windowCount: isGroup ? Number(model.ChildCount) : (model.IsWindow ? 1 : 0)
            readonly property var modelIndex: root.tasksModel ? root.tasksModel.makeModelIndex(index) : null
            readonly property var launcherUrl: root.launcherUrlFor(model)
            readonly property string appName: String(model.AppName || model.display || "")
            readonly property string appId: String(model.AppId || "")
            readonly property var jobProgress: Island.Notifs.jobsByApp[appId]
            readonly property int unreadCount: Island.Notifs.unreadByApp[appId] ?? 0
            property real wheelDelta: 0
            // KWin animates minimising towards this rectangle.
            function publishGeometry(): void {
                if (!root.tasksModel || !task.modelIndex || task.windowCount === 0) return;
                const p = task.mapToGlobal(0, 0);
                root.tasksModel.requestPublishDelegateGeometry(task.modelIndex, Qt.rect(p.x, p.y, task.width, task.height), task);
            }
            Component.onCompleted: Qt.callLater(task.publishGeometry)
            onXChanged: Qt.callLater(task.publishGeometry)
            onWindowCountChanged: Qt.callLater(task.publishGeometry)
            Connections {
                target: taskList
                function onContentXChanged() { Qt.callLater(task.publishGeometry); }
            }
            width: root.cellSize
            height: root.cellSize
            Accessible.role: Accessible.Button
            Accessible.name: appName + (isGroup ? " · " + windowCount + " " + Island.Cfg.t("WINDOWS") : "")
            Accessible.onPressAction: activateTask()
            QQC2.ToolTip.visible: hover.containsMouse && windowCount === 0 && taskMenu.status !== PlasmaExtras.Menu.Open
            QQC2.ToolTip.text: appName
            QQC2.ToolTip.delay: 500

            function activateTask() {
                Island.Notifs.markSeen(task.appId);
                if (isGroup) {
                    groupPreviewTip.hideImmediately();
                    root.chooseWindows(index, windowCount, appName, model.decoration, task);
                } else root.activateOrMinimize(modelIndex);
            }

            DesktopActions { id: desktopActions; launcherUrl: String(task.launcherUrl || "") }
            TaskWorkspaces {
                id: workspaces
                tasksModel: root.tasksModel
                row: task.index
                grouped: task.isGroup
                childCount: task.windowCount
                desktopInfo: root.desktopInfo
            }
            Rectangle {
                id: taskFace
                opacity: root.dragging && root.dragRow === task.index ? 0 : 1
                transform: Translate {
                    x: !root.dragging ? 0
                        : root.dragRow < root.dropRow && task.index > root.dragRow && task.index <= root.dropRow ? -root.cellStep
                        : root.dragRow > root.dropRow && task.index >= root.dropRow && task.index < root.dragRow ? root.cellStep : 0
                    Behavior on x { NumberAnimation { duration: 120 } }
                }
                anchors.fill: parent
                radius: 13 * root.uiScale
                color: task.model.IsActive ? Island.Theme.surfaceTop : hover.containsMouse ? Island.Theme.surfaceHigh : "transparent"
                border.width: taskList.activeFocus && taskList.currentIndex === task.index ? 1 : 0
                border.color: Island.Theme.fgDim
                Behavior on color { ColorAnimation { duration: Island.Theme.durShort } }
                Rectangle {
                    objectName: "otherWorkspaceDot"
                    z: 1
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: 3 * root.uiScale
                    width: 9 * root.uiScale; height: width; radius: width / 2
                    visible: workspaces.otherNames.length > 0
                    color: root.accentColor
                    // Ring keeps the dot readable over icons that share the accent hue.
                    border.width: 2 * root.uiScale
                    border.color: Island.Theme.surface
                }
                Kirigami.Icon {
                    id: taskIcon
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -2
                    width: 25 * root.uiScale
                    height: width
                    source: task.model.decoration
                    opacity: task.model.IsMinimized ? 0.55 : 1
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2
                    width: task.model.IsActive ? 14 : 4
                    height: 3
                    radius: 1.5
                    visible: task.windowCount > 0 || task.model.IsStartup === true
                    color: task.model.IsDemandingAttention ? Island.Theme.alert : task.model.IsActive ? Island.Theme.fg : Island.Theme.fgDim
                    Behavior on width { NumberAnimation { duration: Island.Theme.durShort } }
                }
                // Progress of the application's running KDE jobs.
                Shape {
                    objectName: "taskProgressRing"
                    anchors.centerIn: taskIcon
                    width: taskIcon.width + 8 * root.uiScale
                    height: width
                    visible: task.jobProgress !== undefined
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: Island.Theme.surfaceHigh
                        strokeWidth: 2 * root.uiScale
                        fillColor: "transparent"
                        PathAngleArc {
                            centerX: taskIcon.width / 2 + 4 * root.uiScale
                            centerY: centerX
                            radiusX: centerX - root.uiScale
                            radiusY: radiusX
                            startAngle: 0
                            sweepAngle: 360
                        }
                    }
                    ShapePath {
                        strokeColor: root.accentColor
                        strokeWidth: 2 * root.uiScale
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathAngleArc {
                            centerX: taskIcon.width / 2 + 4 * root.uiScale
                            centerY: centerX
                            radiusX: centerX - root.uiScale
                            radiusY: radiusX
                            startAngle: -90
                            sweepAngle: 3.6 * Math.max(2, task.jobProgress ?? 0)
                        }
                    }
                }
                // Unread notifications (Plasma's "badges in task manager" setting).
                Rectangle {
                    objectName: "taskUnreadBadge"
                    anchors.right: parent.right
                    anchors.top: parent.top
                    z: 1
                    visible: task.unreadCount > 0
                    height: 15
                    width: Math.max(15, unreadText.implicitWidth + 7)
                    radius: 7.5
                    color: root.accentColor
                    border.width: 1.5
                    border.color: Island.Theme.surface
                    Text {
                        id: unreadText
                        anchors.centerIn: parent
                        text: task.unreadCount > 99 ? "99+" : task.unreadCount
                        font.family: Island.Theme.font
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: root.accentColor.hslLightness > 0.58 ? "#111111" : "#ffffff"
                    }
                }
                Rectangle {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    width: 14
                    height: 14
                    radius: 7
                    visible: task.isGroup
                    color: Island.Theme.inverted
                    Text {
                        anchors.centerIn: parent
                        text: Math.min(99, task.windowCount)
                        font.family: Island.Theme.font
                        font.pixelSize: 8
                        color: Island.Theme.invertedFg
                    }
                }
            }

            PlasmaCore.ToolTipArea {
                id: groupPreviewTip
                anchors.fill: parent
                active: !root.dragging && task.windowCount > 0 && !chooser.visible && !hover.pressed && taskMenu.status !== PlasmaExtras.Menu.Open
                interactive: true
                timeout: -1
                location: PlasmaCore.Types.BottomEdge
                mainItem: TaskPreviewContent {
                    tasksModel: root.tasksModel
                    rootRow: task.index
                    childCount: Math.max(1, task.windowCount)
                    grouped: task.isGroup
                    fallbackIcon: task.model.decoration
                    appName: task.appName
                    desktopInfo: root.desktopInfo
                    accentColor: root.accentColor
                    uiScale: root.uiScale
                    previewWidthPercent: root.previewWidthPercent
                    previewHeightPercent: root.previewHeightPercent
                    onWindowActivated: groupPreviewTip.hideImmediately()
                }
                MouseArea {
                    id: hover
                    objectName: "dockTaskPointer-" + task.index
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    property bool dragged: false
                    property real pressX: 0
                    property real pressY: 0
                    preventStealing: true
                    onPressed: mouse => {
                        dragged = false; pressX = mouse.x; pressY = mouse.y;
                        taskList.currentIndex = task.index;
                    }
                    onPositionChanged: mouse => {
                        if (!(pressedButtons & Qt.LeftButton)) return;
                        if (!dragged && Math.hypot(mouse.x - pressX, mouse.y - pressY) >= root.dragStyleHints.startDragDistance) {
                            dragged = true;
                            chooser.closePopup(); groupPreviewTip.hideImmediately();
                            root.dragRow = task.index; root.dropRow = task.index;
                            root.dragIcon = task.model.decoration;
                        }
                        if (dragged && root.dragging) {
                            const p = mapToItem(root, mouse.x, mouse.y);
                            root.updateDrag(p.x, p.y);
                        }
                    }
                    onReleased: mouse => {
                        if (dragged) {
                            const p = mapToItem(root, mouse.x, mouse.y);
                            root.finishDrag(p.y >= -root.cellSize && p.y <= root.height + root.cellSize);
                        }
                    }
                    onCanceled: root.finishDrag(false)
                    onClicked: mouse => {
                        if (dragged || !root.tasksModel || !task.modelIndex) return;
                        if (mouse.button === Qt.RightButton) { desktopActions.refresh(); taskMenu.openRelative(); }
                        else if (mouse.button === Qt.MiddleButton) root.tasksModel.requestNewInstance(task.modelIndex);
                        else task.activateTask();
                    }
                    onWheel: wheel => {
                        // Over a running app the wheel walks its windows; Shift or an
                        // overflowing launcher row scrolls the dock instead.
                        if (task.windowCount > 0 && wheel.angleDelta.y !== 0 && !(wheel.modifiers & Qt.ShiftModifier)) {
                            task.wheelDelta += wheel.angleDelta.y;
                            while (Math.abs(task.wheelDelta) >= 120) {
                                const direction = task.wheelDelta > 0 ? -1 : 1;
                                task.wheelDelta += direction * 120;
                                root.cycleTask(task.index, direction);
                            }
                            wheel.accepted = true;
                        } else if (taskList.contentWidth > taskList.width) {
                            const delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x;
                            taskList.contentX = Math.max(0, Math.min(taskList.contentWidth - taskList.width,
                                taskList.contentX - delta));
                            wheel.accepted = true;
                        } else wheel.accepted = false;
                    }
                }
            }
            // Files dropped on an icon open with that application; hovering while
            // dragging raises its window so the file can be dropped into it.
            DropArea {
                anchors.fill: parent
                function isLauncherFile(url): bool {
                    const text = String(url);
                    return text.startsWith("applications:") || text.endsWith(".desktop");
                }
                onEntered: drag => {
                    // .desktop files fall through to the dock's pinning drop area.
                    if (!drag.hasUrls || drag.urls.every(url => isLauncherFile(url))) {
                        drag.accepted = false;
                        return;
                    }
                    if (task.windowCount > 0) raiseWhileDragging.restart();
                }
                onExited: raiseWhileDragging.stop()
                onDropped: drop => {
                    raiseWhileDragging.stop();
                    const files = drop.urls.filter(url => !isLauncherFile(url));
                    if (!files.length || !root.tasksModel || !task.modelIndex) return;
                    root.tasksModel.requestOpenUrls(task.modelIndex, files);
                    drop.acceptProposedAction();
                }
                Timer {
                    id: raiseWhileDragging
                    interval: 700
                    onTriggered: if (root.tasksModel && task.modelIndex) root.tasksModel.requestActivate(task.modelIndex)
                }
            }
            PlasmaExtras.Menu {
                id: taskMenu
                visualParent: task
                placement: PlasmaExtras.Menu.TopPosedLeftAlignedPopup
                minimumWidth: 220
                readonly property Instantiator applicationActions: Instantiator {
                    model: desktopActions.actions
                    delegate: PlasmaExtras.MenuItem {
                        required property var modelData
                        text: modelData.text
                        icon: modelData.icon || ""
                        onClicked: desktopActions.trigger(modelData)
                    }
                    onObjectAdded: (index, object) => taskMenu.addMenuItem(object, pinMenuItem)
                    onObjectRemoved: (index, object) => taskMenu.removeMenuItem(object)
                }
                PlasmaExtras.MenuItem {
                    id: pinMenuItem
                    text: root.isPinned(task.model) ? Island.Cfg.t("UNPIN DOCK") : Island.Cfg.t("PIN DOCK")
                    icon: "window-pin"
                    enabled: task.launcherUrl !== null
                    onClicked: root.pinToggleRequested(task.launcherUrl)
                }
                PlasmaExtras.MenuItem {
                    text: Island.Cfg.t("NEW WINDOW")
                    icon: "window-new"
                    visible: task.model.CanLaunchNewInstance === true || task.model.IsLauncher === true
                    onClicked: root.tasksModel.requestNewInstance(task.modelIndex)
                }
                PlasmaExtras.MenuItem {
                    text: Island.Cfg.t("CHOOSE WINDOW")
                    icon: "view-list-icons"
                    visible: task.isGroup
                    onClicked: task.activateTask()
                }
                PlasmaExtras.MenuItem { separator: true }
                PlasmaExtras.MenuItem {
                    text: task.model.IsMinimized ? Island.Cfg.t("RESTORE WINDOW") : Island.Cfg.t("MINIMIZE WINDOW")
                    icon: "window-minimize"
                    visible: task.windowCount > 0
                    enabled: task.model.IsMinimizable === true
                    onClicked: root.tasksModel.requestToggleMinimized(task.modelIndex)
                }
                PlasmaExtras.MenuItem {
                    text: task.model.IsMaximized ? Island.Cfg.t("RESTORE WINDOW") : Island.Cfg.t("MAXIMIZE WINDOW")
                    icon: "window-maximize"
                    visible: task.windowCount > 0
                    enabled: task.model.IsMaximizable === true
                    onClicked: root.tasksModel.requestToggleMaximized(task.modelIndex)
                }
                PlasmaExtras.MenuItem { separator: true }
                PlasmaExtras.MenuItem {
                    text: task.isGroup ? Island.Cfg.t("CLOSE ALL WINDOWS") : Island.Cfg.t("CLOSE WINDOW")
                    icon: "window-close"
                    visible: task.windowCount > 0
                    enabled: task.model.IsClosable === true
                    onClicked: root.tasksModel.requestClose(task.modelIndex)
                }
            }
        }
    }
    Rectangle {
        visible: root.dragging
        x: root.dropRow * root.cellStep - taskList.contentX
        y: 0; width: root.cellSize; height: root.cellSize
        radius: 13 * root.uiScale
        color: "transparent"; border.width: 1; border.color: Island.Theme.fgDim
    }
    Kirigami.Icon {
        visible: root.dragging
        x: root.dragX - width / 2; y: root.dragY - height / 2
        width: 29 * root.uiScale; height: width
        source: root.dragIcon
        z: 10
    }
    Timer {
        interval: 30; repeat: true; running: root.dragging
        onTriggered: {
            const direction = root.dragX < root.cellStep / 2 ? -1 : root.dragX > root.width - root.cellStep / 2 ? 1 : 0;
            taskList.contentX = Math.max(0, Math.min(Math.max(0, taskList.contentWidth - taskList.width), taskList.contentX + direction * 8));
            root.updateDrag(root.dragX, root.dragY);
        }
    }
    NothingPopupWindow {
        id: chooser
        popupParent: root
        anchorItem: root
        panelLocation: PlasmaCore.Types.BottomEdge
        islandStyle: true
        popupWidth: Math.min(Screen.width - 24, Math.min(3, Math.max(1, root.selectedCount)) * 232 + 28)
        popupHeight: 224
        pageComponent: Component {
            TaskPreviewContent {
                tasksModel: root.tasksModel
                rootRow: root.selectedRow
                childCount: root.selectedCount
                fallbackIcon: root.selectedIcon
                appName: root.selectedName
                grouped: true
                desktopInfo: root.desktopInfo
                accentColor: root.accentColor
                onWindowActivated: chooser.closePopup()
            }
        }
    }
}
