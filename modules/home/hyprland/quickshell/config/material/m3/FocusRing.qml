import QtQuick
import ".."

// M3 keyboard focus indicator drawn around its parent's shape.
Rectangle {
    id: ring

    property bool shown: false
    property real offset: 3
    readonly property real thickness: 3
    readonly property real grow: offset + thickness

    function cornerOf(value) {
        return (value === undefined || isNaN(value) ? 0 : value) + grow;
    }

    anchors.fill: parent
    anchors.margins: -grow
    topLeftRadius: cornerOf(parent.topLeftRadius)
    topRightRadius: cornerOf(parent.topRightRadius)
    bottomLeftRadius: cornerOf(parent.bottomLeftRadius)
    bottomRightRadius: cornerOf(parent.bottomRightRadius)
    color: "transparent"
    border.width: thickness
    border.color: Theme.secondary
    opacity: shown ? 1 : 0
    z: 10

    Behavior on opacity { Effect {} }
}
