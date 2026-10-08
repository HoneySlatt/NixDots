import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../services" as Services

Item {
    id: root

    Layout.alignment: Qt.AlignVCenter
    implicitWidth: workspaceRow.implicitWidth + 8
    implicitHeight: Theme.barHeight

    Row {
        id: workspaceRow
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: 8
        spacing: 0

        Repeater {
            model: Services.NiriData.barWorkspaces

            delegate: Item {
                required property var modelData

                width: 32
                height: Theme.barHeight

                Text {
                    anchors.centerIn: parent
                    text: {
                        if (modelData.name === "magic") return "";
                        if (modelData.name === "zellij") return "";
                        if (modelData.name === "10") return "\u{f02b4}";
                        if (modelData.name === "lock") return "";
                        return "";
                    }
                    color: {
                        if (modelData.is_focused)
                            return Theme.text;
                        return Theme.caution;
                    }
                    font.family: Theme.symbolFontFamily
                    font.pixelSize: Theme.fontSize
                    font.weight: Theme.fontWeight
                    font.italic: true

                    Behavior on color {
                        ColorAnimation { duration: 250 }
                    }
                }

                MouseArea {
                    cursorShape: Qt.PointingHandCursor
                    anchors.fill: parent
                    onClicked: Services.NiriData.focusWorkspace(modelData)
                    onWheel: wheel => Services.NiriData.focusRelative(wheel.angleDelta.y > 0 ? -1 : 1)
                }
            }
        }
    }
}
