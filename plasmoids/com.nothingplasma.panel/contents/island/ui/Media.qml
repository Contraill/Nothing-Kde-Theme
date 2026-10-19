pragma Singleton
import QtQuick
import org.kde.plasma.private.mpris as Mpris
import org.kde.taskmanager as TaskManager
import "."

// One MPRIS selection shared by the compact mini player and the media card.
QtObject {
    id: root
    readonly property Mpris.Mpris2Model model: Mpris.Mpris2Model {}
    readonly property var player: Backend.preview ? null : model.currentPlayer

    readonly property Instantiator rows: Instantiator {
        model: root.model
        delegate: QtObject {
            required property var model
            required property int index
            readonly property bool multiplexer: model.isMultiplexer === true
            // playerctld re-exports whichever player is active; it is not a player itself.
            readonly property bool proxy: model.container?.objectName === "playerctld"
            readonly property string identity: model.identity ?? ""
            readonly property string icon: model.desktopEntry || model.iconName || ""
            readonly property int pid: model.container?.instancePid ?? 0
        }
    }
    // Real players; row 0 is Plasma's "follow the active player" multiplexer.
    readonly property var players: {
        const list = [];
        for (let i = 0; i < rows.count; ++i)
            list.push(rows.objectAt(i));
        return list.filter(row => row && !row.multiplexer && !row.proxy);
    }
    readonly property int currentIndex: model.currentIndex

    // The cover. Players that send none (a browser playing YouTube) get the
    // video's thumbnail, from the address the player reports over MPRIS,
    // which Plasma's model does not pass on.
    readonly property string track: player?.track ?? ""
    property string thumbnail: ""
    readonly property string artUrl: (player?.artUrl ?? "") || thumbnail
    onTrackChanged: { thumbnail = ""; lookUp.restart(); }
    // The address lands a moment after the title.
    readonly property Timer lookUp: Timer {
        interval: 700
        onTriggered: root.findThumbnail()
    }
    function findThumbnail() {
        const title = root.track;
        if (Backend.preview || !title || (root.player?.artUrl ?? "")) return;
        Exec.run("t=" + Exec.quote(title) + "; q=$(command -v qdbus6 || command -v qdbus) || exit 0; "
            + "for s in $($q | grep -o 'org\\.mpris\\.MediaPlayer2\\.[^ ]*'); do "
            + "m=$($q \"$s\" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Metadata 2>/dev/null) || continue; "
            + "printf '%s\\n' \"$m\" | grep -qxF \"xesam:title: $t\" && { printf '%s\\n' \"$m\" | grep '^xesam:url: '; exit 0; }; done",
            result => {
                if (title !== root.track) return;
                const id = (String(result.stdout ?? "").match(/(?:youtube\.com\/(?:watch\?(?:\S*&)?v=|shorts\/|embed\/)|youtu\.be\/)([\w-]{11})/) ?? [])[1];
                root.thumbnail = id ? "https://i.ytimg.com/vi/" + id + "/mqdefault.jpg" : "";
            });
    }
    // The player actually being controlled, also while following the active one.
    function controls(row) {
        return !!row && !!root.player && row.pid === (root.player.instancePid ?? -1);
    }

    function select(index) {
        if (!Backend.preview) root.model.currentIndex = index;
    }
    // Wayland lets no player bring its own window forward, so its window is
    // activated here, found by process or, for a browser's integration
    // (its own helper process), by application; Raise() still picks the tab.
    readonly property TaskManager.TasksModel tasks: TaskManager.TasksModel {
        groupMode: TaskManager.TasksModel.GroupDisabled
    }
    function raise() {
        if (Backend.preview || !root.player?.canRaise) return;
        root.player.Raise();
        const find = (role, value) => {
            for (let i = 0; i < root.tasks.count; ++i)
                if (root.tasks.data(root.tasks.index(i, 0), role) === value) return root.tasks.index(i, 0);
            return null;
        };
        const pid = root.player.instancePid ?? 0, app = root.player.desktopEntry ?? "";
        // shortcut: a player with several windows gets its first, until MPRIS says which.
        const task = (pid > 0 && find(TaskManager.AbstractTasksModel.AppPid, pid))
            || (app && find(TaskManager.AbstractTasksModel.AppId, app));
        if (task) root.tasks.requestActivate(task);
        Backend.dismissRequested();
    }
    function toggleShuffle() {
        const p = root.player;
        if (p && p.shuffle !== Mpris.ShuffleStatus.Unknown)
            p.shuffle = p.shuffle === Mpris.ShuffleStatus.On ? Mpris.ShuffleStatus.Off : Mpris.ShuffleStatus.On;
    }
    // None → whole playlist → current track → None, as in Plasma's media applet.
    function cycleLoop() {
        const p = root.player;
        if (!p || p.loopStatus === Mpris.LoopStatus.Unknown) return;
        p.loopStatus = p.loopStatus === Mpris.LoopStatus.None ? Mpris.LoopStatus.Playlist
            : p.loopStatus === Mpris.LoopStatus.Playlist ? Mpris.LoopStatus.Track : Mpris.LoopStatus.None;
    }
}
