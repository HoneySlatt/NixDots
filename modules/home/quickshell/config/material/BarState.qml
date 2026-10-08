pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "services" as Services

QtObject {
    id: root

    property bool isTop: true
    readonly property string positionFile: Quickshell.env("HOME") + "/.config/quickshell/.bar-position"
    readonly property string niriModeFile: Quickshell.env("HOME") + "/.config/niri/bar-mode.kdl"

    readonly property string niriTopMode: "// Barre en haut : pas de surcharge."
    readonly property string niriCompactMode: "layout {\n    gaps 0\n    border {\n        off\n    }\n    shadow {\n        off\n    }\n}\nwindow-rule {\n    geometry-corner-radius 0\n    opacity 1.0\n}"
    readonly property string hyprlandTopMode: "hl.config({ general = { gaps_in = 6, gaps_out = 6, border_size = 2 }, decoration = { rounding = 12, active_opacity = 1.0, inactive_opacity = 0.9, shadow = { enabled = true } } })"
    readonly property string hyprlandCompactMode: "hl.config({ general = { gaps_in = 0, gaps_out = 0, border_size = 0 }, decoration = { rounding = 0, active_opacity = 1.0, inactive_opacity = 1.0, shadow = { enabled = false } } })"

    function setPosition(position) {
        if (position === "top") isTop = true;
        else if (position === "bottom") isTop = false;
        else return;

        applyMode();
    }

    function applyMode() {
        if (Services.Compositor.isHyprland) {
            Quickshell.execDetached(["hyprctl", "eval", isTop ? hyprlandTopMode : hyprlandCompactMode]);
            return;
        }
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
        onExited: exitCode => { if (exitCode !== 0) root.applyMode(); }
    }

    readonly property var writer: Process {
        property string position: "top"
        command: ["sh", "-c", "mkdir -p \"$HOME/.config/quickshell\" && printf '%s\\n' '" + position + "' > '" + root.positionFile + "'"]
        running: false
    }
}
