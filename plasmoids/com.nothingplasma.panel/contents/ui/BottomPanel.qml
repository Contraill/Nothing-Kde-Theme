pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.taskmanager as TaskManager
import org.kde.plasma.private.kicker as Kicker
import "components" as Components
import QtQuick.Controls as QQC2
import "../island/ui" as Island
import org.kde.kwindowsystem as KWindowSystem
import org.kde.kcmutils as KCMUtils

Item {
    id: root

    required property ContainmentItem appletItem
    required property Components.PanelRoleMetrics metrics
    required property int shortcutEpoch

    onShortcutEpochChanged: {
        if (root.shortcutEpoch > 0) root.toggleLauncher()
    }

    Binding {
        target: root.metrics
        property: "requestedWidth"
        value: root.implicitWidth
    }
    Binding {
        target: root.metrics
        property: "requestedHeight"
        value: Math.max(40, Math.min(72, Plasmoid.configuration.horizontalPanelHeight))
    }

    property var allAppsModel: null
    property bool launcherPersistenceReady: false

    readonly property color accentColor: Kirigami.Theme.highlightColor
    readonly property real uiScale: Math.max(0.85, Math.min(1.45, root.height / 50.0))
    readonly property real logicalScreenWidth: Screen.desktopAvailableWidth > 0 ? Screen.desktopAvailableWidth : Screen.width
    readonly property real logicalScreenHeight: Screen.desktopAvailableHeight > 0 ? Screen.desktopAvailableHeight : Screen.height
    readonly property real popupUiScale: Math.max(0.92, Math.min(1.35, Math.sqrt((root.logicalScreenWidth * root.logicalScreenHeight) / (1920.0 * 1080.0))))
    readonly property int horizontalPadding: Math.max(9, Math.round(11 * root.uiScale))
    readonly property int controlHeight: Math.round(38 * root.uiScale)
    readonly property int buttonWidth: root.controlHeight
    readonly property int itemSpacing: Math.max(3, Math.round(5 * root.uiScale))
    readonly property int taskAreaLimit: Math.round(root.logicalScreenWidth * Plasmoid.configuration.taskAreaMaxPercent / 100.0)
    readonly property int taskAreaWidth: Math.min(root.taskAreaLimit,
        Math.max(0, Math.round(root.logicalScreenWidth * 0.70) - root.horizontalPadding * 2 - root.buttonWidth - root.itemSpacing * 4 - 20),
        Math.max(0, Math.round(taskSourceModel.count * 44 * root.uiScale)))
    readonly property int naturalWidth: Math.max(
        Math.round(110 * root.uiScale),
        root.horizontalPadding * 2 + root.buttonWidth + root.taskAreaWidth + root.itemSpacing * 4 + Math.round(20 * root.uiScale)
    )
    readonly property real panelSurfaceOpacity: Math.max(0.18, Math.min(0.98, Plasmoid.configuration.panelOpacity / 100.0))
    readonly property real popupSurfaceOpacity: Math.max(0.18, Math.min(0.96, Plasmoid.configuration.popupOpacity / 100.0))
    readonly property int launcherMinimumWidth: Math.round(
        root.logicalScreenWidth * Plasmoid.configuration.launcherWidthPercent / 100.0
    )
    readonly property int popupHeightLimit: Math.max(300, Math.round(root.logicalScreenHeight - root.height - 28))
    readonly property int launcherHeight: Math.min(
        root.popupHeightLimit,
        Math.max(Math.round(root.logicalScreenHeight * Plasmoid.configuration.launcherHeightPercent / 100.0), Math.round(440 * root.popupUiScale))
    )

    implicitWidth: Math.min(Math.round(root.logicalScreenWidth * 0.70), root.naturalWidth)
    implicitHeight: root.height > 0 ? root.height : 50

    Layout.minimumWidth: Math.round(110 * root.uiScale)
    Layout.preferredWidth: root.implicitWidth
    Layout.maximumWidth: Math.round(root.logicalScreenWidth * 0.70)
    Layout.preferredHeight: Math.max(40, Math.min(72, Plasmoid.configuration.horizontalPanelHeight))

    Components.NothingPalette { id: nothingPalette; accent: root.accentColor }
    Binding { target: Island.Cfg; property: "lang"; value: Plasmoid.configuration.islandLanguage }
    Binding { target: Island.Cfg; property: "colorFondo"; value: Plasmoid.configuration.appearanceMode === "light" ? "#EEEDE9" : "#000000" }
    Binding { target: Island.Cfg; property: "colorTarjeta"; value: Plasmoid.configuration.appearanceMode === "light" ? "#E7E6E1" : "#0B0B0B" }
    Binding { target: Island.Cfg; property: "colorInvertida"; value: Plasmoid.configuration.appearanceMode === "light" ? "#D0CFC8" : "#FFFFFF" }
    Binding { target: Island.Cfg; property: "colorTexto"; value: Plasmoid.configuration.appearanceMode === "light" ? "#393A37" : "#FFFFFF" }

    TaskManager.VirtualDesktopInfo { id: virtualDesktopInfo }
    TaskManager.ActivityInfo { id: activityInfo }

    TaskManager.TasksModel {
        id: taskSourceModel
        groupMode: TaskManager.TasksModel.GroupApplications
        sortMode: TaskManager.TasksModel.SortManual
        groupInline: false
        groupingWindowTasksThreshold: -1
        // A pinned launcher and its running windows occupy one task slot.
        // This mirrors Plasma's normal taskbar behavior and prevents duplicate
        // icons for the same application. Mixed (false) mode appends windows
        // that open after the launcher list loads, scrambling the pinned order.
        separateLaunchers: true
        launchInPlace: true
        hideActivatedLaunchers: true
        taskReorderingEnabled: true
        activity: activityInfo.currentActivity
        virtualDesktop: virtualDesktopInfo.currentDesktop
        filterByVirtualDesktop: false
        filterByActivity: true
        filterByScreen: false

        onLauncherListChanged: {
            if (root.launcherPersistenceReady) {
                Plasmoid.configuration.pinnedLaunchers = taskSourceModel.launcherList
            }
        }

        Component.onCompleted: {
            taskSourceModel.launcherList = Plasmoid.configuration.pinnedLaunchers
            root.launcherPersistenceReady = true
        }
    }

    Kicker.RootModel {
        id: appsRoot
        appletInterface: root.appletItem
        flat: true
        showAllApps: true
        showRecentApps: false
        showRecentDocs: false
        autoPopulate: false

        onRefreshed: root.allAppsModel = appsRoot.modelForRow(0)
        Component.onCompleted: appsRoot.refresh()
    }

    Kicker.RunnerModel {
        id: searchRunner
        appletInterface: root.appletItem
        mergeResults: true
        runners: ["services"]
    }

    function toggleLauncher(): void {
        if (launcherPopup.visible) launcherPopup.closePopup()
        else if (!launcherPopup.wasJustClosed()) launcherPopup.openPopup()
    }

    function openLauncherSettings(): void {
        launcherPopup.closePopup()
        launcherHandoff.targetPopup = launcherSettingsPopup
        launcherHandoff.restart()
    }

    function returnToLauncher(): void {
        launcherSettingsPopup.closePopup()
        launcherHandoff.targetPopup = launcherPopup
        launcherHandoff.restart()
    }

    Timer {
        id: launcherHandoff
        interval: 85
        repeat: false
        property Components.NothingPopupWindow targetPopup: null
        onTriggered: {
            if (!launcherHandoff.targetPopup) return
            launcherHandoff.targetPopup.openPopup()
            launcherHandoff.targetPopup = null
        }
    }


    function togglePinnedLauncher(launcherUrl): void {
        if (!launcherUrl) return
        const text = launcherUrl.toString ? launcherUrl.toString() : String(launcherUrl)
        if (text.length === 0) return
        if (taskSourceModel.launcherPosition(launcherUrl) >= 0) taskSourceModel.requestRemoveLauncher(launcherUrl)
        else taskSourceModel.requestAddLauncher(launcherUrl)
    }

    Rectangle {
        id: panelSurface
        anchors.fill: parent
        anchors.topMargin: 3
        anchors.bottomMargin: 3
        radius: height / 2
        color: Island.Theme.surface
        DropArea {
            anchors.fill: parent
            onDropped: drop => {
                if (!drop.hasUrls) return;
                let accepted = false;
                for (const url of drop.urls) {
                    const value = String(url);
                    if (value.startsWith("applications:") || (value.startsWith("file:") && value.endsWith(".desktop"))) {
                        taskSourceModel.requestAddLauncher(url);
                        accepted = true;
                    }
                }
                if (accepted) drop.acceptProposedAction();
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.horizontalPadding
            anchors.rightMargin: root.horizontalPadding
            spacing: root.itemSpacing

            QQC2.AbstractButton {
                id: launcherButton
                Layout.preferredWidth: root.buttonWidth
                Layout.preferredHeight: root.controlHeight
                Accessible.name: Island.Cfg.t("APPLICATIONS")
                // A clicked button keeps focus; when the launcher popup closes
                // its keyboard focus returns to the panel and Plasma paints the
                // blue panel focus indicator over the focused item.
                focusPolicy: Qt.TabFocus
                background: Rectangle {
                    radius: height / 2
                    color: launcherPopup.visible || launcherSettingsPopup.visible ? Island.Theme.inverted : launcherButton.hovered ? Island.Theme.surfaceHigh : "transparent"
                }
                contentItem: Text {
                    text: "apps"
                    font.family: Island.Theme.fontIcons
                    font.pixelSize: 23 * root.uiScale
                    color: launcherPopup.visible || launcherSettingsPopup.visible ? Island.Theme.invertedFg : Island.Theme.fg
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: root.toggleLauncher()
            }

            Rectangle {
                visible: taskSourceModel.count > 0
                Layout.preferredWidth: 1
                Layout.preferredHeight: Math.round(20 * root.uiScale)
                color: Island.Theme.outline
            }

            Components.TaskStrip {
                Layout.minimumWidth: 0
                visible: taskSourceModel.count > 0
                Layout.preferredWidth: root.taskAreaWidth
                Layout.preferredHeight: root.controlHeight
                maximumWidth: root.taskAreaLimit
                tasksModel: taskSourceModel
                // highlightColor is KDE's selection tone (accent blended into the
                // background); dock marks show the chosen accent itself.
                accentColor: Plasmoid.configuration.accentColor
                uiScale: root.uiScale
                previewWidthPercent: Plasmoid.configuration.taskPreviewWidthPercent
                previewHeightPercent: Plasmoid.configuration.taskPreviewHeightPercent
                onPinToggleRequested: launcherUrl => root.togglePinnedLauncher(launcherUrl)
            }

            Item {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
            }
            QQC2.AbstractButton {
                id: desktopButton
                Layout.preferredWidth: 24 * root.uiScale
                Layout.preferredHeight: root.controlHeight
                Accessible.name: Island.Cfg.t("SHOW DESKTOP")
                focusPolicy: Qt.TabFocus
                onClicked: KWindowSystem.KWindowSystem.showingDesktop = !KWindowSystem.KWindowSystem.showingDesktop
                background: Rectangle { radius: 12; color: desktopButton.hovered ? Island.Theme.surfaceHigh : "transparent" }
                contentItem: Text {
                    text: "desktop_windows"
                    font.family: Island.Theme.fontIcons
                    font.pixelSize: 17 * root.uiScale
                    color: KWindowSystem.KWindowSystem.showingDesktop ? Island.Theme.fg : Island.Theme.fgDim
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    Components.NothingPopupWindow {
        id: launcherPopup
        popupParent: root
        objectName: "nothingBottomLauncherExtension"
        anchorItem: panelSurface
        panelLocation: PlasmaCore.Types.BottomEdge
        popupWidth: Math.max(Math.round(root.width), root.launcherMinimumWidth)
        popupHeight: root.launcherHeight
        accentColor: root.accentColor
        surfaceOpacity: root.popupSurfaceOpacity
        blurEnabled: Plasmoid.configuration.glassBlur
        islandStyle: true
        pageComponent: Component {
            Components.LauncherPage {
                anchors.fill: parent
                uiScale: root.popupUiScale
                active: launcherPopup.visible
                appsModel: root.allAppsModel
                runnerModel: searchRunner
                hiddenApps: Plasmoid.configuration.hiddenApplications
                tasksModel: taskSourceModel
                accentColor: root.accentColor
                onLaunched: launcherPopup.closePopup()
                onPinRequested: launcherUrl => root.togglePinnedLauncher(launcherUrl)
                onSettingsRequested: root.openLauncherSettings()
                onSystemSettingsRequested: {
                    launcherPopup.closePopup()
                    KCMUtils.KCMLauncher.openSystemSettings("")
                }
            }
        }
    }
    Components.NothingPopupWindow {
        id: launcherSettingsPopup
        popupParent: root
        objectName: "nothingBottomLauncherSettingsExtension"
        anchorItem: panelSurface
        panelLocation: PlasmaCore.Types.BottomEdge
        popupWidth: Math.max(Math.round(root.width), root.launcherMinimumWidth)
        popupHeight: Math.min(root.popupHeightLimit, Math.round(560 * root.popupUiScale))
        accentColor: root.accentColor
        surfaceOpacity: root.popupSurfaceOpacity
        blurEnabled: Plasmoid.configuration.glassBlur
        islandStyle: true
        pageComponent: Component {
            Components.LauncherSettingsPage {
                anchors.fill: parent
                uiScale: root.popupUiScale
                accentColor: root.accentColor
                appsModel: root.allAppsModel
                panelConfig: Plasmoid.configuration
                shortcutController: root.appletItem
                onBackRequested: root.returnToLauncher()
            }
        }
    }

}
