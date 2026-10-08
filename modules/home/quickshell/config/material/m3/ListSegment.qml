import QtQuick
import ".."

// M3 Expressive segmented list item: connected corners, fully rounded when selected.
Rectangle {
    id: segment

    property bool first: false
    property bool last: false
    property bool selected: false
    property bool rounded: false
    property bool interactive: true
    property real outerRadius: Theme.shapeLI
    property real innerRadius: Theme.shapeXS
    property color baseColor: Theme.surfaceContainerHigh
    property color selectedColor: Theme.secondaryContainer
    property alias hovered: mouse.containsMouse
    property alias pressed: mouse.pressed
    signal clicked()
    signal entered()

    readonly property real topRadius: selected || rounded || first ? outerRadius : innerRadius
    readonly property real bottomRadius: selected || rounded || last ? outerRadius : innerRadius

    color: selected ? selectedColor : baseColor
    topLeftRadius: topRadius
    topRightRadius: topRadius
    bottomLeftRadius: bottomRadius
    bottomRightRadius: bottomRadius

    Behavior on color { ColorEffect {} }
    Behavior on topLeftRadius { Spring {} }
    Behavior on topRightRadius { Spring {} }
    Behavior on bottomLeftRadius { Spring {} }
    Behavior on bottomRightRadius { Spring {} }

    StateLayer {
        visible: segment.interactive
        tint: segment.selected ? Theme.textOnSecondaryContainer : Theme.textOnSurface
        hovered: segment.hovered
        pressed: segment.pressed
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: segment.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: segment.entered()
        onClicked: segment.clicked()
    }
}
