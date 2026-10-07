pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool topPosition: true
    property bool material: false
    property bool styleReady: false
    // The material bar is always at the top
    readonly property bool isTop: material || topPosition
    readonly property string positionFile: "/home/honey/.config/quickshell/.bar-position"
    readonly property string styleFile: "/home/honey/.config/quickshell/.bar-style"
    readonly property string niriModeFile: "/home/honey/.config/niri/bar-mode.kdl"

    readonly property string niriTopMode: "// Barre en haut : pas de surcharge."
    readonly property string niriCompactMode: "layout {\n    gaps 0\n    border {\n        off\n    }\n    shadow {\n        off\n    }\n}\nwindow-rule {\n    geometry-corner-radius 0\n    opacity 1.0\n}"

    function setPosition(position) {
        if (position === "top") topPosition = true;
        else if (position === "bottom") topPosition = false;
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
        writer.position = topPosition ? "top" : "bottom";
        writer.running = true;
    }

    function togglePosition() {
        if (material) return;
        setPosition(topPosition ? "bottom" : "top");
        writePosition();
    }

    function toggleStyle() {
        material = !material;
        applyNiriMode();
        Quickshell.execDetached([
            "sh", "-c", "printf '%s\\n' \"$2\" > \"$1\"",
            "sh", styleFile, material ? "material" : "modern"
        ]);
    }

    readonly property var reader: Process {
        command: ["cat", root.positionFile]
        running: true
        stdout: SplitParser {
            onRead: data => root.setPosition(data.trim())
        }
        onExited: exitCode => { if (exitCode !== 0) root.applyNiriMode(); }
    }

    readonly property var styleReader: Process {
        command: ["cat", root.styleFile]
        running: true
        stdout: SplitParser {
            onRead: data => root.material = data.trim() === "material"
        }
        onExited: {
            if (root.material) root.applyNiriMode();
            root.styleReady = true;
        }
    }

    readonly property var writer: Process {
        property string position: "top"
        command: ["sh", "-c", "mkdir -p '/home/honey/.config/quickshell' && printf '%s\\n' '" + position + "' > '" + root.positionFile + "'"]
        running: false
    }
}
