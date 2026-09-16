pragma ComponentBehavior: Bound

import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

// Plasma 6.7 Dialog is used deliberately here instead of QtQuick.Controls
// Popup.Window. Dialog owns the Wayland popup placement contract and positions
// itself from visualParent, so it is not constrained/repositioned by the tiny
// PanelView scene. Every menu still has its own Dialog instance and geometry.
PlasmaCore.Dialog {
    id: root

    required property Item anchorItem
    required property Item popupParent
    property int panelLocation: PlasmaCore.Types.TopEdge
    required property int popupWidth
    required property int popupHeight
    property color accentColor: Kirigami.Theme.highlightColor
    property real surfaceOpacity: 0.72
    property bool blurEnabled: true
    property bool islandStyle: false
    property Component pageComponent
    readonly property alias pageItem: pageLoader.item
    property double lastClosedAt: -10000
    property bool wasVisible: false

    visualParent: root.anchorItem
    // Follow the owning panel edge. Plasma positions the dialog on the inner
    // side of visualParent for top/bottom/left/right panels.
    location: root.panelLocation
    // PopupMenu avoids Dialog.AppletPopup's intentional screen-centering rule
    // for applets near the middle of a panel; we want the clicked button center.
    type: PlasmaCore.Dialog.PopupMenu
    hideOnWindowDeactivate: true
    flags: Qt.Popup
    backgroundHints: root.blurEnabled && !root.islandStyle
        ? PlasmaCore.Dialog.StandardBackground
        : PlasmaCore.Dialog.NoBackground
    visible: false

    function wasJustClosed(): bool {
        return Date.now() - root.lastClosedAt < 220
    }

    function focusPage(page: var): void {
        if (page && typeof page.focusDefault === "function") page.focusDefault()
    }

    function openPopup(): void {
        // Re-assign before every show so detail windows opened from tray items
        // inherit the current invoking anchor. Plasma computes the final global
        // geometry from visualParent; no manual x/y math is involved.
        root.visualParent = root.anchorItem
        root.visible = true
        root.wasVisible = true
        Qt.callLater(function() {
            if (!root.visible) return
            root.requestActivate()
            popupSurface.forceActiveFocus()
            root.focusPage(pageLoader.item)
        })
    }

    function closePopup(): void {
        if (root.visible) root.visible = false
    }

    onVisibleChanged: {
        if (!root.visible && root.wasVisible) {
            root.lastClosedAt = Date.now()
            root.wasVisible = false
        }
    }

    mainItem: PopupShell {
        id: popupSurface
        width: root.popupWidth
        height: root.popupHeight
        accentColor: root.accentColor
        surfaceOpacity: root.surfaceOpacity
        islandStyle: root.islandStyle
        Keys.onEscapePressed: root.closePopup()

        Loader {
            id: pageLoader
            anchors.fill: parent
            sourceComponent: root.pageComponent
        }
    }
}
