pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Live PipeWire state: no polling, values update as soon as PipeWire reports a change.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property int volume: Math.round((sink?.audio?.volume ?? 0) * 100)
    readonly property bool muted: sink?.audio?.muted ?? false

    readonly property var _audioNodes: Pipewire.nodes.values.filter(n => n.audio).sort((a, b) => a.id - b.id)

    // Same entries as the Sinks and Streams sections of `wpctl status`
    readonly property var sinks: _audioNodes
        .filter(n => n.isSink && !n.isStream)
        .map(n => ({ sinkId: String(n.id), active: n === sink, label: n.description }))
    readonly property var appStreams: _audioNodes
        .filter(n => n.isStream && !(n.properties["media.class"] ?? "").includes("Internal"))
        .map(n => ({
            streamId: String(n.id),
            label: n.name,
            volume: Math.max(0, Math.min(100, Math.round(n.audio.volume * 100))),
            muted: n.audio.muted
        }))
        .filter(s => s.label !== "")

    PwObjectTracker { objects: Pipewire.nodes.values }

    function _node(id) {
        return Pipewire.nodes.values.find(n => String(n.id) === id) ?? null;
    }

    function setVolume(percent) {
        if (sink?.audio) sink.audio.volume = Math.max(0, Math.min(100, percent)) / 100;
    }
    function volUp() { setVolume(volume + 5); }
    function volDown() { setVolume(volume - 5); }
    function toggleMute() {
        if (sink?.audio) sink.audio.muted = !sink.audio.muted;
    }

    function setDefaultSink(sinkId) {
        const node = _node(sinkId);
        if (node) Pipewire.preferredDefaultAudioSink = node;
    }

    function setAppVolume(streamId, percent) {
        const node = _node(streamId);
        if (node?.audio) node.audio.volume = Math.max(0, Math.min(100, percent)) / 100;
    }
    function toggleAppMute(streamId) {
        const node = _node(streamId);
        if (node?.audio) node.audio.muted = !node.audio.muted;
    }
}
