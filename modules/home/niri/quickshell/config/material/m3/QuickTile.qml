import QtQuick
import QtQuick.Layouts
import ".."

// Quick settings tile: full-round when off, rounded square in primary when on.
Rectangle {
    id: tile

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool selected: false
    property bool interactive: true
    signal clicked()
    signal entered()

    readonly property color contentColor: active ? Theme.textOnPrimary : Theme.textOnSurface

    implicitHeight: 60
    radius: active ? Theme.shapeLI : height / 2
    color: active ? Theme.primary : Theme.surfaceContainerHighest

    Behavior on radius { Spring {} }
    Behavior on color { ColorEffect {} }

    StateLayer {
        visible: tile.interactive
        tint: tile.contentColor
        hovered: mouse.containsMouse
        pressed: mouse.pressed
    }

    FocusRing {
        shown: tile.selected
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 14
        spacing: 10

        Rectangle {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            radius: tile.active ? Theme.shapeM : 18
            color: tile.active ? Theme.alpha(Theme.textOnPrimary, 0.14) : Theme.mix(Theme.surfaceContainerHighest, Theme.textOnSurface, 0.07)

            Behavior on radius { Spring {} }

            Icon {
                anchors.centerIn: parent
                icon: tile.icon
                size: 20
                color: tile.contentColor
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Label {
                Layout.fillWidth: true
                text: tile.title
                color: tile.contentColor
                font.pixelSize: Theme.typeBody + 1
                font.weight: Font.Bold
            }

            Label {
                Layout.fillWidth: true
                visible: text !== ""
                text: tile.subtitle
                color: tile.active ? Theme.alpha(Theme.textOnPrimary, 0.8) : Theme.textOnSurfaceVariant
                font.pixelSize: Theme.typeLabel
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: tile.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: tile.entered()
        onClicked: tile.clicked()
    }
}
