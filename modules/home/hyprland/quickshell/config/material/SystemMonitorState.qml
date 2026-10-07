pragma Singleton

import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property var processes: []

    function refresh() {
        root._processProc.running = true;
    }

    function killProcess(pid) {
        let processId = parseInt(pid);
        if (isNaN(processId) || processId <= 0) return;

        root._killProc.command = ["kill", String(processId)];
        root._killProc.running = true;
    }

    readonly property var _processProc: Process {
        command: ["bash", "-c", "ps -eo pid=,comm=,pcpu=,pmem= --sort=-pcpu | head -n 80"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                let rows = [];
                let lines = this.text.trim().split("\n");

                for (let i = 0; i < lines.length; i++) {
                    let parts = lines[i].trim().split(/\s+/);
                    if (parts.length < 4) continue;

                    rows.push({
                        pid: parseInt(parts[0]),
                        name: parts[1],
                        cpu: parseFloat(parts[2]).toFixed(1),
                        mem: parseFloat(parts[3]).toFixed(1)
                    });
                }

                root.processes = rows;
            }
        }
    }

    readonly property var _killProc: Process {
        command: ["true"]
        running: false
        onExited: root.refresh()
    }

    readonly property var _pollTimer: Timer {
        interval: 2000
        running: SystemMonitorPopupState.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
