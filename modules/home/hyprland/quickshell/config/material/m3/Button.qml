import QtQuick
import ".."

// M3 Expressive common button with shape morphing.
// variant: "filled" | "tonal" | "outlined" | "text" | "error"
// Inside a connected button group set `grouped` and mark the ends with groupStart / groupEnd.
Rectangle {
    id: button

    property string text: ""
    property string icon: ""
    property string variant: "filled"
    property bool toggle: false
    property bool checked: false
    property bool grouped: false
    property bool groupStart: false
    property bool groupEnd: false
    property int size: 40
    property int iconSize: size >= 56 ? 22 : 18
    property int labelSize: size >= 56 ? Theme.typeTitle : Theme.typeBody + 1
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
        case "filled": return toggle && !checked ? Theme.textOnSurfaceVariant : Theme.textOnPrimary;
        case "tonal": return selected ? Theme.textOnSecondary : Theme.textOnSecondaryContainer;
        case "error": return selected ? Theme.textOnError : Theme.textOnErrorContainer;
        case "outlined": return selected ? Theme.inverseOnSurface : Theme.textOnSurfaceVariant;
        default: return Theme.primary;
        }
    }

    readonly property real fullRadius: height / 2
    readonly property real outerRadius: pressed ? (size >= 56 ? Theme.shapeM : Theme.shapeS)
        : selected && !grouped ? (size >= 56 ? Theme.shapeL : Theme.shapeM)
        : fullRadius
    readonly property real innerRadius: !grouped ? outerRadius
        : selected ? fullRadius
        : pressed ? Theme.shapeXS : Theme.shapeS

    implicitHeight: size
    implicitWidth: content.implicitWidth + (size >= 56 ? 48 : 32)

    color: containerColor
    border.width: variant === "outlined" && !selected ? 1 : 0
    border.color: Theme.outlineVariant
    topLeftRadius: !grouped || groupStart ? outerRadius : innerRadius
    bottomLeftRadius: !grouped || groupStart ? outerRadius : innerRadius
    topRightRadius: !grouped || groupEnd ? outerRadius : innerRadius
    bottomRightRadius: !grouped || groupEnd ? outerRadius : innerRadius

    Behavior on color { ColorEffect {} }
    Behavior on topLeftRadius { Spring {} }
    Behavior on bottomLeftRadius { Spring {} }
    Behavior on topRightRadius { Spring {} }
    Behavior on bottomRightRadius { Spring {} }

    StateLayer {
        tint: button.contentColor
        hovered: button.hovered
        pressed: button.pressed
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 8

        Icon {
            visible: button.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            icon: button.icon
            size: button.iconSize
            color: button.contentColor
        }

        Label {
            visible: button.text !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: button.text
            color: button.contentColor
            font.pixelSize: button.labelSize
            font.weight: Font.Bold
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}
