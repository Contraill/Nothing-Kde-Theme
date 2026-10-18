pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import org.kde.taskmanager as TaskManager
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "components" as Components
import "../island/ui" as Island

Item {
    id: root
    required property ContainmentItem appletItem
    required property Components.PanelRoleMetrics metrics
    required property int shortcutEpoch
    property bool controlsReady: false
    readonly property color kdeAccent: Kirigami.Theme.highlightColor
    onKdeAccentChanged: if (controlsReady) accentSync.restart()
    // Reuse the existing debounced palette hook; no service or layout change.
    readonly property color kdeWindowColor: Kirigami.Theme.backgroundColor
    onKdeWindowColorChanged: if (controlsReady) accentSync.restart()
    Timer { id: accentSync; interval: 350; onTriggered: controls.syncAccentSchemeFiles() }
    readonly property bool autoWallpaper: Plasmoid.configuration.autoWallpaper
    readonly property bool lightMode: Plasmoid.configuration.appearanceMode === "light"
    readonly property real availableWidth: Screen.desktopAvailableWidth || Screen.width || 1920
    readonly property real availableHeight: Screen.desktopAvailableHeight || Screen.height || 1080
    implicitWidth: Math.min(Island.Theme.collapsedWidth + (tray.visible ? 2 * (tray.width + 12) : 0), root.availableWidth - 24)
    implicitHeight: 50
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    Binding { target: root.metrics; property: "requestedWidth"; value: root.implicitWidth }
    Binding { target: root.metrics; property: "requestedHeight"; value: 50 }
    Binding { target: Island.Backend; property: "controls"; value: controls }
    Binding { target: Island.Backend; property: "appletItem"; value: root.appletItem }
    Binding { target: Island.Backend; property: "stats"; value: stats }
    Binding { target: Island.Backend; property: "expanded"; value: popup.visible }
    Binding { target: Island.Cfg; property: "lang"; value: Plasmoid.configuration.islandLanguage }
    Binding { target: Island.Cfg; property: "showClock"; value: Plasmoid.configuration.showClock }
    Binding { target: Island.Weather; property: "panelConfig"; value: Plasmoid.configuration }
    Binding { target: Island.Cfg; property: "weatherCity"; value: Plasmoid.configuration.islandWeatherCity }
    Binding { target: Island.Cfg; property: "colorFondo"; value: root.lightMode ? "#EEEDE9" : "#000000" }
    Binding { target: Island.Cfg; property: "colorTarjeta"; value: root.lightMode ? "#E7E6E1" : "#0B0B0B" }
    Binding { target: Island.Cfg; property: "colorInvertida"; value: root.lightMode ? "#D0CFC8" : "#FFFFFF" }
    Binding { target: Island.Cfg; property: "colorTexto"; value: root.lightMode ? "#393A37" : "#FFFFFF" }

    Components.SystemControls { id: controls; autoWallpaper: Plasmoid.configuration.autoWallpaper }
    Component.onCompleted: { controlsReady = true; controls.retireLegacyInhibitors(); controls.syncLockWallpaper(); controls.initAccent(); Qt.callLater(() => controls.ensureTray()); }
    onLightModeChanged: if (controlsReady) Qt.callLater(() => controls.syncLockWallpaper())
    onAutoWallpaperChanged: if (controlsReady && autoWallpaper) Qt.callLater(() => controls.syncLockWallpaper())
    TaskManager.ActivityInfo { id: wallpaperActivity }
    Components.WallpaperSync {
        enabled: root.controlsReady && root.autoWallpaper
        mode: root.lightMode ? "light" : "dark"
        activity: wallpaperActivity.currentActivity
        onSynchronize: mode => controls.syncDesktopWallpaper(mode)
    }
    Binding { target: Island.Backend; property: "trayHost"; value: tray }
    Components.SystemStats { id: stats; active: popup.visible }
    Connections {
        target: Island.Backend
        function onDismissRequested() { popup.closePopup(); }
    }

    function toggleMenu(): void {
        if (popup.visible) popup.closePopup();
        else if (!popup.wasJustClosed()) popup.openPopup();
    }
    onShortcutEpochChanged: if (shortcutEpoch > 0) toggleMenu()

    MouseArea {
        id: anchor
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleMenu()
        Accessible.role: Accessible.Button
        Accessible.name: "Nothing Island"
        Accessible.onPressAction: root.toggleMenu()
        Island.CompactPill {
            id: compact
            anchors.fill: parent
            trayWidth: tray.visible ? tray.width : 0
            onWeatherSettingsRequested: { popup.openPopup(); island.openOverlay("weather"); }
        }
    }

    Components.TrayHost {
        id: tray
        containment: Plasmoid
        containmentItem: root.appletItem
        parent: compact.traySlot
        width: Math.min(240, implicitWidth)
        height: implicitHeight
        anchors.verticalCenter: parent.verticalCenter
        visible: Plasmoid.configuration.showSystemTray
    }

    // The working top bar's native Dialog placement and focus contract.
    // Use the imported surface directly without a second glass frame.
    PlasmaCore.Dialog {
        id: popup
        property double lastClosedAt: -10000
        visualParent: anchor
        location: PlasmaCore.Types.TopEdge
        type: PlasmaCore.Dialog.PopupMenu
        flags: Qt.Popup
        hideOnWindowDeactivate: true
        backgroundHints: PlasmaCore.Dialog.NoBackground
        visible: false
        function wasJustClosed(): bool { return Date.now() - lastClosedAt < 220; }
        function closePopup(): void { visible = false; }
        function openPopup(): void {
            island.closeOverlay();
            visible = true;
            Qt.callLater(function() { popup.requestActivate(); content.forceActiveFocus(); });
        }
        onVisibleChanged: if (!visible) { lastClosedAt = Date.now(); island.closeOverlay(); }
        mainItem: FocusScope {
            id: content
            width: Math.min(Island.Theme.expandedWidth, root.availableWidth - 24)
            height: Math.min(island.implicitHeight, root.availableHeight - root.height - 24)
            focus: true
            Keys.onEscapePressed: {
                if (island.overlay) island.closeOverlay();
                else popup.closePopup();
            }
            Flickable {
                anchors.fill: parent
                clip: true
                contentHeight: island.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                Island.ExpandedPanel { id: island; width: parent.width; height: implicitHeight }
            }
        }
    }
}
