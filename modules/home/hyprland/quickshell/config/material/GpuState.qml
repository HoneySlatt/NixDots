pragma Singleton

import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property int tempC: 0
    property string hwmonPath: ""
    property var history: []

    function _pushHistory(value) {
        let next = history.slice(-35);
        next.push(Math.max(0, Math.min(100, value)));
        history = next;
    }

    readonly property var _findProc: Process {
        command: ["bash", "-c", "for d in /sys/class/hwmon/hwmon*/; do if [ \"$(cat \"$d/name\" 2>/dev/null)\" = \"amdgpu\" ]; then echo \"${d}temp1_input\"; exit 0; fi; done"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                let path = this.text.trim();
                if (path.length > 0) {
                    root.hwmonPath = path;
                }
            }
        }
    }

    readonly property var _proc: Process {
        command: ["cat", root.hwmonPath]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                let val = parseInt(this.text.trim());
                if (!isNaN(val)) {
                    root.tempC = Math.round(val / 1000);
                    root._pushHistory(root.tempC);
                }
            }
        }
    }

    readonly property var _pollTimer: Timer {
        interval: 2000
        running: root.hwmonPath !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: root._proc.running = true
    }
}
