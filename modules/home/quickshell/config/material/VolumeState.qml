pragma Singleton

import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property int volume: 0
    property bool muted: false
    property var sinks: []
    property var appStreams: []
    property bool popupVisible: false

    function volUp() { root._volUpProc.running = true; }
    function volDown() { root._volDownProc.running = true; }
    function toggleMute() { root._muteProc.running = true; }
    function setVolume(percent) {
        root._setVolProc.command = ["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", (Math.max(0, Math.min(100, percent)) / 100).toFixed(2)];
        root._setVolProc.running = true;
    }

    readonly property var _volumeProc: Process {
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                let line = this.text.trim();
                root.muted = line.includes("[MUTED]");
                let match = line.match(/Volume:\s+([\d.]+)/);
                if (match) {
                    root.volume = Math.round(parseFloat(match[1]) * 100);
                }
            }
        }
    }

    readonly property var _volUpProc: Process {
        command: ["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", "5%+"]
        running: false
        onExited: root._volumeProc.running = true
    }

    readonly property var _volDownProc: Process {
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"]
        running: false
        onExited: root._volumeProc.running = true
    }

    readonly property var _muteProc: Process {
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        running: false
        onExited: root._volumeProc.running = true
    }

    readonly property var _setVolProc: Process {
        running: false
        onExited: root._volumeProc.running = true
    }

    function setDefaultSink(sinkId) {
        root._setDefaultSinkProc.command = ["wpctl", "set-default", sinkId];
        root._setDefaultSinkProc.running = true;
    }

    function refreshSinks() {
        root._sinksProc.running = true;
    }

    function refreshAppStreams() {
        root._appStreamsProc.running = true;
    }

    function setAppVolume(streamId, percent) {
        root._setAppVolProc.command = ["wpctl", "set-volume", "-l", "1.0", streamId, (Math.max(0, Math.min(100, percent)) / 100).toFixed(2)];
        root._setAppVolProc.running = true;
    }

    function toggleAppMute(streamId) {
        root._toggleAppMuteProc.command = ["wpctl", "set-mute", streamId, "toggle"];
        root._toggleAppMuteProc.running = true;
    }

    readonly property var _sinksProc: Process {
        command: ["sh", "-c", "wpctl status | awk '/^Audio/{a=1} a && /Sinks:/{b=1; next} a && b && /[0-9]+\\./{isdef=($0~/\\*/?\"1\":\"0\"); match($0,/[0-9]+\\./); nid=substr($0,RSTART,RLENGTH-1); rest=substr($0,RSTART+RLENGTH); gsub(/ \\[vol:.*/,\"\",rest); gsub(/^[ \\t]+|[ \\t]+$/,\"\",rest); print nid \"\\t\" isdef \"\\t\" rest} a && b && /Sources:/{exit}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n").filter(l => l.trim() !== "");
                root.sinks = lines.map(l => {
                    let parts = l.split("\t");
                    return { sinkId: parts[0] || "", active: parts[1] === "1", label: parts[2] || "" };
                }).filter(s => s.label !== "");
            }
        }
    }

    readonly property var _setDefaultSinkProc: Process {
        running: false
        onExited: {
            root.refreshSinks();
            root._volumeProc.running = true;
        }
    }

    readonly property var _appStreamsProc: Process {
        command: ["bash", "-c", "wpctl status | awk '/^Audio/{a=1} a && /Streams:/{s=1; next} s && /^Video/{exit} s && /^[[:space:]]+[0-9]+\\./ && $0 !~ />/ { match($0,/[0-9]+\\./); id=substr($0,RSTART,RLENGTH-1); label=substr($0,RSTART+RLENGTH); gsub(/^[ \\t]+|[ \\t]+$/,\"\",label); if (label != \"\") print id \"\\t\" label }' | while IFS=$'\\t' read -r id label; do line=$(wpctl get-volume \"$id\" 2>/dev/null); muted=0; case \"$line\" in *MUTED*) muted=1;; esac; vol=$(printf '%s\\n' \"$line\" | sed -n 's/.*Volume:[[:space:]]*\\([0-9.]*\\).*/\\1/p'); [ -z \"$vol\" ] && vol=0; pct=$(awk -v v=\"$vol\" 'BEGIN { printf \"%d\", v * 100 }'); printf '%s\\t%s\\t%s\\t%s\\n' \"$id\" \"$label\" \"$pct\" \"$muted\"; done"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n").filter(l => l.trim() !== "");
                root.appStreams = lines.map(l => {
                    let parts = l.split("\t");
                    return {
                        streamId: parts[0] || "",
                        label: parts[1] || "",
                        volume: Math.max(0, Math.min(100, parseInt(parts[2]) || 0)),
                        muted: parts[3] === "1"
                    };
                }).filter(s => s.streamId !== "" && s.label !== "");
            }
        }
    }

    readonly property var _setAppVolProc: Process {
        running: false
    }

    readonly property var _toggleAppMuteProc: Process {
        running: false
    }

    readonly property var _startupTimer: Timer {
        interval: 2000
        running: true
        repeat: false
        onTriggered: root._volumeProc.running = true
    }

    readonly property var _pollTimer: Timer {
        interval: 500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root._volumeProc.running = true;
            if (!root.popupVisible) root.refreshAppStreams();
        }
    }
}
