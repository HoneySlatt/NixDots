import QtQuick
import ".."

// M3 filter chip: outlined at rest, tonal with a check when selected.
Rectangle {
    id: chip

    property string text: ""
    property string icon: ""
    property bool selected: false
    property bool clickable: true
    signal clicked()

    readonly property string shownIcon: selected ? "\u{f012c}" : icon

    implicitHeight: 32
    implicitWidth: row.implicitWidth + (shownIcon !== "" ? 24 : 32)
    radius: Theme.shapeS
    color: selected ? Theme.secondaryContainer : "transparent"
    border.width: selected ? 0 : 1
    border.color: Theme.outlineVariant

    Behavior on color { ColorEffect {} }
    Behavior on implicitWidth { Spring {} }

    StateLayer {
        visible: chip.clickable
        tint: selected ? Theme.textOnSecondaryContainer : Theme.textOnSurfaceVariant
        hovered: mouse.containsMouse
        pressed: mouse.pressed
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Icon {
            visible: chip.shownIcon !== ""
            anchors.verticalCenter: parent.verticalCenter
            icon: chip.shownIcon
            size: 16
            color: chip.selected ? Theme.textOnSecondaryContainer : Theme.primary
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: chip.text
            color: chip.selected ? Theme.textOnSecondaryContainer : Theme.textOnSurfaceVariant
            font.pixelSize: Theme.typeLabel
            font.weight: Font.Bold
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: chip.clickable
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.clicked()
    }
}
