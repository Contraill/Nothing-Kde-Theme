pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager
import "../../island/ui" as Island

FocusScope {
    id: root
    required property var tasksModel
    required property int rootRow
    required property int childCount
    required property var fallbackIcon
    required property string appName
    property bool grouped: true
    property color accentColor: Island.Theme.fg
    property real uiScale: 1
    property int previewWidthPercent: 44
    property int previewHeightPercent: 20
    property int revision: 0
    signal windowActivated()
    readonly property int safeCount: Math.max(1, childCount)
    readonly property int visibleCardCount: Math.min(3, root.safeCount)
    implicitWidth: Math.min(Screen.width - 24, visibleCardCount * 232 + 28)
    implicitHeight: 224

    function childIndex(row) { return tasksModel ? (grouped ? tasksModel.makeModelIndex(rootRow, row) : tasksModel.makeModelIndex(rootRow)) : null; }
    // Only explicit popup opening calls this; hover previews never steal focus.
    function focusDefault() { root.forceActiveFocus(); }
    function childData(row, role) {
        const index = childIndex(row);
        return index && tasksModel ? tasksModel.data(index, role) : null;
    }
    function activate(row) {
        if (row < 0 || row >= childCount) return;
        tasksModel.requestActivate(childIndex(row));
        windowActivated();
    }
    Connections {
        target: root.tasksModel
        ignoreUnknownSignals: true
        function onDataChanged() { root.revision++; }
    }
    Keys.onLeftPressed: previews.decrementCurrentIndex()
    Keys.onRightPressed: previews.incrementCurrentIndex()
    Keys.onReturnPressed: activate(previews.currentIndex)
    Keys.onEnterPressed: activate(previews.currentIndex)

    Rectangle { anchors.fill: parent; radius: Island.Theme.shapeLg; color: Island.Theme.surface }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: root.appName
                textFormat: Text.PlainText
                font.family: Island.Theme.font
                font.pixelSize: 13
                font.weight: Font.Medium
                color: Island.Theme.fg
                elide: Text.ElideRight
            }
            Text {
                text: root.childCount + " " + Island.Cfg.t("WINDOWS")
                font.family: Island.Theme.font
                font.pixelSize: 10
                color: Island.Theme.fgDim
            }
        }
        ListView {
            id: previews
            Layout.fillWidth: true
            Layout.fillHeight: true
            orientation: ListView.Horizontal
            spacing: 8
            clip: true
            currentIndex: 0
            model: Math.max(0, root.childCount)
            boundsBehavior: Flickable.StopAtBounds
            QQC2.ScrollBar.horizontal: QQC2.ScrollBar { policy: QQC2.ScrollBar.AsNeeded }
            delegate: QQC2.AbstractButton {
                id: card
                required property int index
                readonly property var titleValue: { root.revision; return root.childData(index, 0); }
                readonly property string title: titleValue ? String(titleValue) : root.appName
                readonly property var winIds: { root.revision; return root.childData(index, TaskManager.AbstractTasksModel.WinIdList); }
                readonly property var winId: winIds && winIds.length ? winIds[0] : null
                readonly property bool minimized: { root.revision; return root.childData(index, TaskManager.AbstractTasksModel.IsMinimized) === true; }
                width: (previews.width - 8 * (root.visibleCardCount - 1)) / root.visibleCardCount
                height: previews.height - 6
                Accessible.name: title
                onClicked: { previews.currentIndex = index; root.activate(index); }
                background: Rectangle {
                    radius: Island.Theme.shapeMd
                    color: card.hovered ? Island.Theme.surfaceHigh : Island.Theme.surfaceAlt
                    border.width: root.activeFocus && previews.currentIndex === card.index ? 1 : 0
                    border.color: Island.Theme.fgDim
                }
                contentItem: Item {
                    Item {
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.top: parent.top; anchors.bottom: titleRow.top
                        anchors.margins: 6
                        clip: true
                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: 42; height: 42
                            source: root.fallbackIcon
                        }
                        Loader {
                            anchors.fill: parent
                            active: !Island.Backend.preview && root.visible && (root.Window.window?.visible ?? false) && card.winId !== null && !card.minimized
                            source: "NativeWindowThumbnail.qml"
                            onLoaded: item.windowId = Qt.binding(() => card.winId)
                        }
                    }
                    RowLayout {
                        id: titleRow
                        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                        anchors.margins: 8
                        height: 32
                        Text {
                            Layout.fillWidth: true
                            text: card.title
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            color: Island.Theme.fg
                            font.family: Island.Theme.font
                            font.pixelSize: 11
                        }
                        QQC2.AbstractButton {
                            id: close
                            Layout.preferredWidth: 24; Layout.preferredHeight: 24
                            visible: root.childData(card.index, TaskManager.AbstractTasksModel.IsClosable) === true
                            Accessible.name: Island.Cfg.t("CLOSE WINDOW") + " · " + card.title
                            onClicked: { root.tasksModel.requestClose(root.childIndex(card.index)); root.windowActivated(); }
                            background: Rectangle { radius: 12; color: close.hovered ? Island.Theme.alert : Island.Theme.surfaceHigh }
                            contentItem: Text {
                                text: "close"; font.family: Island.Theme.fontIcons; font.pixelSize: 16
                                color: Island.Theme.fg
                                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }
            }
        }
    }
}
