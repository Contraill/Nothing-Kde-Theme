pragma Singleton

import QtQuick
import "."
import org.kde.notificationmanager as NM
QtObject {
    id: root
    readonly property bool muted: NM.Server.inhibited
    readonly property NM.Settings settings: NM.Settings {}

    readonly property NM.Notifications model: NM.Notifications {
        showExpired: true
        showDismissed: true
        showJobs: false
        sortMode: NM.Notifications.SortByDate
        groupMode: NM.Notifications.GroupDisabled
    }

    readonly property int count: model.count
    property var current: null

    function at(row, role) {
        return root.model.data(root.model.index(row, 0), role);
    }

    readonly property Connections watch: Connections {
        target: root.model

        function onRowsInserted(parent, first) {
            if (root.muted)
                return;
            root.current = {
                summary: root.at(first, NM.Notifications.SummaryRole) ?? "",
                body: root.at(first, NM.Notifications.BodyRole) ?? "",
                icon: root.at(first, NM.Notifications.ApplicationIconNameRole) ?? ""
            };
            root.popupTimer.restart();
        }
    }

    readonly property Timer popupTimer: Timer {
        interval: 5000
        onTriggered: root.current = null
    }

    function dismissAt(row) {
        if (Backend.preview) return;
        root.model.close(root.model.index(row, 0));
    }
    function clearAll() {
        if (Backend.preview) return;
        for (var i = root.model.count - 1; i >= 0; i--)
            root.model.close(root.model.index(i, 0));
        root.current = null;
    }

    function toggleMute() {
        if (Backend.preview) return;
        // The native notifications widget owns Server.inhibited. Update its
        // settings instead of breaking its binding with a direct assignment.
        if (root.muted) {
            settings.notificationsInhibitedUntil = undefined;
            settings.revokeApplicationInhibitions();
            settings.fullscreenFocused = false;
            settings.screensMirrored = false;
        } else {
            settings.notificationsInhibitedUntil = new Date(Date.now() + 60 * 60 * 1000);
        }
        settings.save();
        root.current = null;
    }
}
