import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Item {
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: notifText.implicitWidth + Theme.modulePadding * 2
    implicitHeight: Theme.barHeight

    Text {
        id: notifText
        anchors.centerIn: parent
        text: NotificationState.icon
        color: Theme.text
        font.family: Theme.symbolFontFamily
        font.pixelSize: Theme.fontSize
        font.weight: Theme.fontWeight
    }

    opacity: mouseArea.containsMouse ? 0.6 : 1.0
    Behavior on opacity { NumberAnimation { duration: 80 } }

    MouseArea {
        id: mouseArea
        cursorShape: Qt.PointingHandCursor
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                dndProc.running = true;
            } else {
                toggleProc.running = true;
            }
        }
    }

    Process {
        id: toggleProc
        command: ["swaync-client", "-t", "-sw"]
        running: false
    }

    Process {
        id: dndProc
        command: ["swaync-client", "-d", "-sw"]
        running: false
    }
}
