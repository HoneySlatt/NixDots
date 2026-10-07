import QtQuick
import ".."

// M3 Expressive slider: thick split track, bar handle, optional inset icon.
Item {
    id: slider

    property real value: 0
    property real from: 0
    property real to: 100
    property int stepSize: 5
    property bool muted: false
    property string icon: ""
    property bool iconClickable: false
    property int trackHeight: 12
    property int handleHeight: 32
    property bool showValue: true
    signal moved(int value)
    signal iconClicked()

    property real _dragValue: 0
    readonly property bool dragging: mouse.pressed
    readonly property real shownValue: dragging ? _dragValue : Math.max(from, Math.min(to, value))
    readonly property real fraction: (shownValue - from) / Math.max(1, to - from)

    readonly property int handleWidth: dragging ? 2 : 4
    readonly property int gap: 6
    readonly property real handleX: fraction * (width - handleWidth)
    readonly property real outerRadius: trackHeight / 2
    readonly property real innerRadius: Math.min(Theme.shapeXS, outerRadius)
    readonly property color activeColor: muted ? Theme.outline : Theme.primary

    implicitWidth: 200
    implicitHeight: Math.max(handleHeight, trackHeight)

    function setFromX(x) {
        const ratio = Math.max(0, Math.min(1, x / width));
        _dragValue = Math.round(from + ratio * (to - from));
        slider.moved(_dragValue);
    }

    Rectangle {
        id: activeTrack
        anchors.verticalCenter: parent.verticalCenter
        x: 0
        width: Math.max(0, slider.handleX - slider.gap)
        height: slider.trackHeight
        visible: width > 0.5
        color: slider.activeColor
        topLeftRadius: slider.outerRadius
        bottomLeftRadius: slider.outerRadius
        topRightRadius: Math.min(slider.innerRadius, width / 2)
        bottomRightRadius: Math.min(slider.innerRadius, width / 2)

        Behavior on color { ColorEffect {} }
    }

    Rectangle {
        id: inactiveTrack
        anchors.verticalCenter: parent.verticalCenter
        x: slider.handleX + slider.handleWidth + slider.gap
        width: Math.max(0, slider.width - x)
        height: slider.trackHeight
        visible: width > 0.5
        color: Theme.secondaryContainer
        topRightRadius: slider.outerRadius
        bottomRightRadius: slider.outerRadius
        topLeftRadius: Math.min(slider.innerRadius, width / 2)
        bottomLeftRadius: Math.min(slider.innerRadius, width / 2)

        Rectangle {
            visible: parent.width > slider.trackHeight
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: (slider.trackHeight - width) / 2
            width: 4
            height: 4
            radius: 2
            color: slider.activeColor
        }
    }

    Icon {
        z: 2
        visible: slider.icon !== ""
        anchors.verticalCenter: parent.verticalCenter
        x: (slider.trackHeight - width) / 2 + 4
        icon: slider.icon
        size: Math.round(slider.trackHeight * 0.5)
        color: activeTrack.width > x + width ? Theme.textOnPrimary : Theme.textOnSecondaryContainer

        MouseArea {
            enabled: slider.iconClickable
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: slider.iconClicked()
        }
    }

    Rectangle {
        id: handle
        anchors.verticalCenter: parent.verticalCenter
        x: slider.handleX
        width: slider.handleWidth
        height: slider.handleHeight
        radius: width / 2
        color: slider.activeColor

        Behavior on width { Spring {} }
    }

    Rectangle {
        id: valueIndicator
        anchors.bottom: handle.top
        anchors.bottomMargin: 6
        x: Math.max(0, Math.min(slider.width - width, handle.x + handle.width / 2 - width / 2))
        width: Math.max(40, valueLabel.implicitWidth + 20)
        height: 32
        radius: 16
        color: Theme.inverseSurface
        opacity: slider.dragging && slider.showValue ? 1 : 0
        scale: slider.dragging && slider.showValue ? 1 : 0.6
        transformOrigin: Item.Bottom
        z: 10

        Behavior on opacity { Effect {} }
        Behavior on scale { Spring {} }

        Label {
            id: valueLabel
            anchors.centerIn: parent
            text: Math.round(slider.shownValue)
            color: Theme.inverseOnSurface
            font.pixelSize: Theme.typeLabel
            font.weight: Font.Bold
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.PointingHandCursor
        onPressed: event => slider.setFromX(event.x)
        onPositionChanged: event => {
            if (pressed) slider.setFromX(event.x);
        }
        onWheel: event => {
            const delta = event.angleDelta.y > 0 ? slider.stepSize : -slider.stepSize;
            slider.moved(Math.max(slider.from, Math.min(slider.to, Math.round(slider.value + delta))));
        }
    }
}
