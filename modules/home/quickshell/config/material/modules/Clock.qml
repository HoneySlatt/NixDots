import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

Item {
    id: clock

    Layout.alignment: Qt.AlignVCenter
    implicitWidth: clockText.implicitWidth
    implicitHeight: Theme.barHeight

    Text {
        id: clockText
        anchors.centerIn: parent
        color: Theme.text
        font.family: Theme.fontFamily
        font.variableAxes: ({ "wdth": Theme.barFontWidth })
        scale: Theme.barTextScale
        font.pixelSize: Theme.fontSize
        font.weight: Theme.fontWeight
        text: Qt.formatDateTime(systemClock.date, "hh:mm AP\u2003-\u2003ddd dd")
    }

    opacity: mouseArea.containsMouse ? 0.6 : 1.0
    Behavior on opacity { NumberAnimation { duration: 80 } }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: CalendarPopupState.toggle()
    }

    // Wakes up once per minute, aligned on the minute change
    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }
}
