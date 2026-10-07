import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

Item {
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: ramText.implicitWidth + Theme.modulePadding * 2
    implicitHeight: Theme.barHeight

    Text {
        id: ramText
        anchors.centerIn: parent
        textFormat: Text.RichText
        text: Theme.glyph("\uefc5") + RamState.percentage + "%"
        color: {
            if (RamState.percentage >= 95) return RamState.blinkState ? Theme.warning : Theme.separator;
            return Theme.text;
        }
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
        onClicked: SystemMonitorPopupState.toggle()
    }
}
