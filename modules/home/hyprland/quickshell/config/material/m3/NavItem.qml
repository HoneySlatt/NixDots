import QtQuick
import ".."

// M3 navigation rail destination: pill indicator that expands from the center.
Item {
    id: item

    property string icon: ""
    property string label: ""
    property bool active: false
    signal clicked()

    implicitWidth: 80
    implicitHeight: label !== "" ? 56 : 40

    Item {
        id: indicatorBox
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: 56
        height: 32

        Rectangle {
            anchors.centerIn: parent
            width: item.active ? parent.width : 24
            height: parent.height
            radius: height / 2
            color: Theme.secondaryContainer
            opacity: item.active ? 1 : 0

            Behavior on width { Spring {} }
            Behavior on opacity { Effect {} }
        }

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Theme.textOnSurface
            opacity: mouse.pressed ? Theme.statePressed : mouse.containsMouse ? Theme.stateHover : 0

            Behavior on opacity { Effect {} }
        }

        Icon {
            anchors.centerIn: parent
            icon: item.icon
            size: 20
            filled: item.active
            color: item.active ? Theme.textOnSecondaryContainer : Theme.textOnSurfaceVariant
        }
    }

    Label {
        visible: item.label !== ""
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: indicatorBox.bottom
        anchors.topMargin: 4
        text: item.label
        color: item.active ? Theme.textOnSurface : Theme.textOnSurfaceVariant
        font.pixelSize: Theme.typeLabel
        font.weight: item.active ? Font.Bold : Theme.fontWeight
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: item.clicked()
    }
}
