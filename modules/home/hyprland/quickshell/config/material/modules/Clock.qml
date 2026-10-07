import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: clock

    property date now: new Date()

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
        text: Qt.formatDateTime(clock.now, "hh:mm AP\u2003-\u2003ddd dd")
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

    // Long Qt timers are coarse and can fire seconds early, so poll instead
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clock.now = new Date()
    }
}
