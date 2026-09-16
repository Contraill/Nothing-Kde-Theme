pragma Singleton
import QtQuick
QtObject {
    id: root
    readonly property var controls: Backend.controls
    readonly property real maxVolume: 1.0
    readonly property real volume: (controls?.volume ?? 0) / 100
    readonly property bool muted: controls?.muted ?? false
    readonly property int percent: Math.round(volume * 100)
    readonly property bool boosted: false
    property bool holding: false
    property int watchers: 0
    readonly property string defaultSink: String(controls?.defaultAudioOutputId ?? -1)
    readonly property string defaultSource: String(controls?.defaultAudioInputId ?? -1)
    readonly property var sinks: (controls?.audioOutputs ?? []).map(d => ({name: String(d.id), description: d.name}))
    readonly property var sources: (controls?.audioInputs ?? []).map(d => ({name: String(d.id), description: d.name}))
    readonly property string description: sinks.find(d => d.name === defaultSink)?.description ?? ""
    function refreshDevices() { if (controls) controls.refreshAudio(); }
    function setVolume(v) { if (controls) controls.setOutputVolume(Math.max(0, Math.min(1, v)) * 100); }
    function step(delta) { setVolume(volume + delta); }
    function toggleMute() { if (controls) controls.toggleOutputMute(); }
    function setDefaultSink(name) { if (controls) controls.setDefaultAudioOutput(Number(name)); }
    function setDefaultSource(name) { if (controls) controls.setDefaultAudioInput(Number(name)); }
}
