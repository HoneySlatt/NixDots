import QtQuick
import QtQuick.Effects
import ".."

// Image clipped to an antialiased rounded rectangle (or circle).
Item {
    id: rounded

    property alias source: image.source
    property alias fillMode: image.fillMode
    property alias sourceSize: image.sourceSize
    property alias status: image.status
    property alias cache: image.cache
    property real radius: Theme.shapeL

    Image {
        id: image
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        visible: false
    }

    Rectangle {
        id: mask
        anchors.fill: parent
        radius: rounded.radius
        layer.enabled: true
        layer.smooth: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: image
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }
}
