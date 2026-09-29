pragma ComponentBehavior: Bound
import QtQuick
import QtQml.Models
import org.kde.plasma.private.kicker as Kicker

QtObject {
    id: root
    property string launcherUrl: ""
    property var actions: []
    readonly property string desktopId: launcherUrl.startsWith("applications:") ? launcherUrl.slice(13)
        : launcherUrl.startsWith("file://") ? decodeURIComponent(launcherUrl.slice(7)) : launcherUrl
    // Resolve exactly this desktop file through KDE. Keep KServiceAction variants
    // intact and let Kicker/KIO execute them, including arguments and activation.
    readonly property Kicker.SimpleFavoritesModel source: Kicker.SimpleFavoritesModel {
        favorites: root.desktopId ? [root.desktopId] : []
    }
    readonly property Instantiator entry: Instantiator {
        model: root.source
        onObjectAdded: (index, object) => root.actions = Qt.binding(() => object.actions)
        onObjectRemoved: root.actions = []
        delegate: QtObject {
            required property var actionList
            readonly property var actions: actionList.filter(action => action.actionId === "_kicker_jumpListAction")
        }
    }
    function trigger(action) { return source.trigger(0, action.actionId, action.actionArgument); }
    function refresh() { source.refresh(); }
}
