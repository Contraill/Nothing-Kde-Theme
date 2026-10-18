pragma ComponentBehavior: Bound

import QtQuick
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
    // Plasma expands every activated applet. In compact mode that paints the
    // blue active-tab frame over the dock and opens an empty popup that steals
    // focus from the real launcher, so stay in an inert full representation.
    fullRepresentation: Item {}
    preferredRepresentation: fullRepresentation

    // PlasmaShell emits activated() on the applet that advertises
    // org.kde.plasma.launchermenu. The owning bottom containment listens to
    // this applet directly; re-emitting activated() on the containment made
    // Plasma activate the panel window, which closed the launcher popup.
}
