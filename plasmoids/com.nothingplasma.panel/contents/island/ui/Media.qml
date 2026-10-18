pragma Singleton
import QtQuick
import org.kde.plasma.private.mpris as Mpris
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
            readonly property string identity: model.identity ?? ""
            readonly property string icon: model.desktopEntry || model.iconName || ""
        }
    }
    // Real players; row 0 is Plasma's "follow the active player" multiplexer.
    readonly property var players: {
        const list = [];
        for (let i = 0; i < rows.count; ++i)
            list.push(rows.objectAt(i));
        return list.filter(row => row && !row.multiplexer);
    }
    readonly property int currentIndex: model.currentIndex

    function select(index) {
        if (!Backend.preview) root.model.currentIndex = index;
    }
    function raise() {
        if (Backend.preview || !root.player?.canRaise) return;
        root.player.Raise();
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
