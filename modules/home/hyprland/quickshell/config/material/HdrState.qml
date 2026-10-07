pragma Singleton

import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool enabled: false

    readonly property var _proc: Process {
        command: ["hyprctl", "monitors"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.enabled = this.text.includes("colorManagementPreset: hdr");
            }
        }
    }

    readonly property var _timer: Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root._proc.running = true
    }
}
