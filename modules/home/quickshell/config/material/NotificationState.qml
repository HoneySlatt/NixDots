pragma Singleton

import QtQuick
import Quickshell.Io

// One swaync subscription shared by the bars of every screen
QtObject {
    id: root

    // U+F009A=notification, U+F009C=none, U+F009B=dnd-notification, U+F0A91=dnd-none
    property string icon: "\u{f009c}"

    readonly property var _proc: Process {
        command: ["swaync-client", "-swb"]
        running: true

        stdout: SplitParser {
            onRead: function(data) {
                try {
                    let json = JSON.parse(data);
                    let alt = json.alt || "none";

                    switch (alt) {
                        case "notification":
                        case "inhibited-notification":
                            root.icon = "\u{f009a}";
                            break;
                        case "dnd-notification":
                        case "dnd-inhibited-notification":
                            root.icon = "\u{f009b}";
                            break;
                        case "dnd-none":
                        case "dnd-inhibited-none":
                            root.icon = "\u{f0a91}";
                            break;
                        case "none":
                        case "inhibited-none":
                        default:
                            root.icon = "\u{f009c}";
                            break;
                    }
                } catch (e) {}
            }
        }
    }
}
