import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../material"
import "../material/m3" as M3

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: bar

        required property var modelData
        screen: modelData

        anchors { top: true; left: true; right: true }
        implicitHeight: 40
        color: Theme.background

        WlrLayershell.namespace: "quickshell:deck-bar"
        WlrLayershell.layer: WlrLayer.Top

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        Swipe {
            anchors.fill: parent
            onTapped: DeckState.toggleQuickSettings()
            onSwiped: direction => {
                if (direction === "down")
                    DeckState.quickSettings = true;
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 12
            spacing: 2

            M3.IconButton {
                icon: "grid_view"
                size: 36
                onClicked: {
                    DeckState.closeAll();
                    DeckState.niri(["toggle-overview"]);
                }
            }

            M3.IconButton {
                icon: "close"
                size: 36
                onClicked: DeckState.niri(["close-window"])
            }

            M3.IconButton {
                icon: "keyboard"
                size: 36
                onClicked: DeckState.toggleKeyboard()
            }

            Item { Layout.fillWidth: true }

            Row {
                spacing: 10

                M3.Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: SystemStatus.wifiIcon
                    size: 18
                }

                M3.Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: SystemStatus.bluetoothEnabled
                    icon: SystemStatus.bluetoothIcon
                    size: 18
                }

                M3.Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: SystemStatus.volumeIcon
                    size: 18
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: SystemStatus.hasBattery
                    spacing: 2

                    M3.Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: SystemStatus.batteryIcon
                        size: 18
                    }

                    M3.Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: SystemStatus.batteryPercent + "%"
                    }
                }
            }
        }

        M3.Label {
            anchors.centerIn: parent
            text: Qt.formatDateTime(clock.date, "hh:mm")
            font.pixelSize: Theme.typeTitle
        }
    }
}
