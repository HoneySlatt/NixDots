pragma Singleton

import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool isTop: true
    readonly property string positionFile: "/home/honey/.config/quickshell/.bar-position"

    function setPosition(position) {
        if (position === "top") isTop = true;
        else if (position === "bottom") isTop = false;
        else return;

        hyprlandSettings.command = [
            "hyprctl",
            "eval",
            isTop
                ? "hl.config({ general = { gaps_in = 6, gaps_out = 6, border_size = 2 }, decoration = { rounding = 12, active_opacity = 1.0, inactive_opacity = 0.9, shadow = { enabled = true } } })"
                : "hl.config({ general = { gaps_in = 0, gaps_out = 0, border_size = 0 }, decoration = { rounding = 0, active_opacity = 1.0, inactive_opacity = 1.0, shadow = { enabled = false } } })"
        ];
        hyprlandSettings.running = true;
    }

    function writePosition() {
        writer.position = isTop ? "top" : "bottom";
        writer.running = true;
    }

    function togglePosition() {
        setPosition(isTop ? "bottom" : "top");
        writePosition();
    }

    readonly property var reader: Process {
        command: ["cat", root.positionFile]
        running: true
        stdout: SplitParser {
            onRead: data => root.setPosition(data.trim())
        }
    }

    readonly property var writer: Process {
        property string position: "top"
        command: ["sh", "-c", "mkdir -p '/home/honey/.config/quickshell' && printf '%s\\n' '" + position + "' > '" + root.positionFile + "'"]
        running: false
    }

    readonly property var hyprlandSettings: Process {
        running: false
    }
}
