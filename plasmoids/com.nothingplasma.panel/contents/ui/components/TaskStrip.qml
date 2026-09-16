pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.taskmanager as TaskManager
import "../../island/ui" as Island

Item {
    id: root
    property var tasksModel
    property int maximumWidth: 420
    property color accentColor: Island.Theme.fg
    property real uiScale: 1
    property int previewWidthPercent: 44
    property int previewHeightPercent: 20
    property int selectedRow: -1
    property int dragRow: -1
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
    function moveTask(from, to) {
        if (!tasksModel || from < 0 || to < 0 || from === to) return;
        chooser.closePopup();
        if (tasksModel.move(from, to)) { dragRow = to; tasksModel.syncLaunchers(); }
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
        function onRowsAboutToBeRemoved() { chooser.closePopup(); }
        function onRowsAboutToBeInserted() { chooser.closePopup(); }
        function onRowsAboutToBeMoved() { chooser.closePopup(); }
        function onModelAboutToBeReset() { chooser.closePopup(); }
        function onLayoutAboutToBeChanged() { chooser.closePopup(); }
    }

    ListView {
        id: taskList
        anchors.fill: parent
        orientation: ListView.Horizontal
        spacing: root.cellStep - root.cellSize
        clip: true
        model: root.tasksModel
        boundsBehavior: Flickable.StopAtBounds
        activeFocusOnTab: true
        QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AsNeeded }
        Keys.onLeftPressed: decrementCurrentIndex()
        Keys.onRightPressed: incrementCurrentIndex()
        Keys.onReturnPressed: root.activateCurrent()
        Keys.onEnterPressed: root.activateCurrent()

        delegate: Item {
            id: task
            required property var model
            required property int index
            readonly property bool isGroup: model.IsGroupParent === true && Number(model.ChildCount) > 1
            readonly property int windowCount: isGroup ? Number(model.ChildCount) : (model.IsWindow ? 1 : 0)
            readonly property var modelIndex: root.tasksModel ? root.tasksModel.makeModelIndex(index) : null
            readonly property var launcherUrl: root.launcherUrlFor(model)
            readonly property string appName: String(model.AppName || model.display || "")
            width: root.cellSize
            height: root.cellSize
            Accessible.role: Accessible.Button
            Accessible.name: appName + (isGroup ? " · " + windowCount + " " + Island.Cfg.t("WINDOWS") : "")
            Accessible.onPressAction: activateTask()
            QQC2.ToolTip.visible: hover.containsMouse && windowCount === 0 && taskMenu.status !== PlasmaExtras.Menu.Open
            QQC2.ToolTip.text: appName
            QQC2.ToolTip.delay: 500

            function activateTask() {
                if (isGroup) {
                    groupPreviewTip.hideImmediately();
                    root.chooseWindows(index, windowCount, appName, model.decoration, task);
                } else root.activateOrMinimize(modelIndex);
            }

            Rectangle {
                anchors.fill: parent
                radius: 13 * root.uiScale
                color: task.model.IsActive ? Island.Theme.surfaceTop : hover.containsMouse ? Island.Theme.surfaceHigh : "transparent"
                border.width: taskList.activeFocus && taskList.currentIndex === task.index ? 1 : 0
                border.color: Island.Theme.fgDim
                Behavior on color { ColorAnimation { duration: Island.Theme.durShort } }
                Kirigami.Icon {
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
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    width: 15
                    height: 15
                    radius: 7.5
                    visible: task.isGroup
                    color: Island.Theme.inverted
                    Text {
                        anchors.centerIn: parent
                        text: Math.min(99, task.windowCount)
                        font.family: Island.Theme.font
                        font.pixelSize: 9
                        color: Island.Theme.invertedFg
                    }
                }
            }

            Item {
                id: dragProxy
                property int taskRow: task.index
                width: 1
                height: 1
                Drag.active: hover.drag.active
                Drag.source: dragProxy
                Drag.keys: ["nothing-task"]
                Drag.hotSpot.x: 0
                Drag.hotSpot.y: 0
            }
            DropArea {
                anchors.fill: parent
                keys: ["nothing-task"]
                onEntered: drag => {
                    if (drag.source) root.moveTask(root.dragRow, task.index);
                }
            }

            PlasmaCore.ToolTipArea {
                id: groupPreviewTip
                anchors.fill: parent
                active: task.windowCount > 0 && !chooser.visible && !hover.pressed && taskMenu.status !== PlasmaExtras.Menu.Open
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
                    uiScale: root.uiScale
                    previewWidthPercent: root.previewWidthPercent
                    previewHeightPercent: root.previewHeightPercent
                    onWindowActivated: groupPreviewTip.hideImmediately()
                }
                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    drag.target: dragProxy
                    drag.axis: Drag.XAndYAxis
                    drag.threshold: 12
                    property bool dragged: false
                    onPressed: { dragged = false; root.dragRow = task.index; taskList.currentIndex = task.index; }
                    onPositionChanged: if (drag.active) dragged = true
                    onReleased: {
                        if (dragged) { dragProxy.Drag.drop(); root.tasksModel.syncLaunchers(); }
                        dragProxy.x = 0; dragProxy.y = 0;
                    }
                    onClicked: mouse => {
                        if (dragged || !root.tasksModel || !task.modelIndex) return;
                        if (mouse.button === Qt.RightButton) taskMenu.openRelative();
                        else if (mouse.button === Qt.MiddleButton) root.tasksModel.requestNewInstance(task.modelIndex);
                        else task.activateTask();
                    }
                    onWheel: wheel => {
                        if (taskList.contentWidth > taskList.width) {
                            taskList.contentX = Math.max(0, Math.min(taskList.contentWidth - taskList.width,
                                taskList.contentX - wheel.angleDelta.y));
                            wheel.accepted = true;
                        } else wheel.accepted = false;
                    }
                }
            }
            PlasmaExtras.Menu {
                id: taskMenu
                visualParent: task
                placement: PlasmaExtras.Menu.TopPosedLeftAlignedPopup
                minimumWidth: 220
                PlasmaExtras.MenuItem {
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
                onWindowActivated: chooser.closePopup()
            }
        }
    }
}
