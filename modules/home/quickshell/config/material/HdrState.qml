pragma Singleton

import QtQuick
import Quickshell.Io
import "services" as Services

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

    // niri has no HDR support to report
    readonly property var _timer: Timer {
        interval: 5000
        running: Services.Compositor.isHyprland
        repeat: true
        triggeredOnStart: true
        onTriggered: root._proc.running = true
    }
}
