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
        // Two or more notifications from one application share a header row.
        groupMode: NM.Notifications.GroupApplicationsFlat
    }

    readonly property int count: model.count
    readonly property int notificationCount: {
        let n = 0;
        for (let row = 0; row < model.count; ++row)
            if (!root.at(row, NM.Notifications.IsGroupRole)) ++n;
        return n;
    }
    property var current: null
    // Bumped every minute while the list is visible so relative times stay fresh.
    property int clock: 0

    function at(row, role) {
        return root.model.data(root.model.index(row, 0), role);
    }

    readonly property Connections watch: Connections {
        target: root.model

        function onRowsInserted(parent, first, last) {
            if (root.muted)
                return;
            // Grouping inserts a header row alongside the notification itself.
            for (let row = last; row >= first; --row) {
                if (root.at(row, NM.Notifications.IsGroupRole))
                    continue;
                root.current = {
                    summary: root.at(row, NM.Notifications.SummaryRole) ?? "",
                    body: root.at(row, NM.Notifications.BodyRole) ?? "",
                    icon: root.at(row, NM.Notifications.ApplicationIconNameRole) ?? ""
                };
                root.popupTimer.restart();
                return;
            }
        }
    }

    readonly property Timer popupTimer: Timer {
        interval: 5000
        onTriggered: root.current = null
    }

    function timeText(date) {
        const update = root.clock;
        const time = date instanceof Date ? date.getTime() : NaN;
        if (isNaN(time)) return "";
        const minutes = Math.floor((Date.now() - time) / 60000);
        if (minutes < 1) return Cfg.t("NOW");
        if (minutes < 60) return minutes + " " + Cfg.t("MIN");
        const then = new Date(time), now = new Date();
        if (then.toDateString() === now.toDateString())
            return Qt.formatTime(then, Cfg.fmtHoraCorta);
        return Qt.formatDate(then, "dd.MM");
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
    // Opening a notification focuses its application, so the island steps aside.
    function activate(row) {
        if (Backend.preview || !root.at(row, NM.Notifications.HasDefaultActionRole)) return;
        root.model.invokeDefaultAction(root.model.index(row, 0), NM.Notifications.Close);
        Backend.dismissRequested();
    }
    function invokeAction(row, name) {
        if (Backend.preview) return;
        root.model.invokeAction(root.model.index(row, 0), name, NM.Notifications.Close);
        Backend.dismissRequested();
    }
    function reply(row, text) {
        if (Backend.preview || !text) return;
        root.model.reply(root.model.index(row, 0), text, NM.Notifications.Close);
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
            // Like Plasma's own toggle: a year from now means "until turned off".
            const until = new Date();
            until.setFullYear(until.getFullYear() + 1);
            settings.notificationsInhibitedUntil = until;
        }
        settings.save();
        root.current = null;
    }
}
