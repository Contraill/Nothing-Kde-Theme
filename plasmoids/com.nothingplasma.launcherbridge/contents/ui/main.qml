pragma ComponentBehavior: Bound

import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    // This applet exists only so PlasmaShell can discover a native launcher
    // provider for the modifier-only Meta/Start key. It is intentionally
    // invisible and occupies no useful panel space.
    visible: false
    implicitWidth: 0
    implicitHeight: 0
    Layout.minimumWidth: 0
    Layout.preferredWidth: 0
    Layout.maximumWidth: 0
    Layout.minimumHeight: 0
    Layout.preferredHeight: 0
    Layout.maximumHeight: 0
    Plasmoid.status: PlasmaCore.Types.HiddenStatus

    // PlasmaShell emits activated() on the applet that advertises
    // org.kde.plasma.launchermenu. Relay that same activation to the owning
    // bottom containment, whose root already owns all launcher dispatch.
    Plasmoid.onActivated: {
        if (Plasmoid.containment) Plasmoid.containment.activated()
    }
}
