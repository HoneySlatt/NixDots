import QtQuick
import ".."

// M3 search bar: full-round container with leading icon.
FocusScope {
    id: field

    property alias text: input.text
    property alias input: input
    property string placeholder: "Search"
    property string icon: "search"
    property bool readOnly: false
    property color color: Theme.surfaceContainerHigh

    implicitWidth: 360
    implicitHeight: 48

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: field.color

        Behavior on color { ColorEffect {} }
    }

    Icon {
        id: leading
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        icon: field.icon
        size: 20
        color: Theme.textOnSurface
    }

    TextInput {
        id: input
        anchors.left: leading.right
        anchors.right: parent.right
        anchors.leftMargin: 14
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        focus: true
        readOnly: field.readOnly
        color: Theme.textOnSurface
        selectionColor: Theme.primary
        selectedTextColor: Theme.textOnPrimary
        clip: true
        font.family: Theme.fontFamily
        font.pixelSize: Theme.typeBody + 1
        font.weight: Theme.fontWeight

        Label {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            visible: input.text.length === 0
            text: field.placeholder
            color: Theme.textOnSurfaceVariant
            font.pixelSize: input.font.pixelSize
        }
    }
}
