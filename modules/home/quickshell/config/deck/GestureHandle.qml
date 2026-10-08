import QtQuick
import Quickshell
import Quickshell.Wayland
import "../material"

Variants {
    model: Quickshell.screens

    PanelWindow {
        required property var modelData
        screen: modelData

        anchors { bottom: true; left: true; right: true }
        implicitHeight: 16
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.namespace: "quickshell:deck-handle"
        WlrLayershell.layer: WlrLayer.Top

        Rectangle {
            anchors.centerIn: parent
            width: 120
            height: 5
            radius: height / 2
            color: Theme.outline
            opacity: swipe.pressed ? 0.9 : 0.5
        }

        Swipe {
            id: swipe
            anchors.fill: parent
            onTapped: DeckState.niri(["toggle-overview"])
            onSwiped: direction => {
                if (direction === "up")
                    DeckState.toggleDrawer();
                else if (direction === "left")
                    DeckState.niri(["focus-column-right"]);
                else if (direction === "right")
                    DeckState.niri(["focus-column-left"]);
            }
        }
    }
}
