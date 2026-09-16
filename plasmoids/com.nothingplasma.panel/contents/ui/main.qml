pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "components" as Components

ContainmentItem {
    id: root

    readonly property string panelRole: {
        switch (Plasmoid.location) {
        case PlasmaCore.Types.BottomEdge: return "bottom"
        default: return "top"
        }
    }
    readonly property var globalShortcutSequence: Plasmoid.globalShortcut
    property int shortcutEpoch: 0

    function setGlobalShortcut(sequence): void {
        // This setter executes on the real root Containment/Applet attached
        // object, which is the object KGlobalAccel registers.
        Plasmoid.globalShortcut = sequence
    }

    Components.PanelRoleMetrics { id: roleMetrics }

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.icon: "applications-all-symbolic"

    // KGlobalAccel activates the real applet/containment. Never dispatch through
    // Loader.item: qmllint only knows that object as QObject. Instead increment
    // a typed epoch and bind it into the statically known role components.
    Plasmoid.onActivated: root.shortcutEpoch += 1

    implicitWidth: roleMetrics.requestedWidth
    implicitHeight: roleMetrics.requestedHeight

    Layout.minimumWidth: 1
    Layout.preferredWidth: root.implicitWidth
    Layout.maximumWidth: 10000
    Layout.minimumHeight: 36
    Layout.preferredHeight: root.implicitHeight
    Layout.maximumHeight: 72

    Component {
        id: topPanelComponent
        TopPanel { appletItem: root; metrics: roleMetrics; shortcutEpoch: root.shortcutEpoch }
    }

    Component {
        id: bottomPanelComponent
        BottomPanel { appletItem: root; metrics: roleMetrics; shortcutEpoch: root.shortcutEpoch }
    }

    Loader {
        id: roleLoader
        anchors.fill: parent
        sourceComponent: {
            switch (root.panelRole) {
            case "bottom": return bottomPanelComponent
            default: return topPanelComponent
            }
        }
    }
}
