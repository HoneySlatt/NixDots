import QtQuick
import ".."

// Hover / press overlay that follows the parent's shape.
Rectangle {
    property bool hovered: false
    property bool pressed: false
    property color tint: Theme.textOnSurface

    anchors.fill: parent
    topLeftRadius: parent.topLeftRadius
    topRightRadius: parent.topRightRadius
    bottomLeftRadius: parent.bottomLeftRadius
    bottomRightRadius: parent.bottomRightRadius
    color: tint
    opacity: pressed ? Theme.statePressed : hovered ? Theme.stateHover : 0

    Behavior on opacity { Effect {} }
}
