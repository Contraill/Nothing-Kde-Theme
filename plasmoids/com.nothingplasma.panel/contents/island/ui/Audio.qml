pragma Singleton
import QtQuick
import org.kde.plasma.private.volume as PA
import "."

// Plasma's own PulseAudio bindings: devices notify changes, nothing is polled.
QtObject {
    id: root
    // PulseAudio's 100 % (PA_VOLUME_NORM).
    readonly property real normalVolume: 65536
    readonly property PA.GlobalConfig config: PA.GlobalConfig {}
    readonly property PA.SinkModel sinkModel: PA.SinkModel {}
    readonly property PA.SourceModel sourceModel: PA.SourceModel {}

    readonly property var sink: Backend.preview ? null : PA.PreferredDevice.sink
    readonly property var source: Backend.preview ? null : PA.PreferredDevice.source

    readonly property real maxVolume: config.raiseMaximumVolume ? 1.5 : 1.0
    readonly property real volume: sink ? sink.volume / normalVolume : 0
    readonly property bool muted: sink?.muted ?? false
    readonly property int percent: Math.round(volume * 100)
    readonly property bool boosted: volume > 1
    readonly property string description: sink?.description ?? ""

    readonly property bool inputAvailable: source !== null
    readonly property real inputVolume: source ? source.volume / normalVolume : 0
    readonly property bool inputMuted: source?.muted ?? false
    readonly property int inputPercent: Math.round(inputVolume * 100)

    property real wheelRemainder: 0

    // Applications recording right now. Plasma's own level meters are virtual
    // streams and are not listed; paused (corked) streams do not count.
    readonly property PA.SourceOutputModel recordings: PA.SourceOutputModel {}
    readonly property Instantiator recordingRows: Instantiator {
        model: root.recordings
        delegate: QtObject {
            required property var model
            readonly property bool live: !model.VirtualStream && !model.Corked
            readonly property string client: model.Client?.name || model.Name || ""
        }
    }
    readonly property var recordingApps: {
        const list = [];
        for (let i = 0; i < recordingRows.count; ++i)
            list.push(recordingRows.objectAt(i));
        return list.filter(row => row && row.live).map(row => row.client).filter((name, index, all) => all.indexOf(name) === index);
    }
    readonly property bool microphoneInUse: !Backend.preview && recordingApps.length > 0

    function writeVolume(device, value) {
        if (!device || !device.volumeWritable) return;
        const v = Math.max(0, Math.min(root.maxVolume, value));
        device.volume = Math.round(v * root.normalVolume);
        // Like Plasma's applet: choosing a level is an explicit request to hear it.
        if (v > 0 && device.muted) device.muted = false;
    }
    function setVolume(v) { root.writeVolume(root.sink, v); }
    function setInputVolume(v) { root.writeVolume(root.source, v); }
    function step(direction) {
        const stepSize = (root.config.volumeStep > 0 ? root.config.volumeStep : 5) / 100;
        root.setVolume(Math.round((root.volume + direction * stepSize) / stepSize) * stepSize);
    }
    // Touchpads deliver many small deltas; one notch (120) is one step.
    function wheel(event) {
        root.wheelRemainder += event.angleDelta.y;
        while (Math.abs(root.wheelRemainder) >= 120) {
            const direction = root.wheelRemainder > 0 ? 1 : -1;
            root.wheelRemainder -= direction * 120;
            root.step(direction);
        }
    }
    function toggleMute() { if (root.sink) root.sink.muted = !root.sink.muted; }
    function toggleInputMute() { if (root.source) root.source.muted = !root.source.muted; }
    function setDefault(device) { if (device && !Backend.preview) device.default = true; }
}
