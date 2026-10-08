import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

Item {
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: gpuText.implicitWidth + Theme.modulePadding * 2
    implicitHeight: Theme.barHeight

    Text {
        id: gpuText
        anchors.centerIn: parent
        textFormat: Text.RichText
        text: Theme.glyph("\uf2c8") + GpuState.tempC + "\u00b0C"
        color: Theme.text
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
