import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../material"
import "../material/m3" as M3

PanelWindow {
    id: root

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.namespace: "quickshell:deck-quicksettings"
    WlrLayershell.layer: WlrLayer.Overlay

    property string armed: ""

    function confirm(key, command) {
        if (armed === key) {
            Quickshell.execDetached(command);
            DeckState.closeAll();
            return;
        }
        armed = key;
        disarm.restart();
    }

    Timer {
        id: disarm
        interval: 3000
        onTriggered: root.armed = ""
    }

    Component.onCompleted: SystemStatus.refreshBrightness()

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.scrim

        MouseArea {
            anchors.fill: parent
            onClicked: DeckState.closeAll()
        }
    }

    M3.Surface {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 8
        width: 560
        height: content.implicitHeight + 48
        growFrom: "top"

        Swipe {
            anchors.fill: parent
            onSwiped: direction => {
                if (direction === "up")
                    DeckState.closeAll();
            }
        }

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 24
            spacing: 18

            RowLayout {
                Layout.fillWidth: true

                Column {
                    M3.Label {
                        text: Qt.formatDateTime(clock.date, "hh:mm")
                        font.pixelSize: Theme.typeHeadline
                    }

                    M3.Label {
                        text: Qt.formatDateTime(clock.date, "dddd d MMMM")
                        color: Theme.textOnSurfaceVariant
                    }
                }

                Item { Layout.fillWidth: true }

                Column {
                    visible: SystemStatus.hasBattery

                    Row {
                        anchors.right: parent.right
                        spacing: 4

                        M3.Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            icon: SystemStatus.batteryIcon
                            size: 22
                        }

                        M3.Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: SystemStatus.batteryPercent + "%"
                            font.pixelSize: Theme.typeTitleL
                        }
                    }

                    M3.Label {
                        anchors.right: parent.right
                        text: SystemStatus.batteryTime
                        color: Theme.textOnSurfaceVariant
                    }
                }
            }

            M3.Slider {
                Layout.fillWidth: true
                trackHeight: 40
                handleHeight: 56
                icon: SystemStatus.volumeIcon
                iconClickable: true
                value: SystemStatus.volume
                muted: SystemStatus.muted
                onMoved: value => SystemStatus.setVolume(value)
                onIconClicked: SystemStatus.toggleMute()
            }

            M3.Slider {
                Layout.fillWidth: true
                trackHeight: 40
                handleHeight: 56
                icon: "light_mode"
                from: 5
                value: SystemStatus.brightness
                onMoved: value => SystemStatus.setBrightness(value)
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 10
                rowSpacing: 10

                M3.QuickTile {
                    Layout.fillWidth: true
                    implicitHeight: 64
                    icon: SystemStatus.wifiIcon
                    title: "Wi-Fi"
                    subtitle: !SystemStatus.wifiEnabled ? "Off" : SystemStatus.wifiNetwork ? SystemStatus.wifiNetwork.name : "Disconnected"
                    active: SystemStatus.wifiEnabled
                    onClicked: SystemStatus.toggleWifi()
                }

                M3.QuickTile {
                    Layout.fillWidth: true
                    implicitHeight: 64
                    icon: SystemStatus.bluetoothIcon
                    title: "Bluetooth"
                    subtitle: !SystemStatus.bluetoothEnabled ? "Off" : SystemStatus.bluetoothDevice ? SystemStatus.bluetoothDevice.name : "On"
                    active: SystemStatus.bluetoothEnabled
                    onClicked: SystemStatus.toggleBluetooth()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                M3.Button {
                    Layout.fillWidth: true
                    size: 56
                    icon: root.armed === "gaming" ? "check" : "sports_esports"
                    text: root.armed === "gaming" ? "Tap again" : "Gaming Mode"
                    onClicked: root.confirm("gaming", ["niri", "msg", "action", "quit", "--skip-confirmation"])
                }

                M3.IconButton {
                    size: 56
                    variant: "tonal"
                    icon: root.armed === "reboot" ? "check" : "restart_alt"
                    onClicked: root.confirm("reboot", ["systemctl", "reboot"])
                }

                M3.IconButton {
                    size: 56
                    variant: "error"
                    icon: root.armed === "poweroff" ? "check" : "power_settings_new"
                    onClicked: root.confirm("poweroff", ["systemctl", "poweroff"])
                }
            }
        }
    }
}
