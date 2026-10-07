import QtQuick
import QtQuick.Effects
import ".."

// Elevated popup container with an expressive entrance.
Item {
    id: surface

    property color color: Theme.surfaceContainer
    property real radius: Theme.shapeXL
    // Square bottom corners, used when the popup is docked to a bottom bar
    property bool flushBottom: false
    // "top", "bottom" or "center": where the surface grows from
    property string growFrom: "top"
    default property alias content: body.data

    transform: Scale {
        id: grow
        origin.x: surface.width / 2
        origin.y: surface.growFrom === "top" ? 0 : surface.growFrom === "bottom" ? surface.height : surface.height / 2
    }

    RectangularShadow {
        anchors.fill: background
        topLeftRadius: background.topLeftRadius
        topRightRadius: background.topRightRadius
        bottomLeftRadius: background.bottomLeftRadius
        bottomRightRadius: background.bottomRightRadius
        offset.y: 6
        blur: 28
        color: Theme.shadow
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: surface.color
        radius: surface.radius
        bottomLeftRadius: surface.flushBottom ? 0 : surface.radius
        bottomRightRadius: surface.flushBottom ? 0 : surface.radius

        Behavior on color { ColorEffect {} }
    }

    Item {
        id: body
        anchors.fill: parent
    }

    ParallelAnimation {
        id: entrance
        Effect { target: surface; property: "opacity"; from: 0; to: 1 }
        Spring { target: grow; property: "xScale"; from: surface.growFrom === "center" ? 0.9 : 0.96; to: 1; speed: "default" }
        Spring { target: grow; property: "yScale"; from: surface.growFrom === "center" ? 0.9 : 0.82; to: 1; speed: "default" }
    }

    Component.onCompleted: entrance.start()
}
