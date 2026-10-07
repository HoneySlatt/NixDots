import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

Item {
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: volumeText.implicitWidth + Theme.modulePadding * 2
    implicitHeight: Theme.barHeight

    Text {
        id: volumeText
        anchors.centerIn: parent
        textFormat: Text.RichText
        text: {
            let icon;
            if (VolumeState.muted) {
                icon = "\uf026";
            } else if (VolumeState.volume <= 30) {
                icon = "\uf027";
            } else {
                icon = "\uf028";
            }
            return Theme.glyph(icon) + VolumeState.volume + "%";
        }
        color: VolumeState.muted ? Theme.separator : Theme.text
        font.family: Theme.fontFamily
        font.variableAxes: ({ "wdth": Theme.barFontWidth })
        scale: Theme.barTextScale
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
                VolumeState.toggleMute();
            } else {
                VolumePopupState.toggle();
            }
        }
        onWheel: function(wheel) {
            if (wheel.angleDelta.y > 0) {
                VolumeState.volUp();
            } else if (wheel.angleDelta.y < 0) {
                VolumeState.volDown();
            }
        }
    }
}
