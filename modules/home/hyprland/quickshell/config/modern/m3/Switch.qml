import QtQuick
import ".."

// M3 switch: the thumb grows and gains a check when selected.
Item {
    id: toggleSwitch

    property bool checked: false
    signal clicked()

    readonly property real thumbSize: mouse.pressed ? 28 : checked ? 24 : 16

    implicitWidth: 52
    implicitHeight: 32

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: toggleSwitch.checked ? Theme.primary : Theme.surfaceContainerHighest
        border.width: toggleSwitch.checked ? 0 : 2
        border.color: Theme.outline

        Behavior on color { ColorEffect {} }
    }

    Rectangle {
        id: halo
        anchors.centerIn: thumb
        width: 40
        height: 40
        radius: 20
        color: toggleSwitch.checked ? Theme.primary : Theme.textOnSurface
        opacity: mouse.pressed ? Theme.statePressed : mouse.containsMouse ? Theme.stateHover : 0

        Behavior on opacity { Effect {} }
    }

    Rectangle {
        id: thumb
        x: (toggleSwitch.checked ? track.width - track.height / 2 : track.height / 2) - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: toggleSwitch.thumbSize
        height: toggleSwitch.thumbSize
        radius: width / 2
        color: toggleSwitch.checked ? Theme.textOnPrimary : Theme.outline

        Behavior on x { Spring {} }
        Behavior on width { Spring {} }
        Behavior on height { Spring {} }
        Behavior on color { ColorEffect {} }

        Icon {
            anchors.centerIn: parent
            icon: "check"
            size: 14
            color: Theme.primary
            opacity: toggleSwitch.checked ? 1 : 0

            Behavior on opacity { Effect {} }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: toggleSwitch.clicked()
    }
}
