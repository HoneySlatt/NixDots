import QtQuick
import ".."

// Small full-round label, e.g. "Active" or "Connected".
Rectangle {
    id: badge

    property string text: ""
    property color contentColor: Theme.textOnPrimary

    implicitWidth: label.implicitWidth + 16
    implicitHeight: 20
    radius: height / 2
    color: Theme.primary

    Label {
        id: label
        anchors.centerIn: parent
        text: badge.text
        color: badge.contentColor
        font.pixelSize: Theme.typeLabelS
        font.weight: Font.Bold
    }
}
