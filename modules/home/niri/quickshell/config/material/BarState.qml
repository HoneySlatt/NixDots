pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool isTop: true
    readonly property string positionFile: "/home/honey/.config/quickshell/.bar-position"
    readonly property string niriModeFile: "/home/honey/.config/niri/bar-mode.kdl"

    readonly property string niriTopMode: "// Barre en haut : pas de surcharge."
    readonly property string niriCompactMode: "layout {\n    gaps 0\n    border {\n        off\n    }\n    shadow {\n        off\n    }\n}\nwindow-rule {\n    geometry-corner-radius 0\n    opacity 1.0\n}"

    function setPosition(position) {
        if (position === "top") isTop = true;
        else if (position === "bottom") isTop = false;
        else return;

        applyNiriMode();
    }

    function applyNiriMode() {
        Quickshell.execDetached([
            "sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s\\n' \"$2\" > \"$1\"",
            "sh", niriModeFile, isTop ? niriTopMode : niriCompactMode
        ]);
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
        onExited: exitCode => { if (exitCode !== 0) root.applyNiriMode(); }
    }

    readonly property var writer: Process {
        property string position: "top"
        command: ["sh", "-c", "mkdir -p '/home/honey/.config/quickshell' && printf '%s\\n' '" + position + "' > '" + root.positionFile + "'"]
        running: false
    }
}
