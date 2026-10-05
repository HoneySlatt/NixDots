import QtQuick
import ".."

// M3 Expressive icon button: round at rest, squarer when selected or pressed.
// variant: "standard" | "filled" | "tonal" | "outlined" | "error"
Rectangle {
    id: button

    property string icon: ""
    property string variant: "standard"
    property bool toggle: false
    property bool checked: false
    property int size: 40
    property int iconSize: Math.round(size * 0.5)
    signal clicked()

    readonly property bool hovered: mouse.containsMouse
    readonly property bool pressed: mouse.pressed
    readonly property bool selected: toggle && checked

    readonly property color containerColor: {
        switch (variant) {
        case "filled": return toggle && !checked ? Theme.surfaceContainerHighest : Theme.primary;
        case "tonal": return selected ? Theme.secondary : Theme.secondaryContainer;
        case "error": return selected ? Theme.error : Theme.errorContainer;
        case "outlined": return selected ? Theme.inverseSurface : "transparent";
        default: return "transparent";
        }
    }

    readonly property color contentColor: {
        switch (variant) {
        case "filled": return toggle && !checked ? Theme.primary : Theme.textOnPrimary;
        case "tonal": return selected ? Theme.textOnSecondary : Theme.textOnSecondaryContainer;
        case "error": return selected ? Theme.textOnError : Theme.textOnErrorContainer;
        case "outlined": return selected ? Theme.inverseOnSurface : Theme.textOnSurfaceVariant;
        default: return selected ? Theme.primary : Theme.textOnSurfaceVariant;
        }
    }

    implicitWidth: size
    implicitHeight: size
    radius: pressed ? height * 0.22 : selected ? height * 0.3 : height / 2
    color: containerColor
    border.width: variant === "outlined" && !selected ? 1 : 0
    border.color: Theme.outlineVariant

    Behavior on radius { Spring {} }
    Behavior on color { ColorEffect {} }

    StateLayer {
        tint: button.contentColor
        hovered: button.hovered
        pressed: button.pressed
    }

    Icon {
        anchors.centerIn: parent
        icon: button.icon
        size: button.iconSize
        color: button.contentColor
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}
