import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "m3" as M3

Item {
    id: networkPopup

    readonly property var wifiIcons: ["signal_wifi_0_bar", "network_wifi_1_bar", "network_wifi_2_bar", "network_wifi_3_bar", "signal_wifi_4_bar"]

    function signalIcon(signal) {
        return wifiIcons[Math.max(0, Math.min(4, Math.floor(signal / 20)))];
    }

    component NetworkRow: M3.ListSegment {
        id: networkRow

        property var networkData

        readonly property bool secured: networkData.security !== "" && networkData.security !== "--"

        width: parent ? parent.width : 0
        height: 52

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 16
            spacing: 14

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: networkRow.networkData.connected ? Theme.shapeM : 18
                color: networkRow.networkData.connected ? Theme.primary : Theme.surfaceContainerHighest

                Behavior on radius { M3.Spring {} }
                Behavior on color { M3.ColorEffect {} }

                M3.Icon {
                    anchors.centerIn: parent
                    icon: networkPopup.signalIcon(networkRow.networkData.signal)
                    size: 20
                    color: networkRow.networkData.connected ? Theme.textOnPrimary : Theme.textOnSurfaceVariant
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                M3.Label {
                    Layout.fillWidth: true
                    text: networkRow.networkData.ssid
                    color: networkRow.selected ? Theme.textOnSecondaryContainer : Theme.textOnSurface
                    font.pixelSize: Theme.typeBody + 1
                    font.weight: Font.Bold
                }

                M3.Label {
                    Layout.fillWidth: true
                    text: networkRow.networkData.connected ? "Connected" : networkRow.secured ? "Secured" : "Open"
                    color: networkRow.networkData.connected ? Theme.primary : Theme.textOnSurfaceVariant
                    font.pixelSize: Theme.typeLabel
                }
            }

            M3.Icon {
                visible: networkRow.secured
                icon: "lock"
                size: 16
                color: Theme.textOnSurfaceVariant
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root

            required property var modelData
            screen: modelData
            visible: NetworkPopupState.visible && monitorIsFocused

            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
            property bool monitorIsFocused: Hyprland.focusedMonitor?.id == monitor?.id
            onMonitorIsFocusedChanged: if (!monitorIsFocused) NetworkPopupState.close()

            property string selectedSsid: ""
            property bool selectedIsSecured: false
            property bool savePassword: true
            property bool showPassword: false

            color: "transparent"

            WlrLayershell.namespace: "quickshell:networkpopup"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            anchors { top: true; bottom: true; left: true; right: true }

            function chooseNetwork(network) {
                const secured = network.security !== "" && network.security !== "--";
                const known = NetworkState.savedConnections.indexOf(network.ssid) !== -1;
                if (network.connected) return;
                if (secured && !known) {
                    selectedSsid = network.ssid;
                    selectedIsSecured = true;
                    savePassword = true;
                    showPassword = false;
                    passwordFocusTimer.start();
                } else {
                    NetworkState.connectToNetwork(network.ssid, "", true);
                }
            }

            HyprlandFocusGrab {
                id: grab
                windows: [root]
                active: false
                onCleared: () => {
                    if (!active) NetworkPopupState.close();
                }
            }

            Connections {
                target: NetworkPopupState
                function onVisibleChanged() {
                    if (NetworkPopupState.visible) {
                        root.selectedSsid = "";
                        NetworkState.scan();
                        NetworkState.refreshSavedConnections();
                        grabTimer.start();
                    } else {
                        grabTimer.stop();
                        grab.active = false;
                    }
                }
            }

            Timer {
                id: grabTimer
                interval: 50
                repeat: false
                onTriggered: grab.active = NetworkPopupState.visible
            }

            Timer {
                id: passwordFocusTimer
                interval: 80
                repeat: false
                onTriggered: passwordInput.forceActiveFocus()
            }

            MouseArea {
                anchors.fill: parent
                onClicked: NetworkPopupState.close()
            }

            FocusScope {
                anchors.fill: parent
                focus: NetworkPopupState.visible

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        if (root.selectedSsid.length > 0) root.selectedSsid = "";
                        else NetworkPopupState.close();
                        event.accepted = true;
                    }
                }

                M3.Surface {
                    id: popup
                    anchors.top: BarState.isTop ? parent.top : undefined
                    anchors.bottom: BarState.isTop ? undefined : parent.bottom
                    anchors.topMargin: Theme.popupGap
                    anchors.right: parent.right
                    anchors.rightMargin: 55
                    width: 320
                    height: contentCol.implicitHeight + 24
                    flushBottom: !BarState.isTop
                    growFrom: BarState.isTop ? "top" : "bottom"

                    Behavior on height { M3.Spring { speed: "default" } }

                    MouseArea { anchors.fill: parent }

                    Column {
                        id: contentCol
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 12
                        spacing: 12

                        RowLayout {
                            width: parent.width
                            spacing: 14

                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                radius: NetworkState.wifiEnabled ? Theme.shapeM : 20
                                color: NetworkState.wifiEnabled ? Theme.primaryContainer : Theme.surfaceContainerHighest

                                Behavior on radius { M3.Spring {} }
                                Behavior on color { M3.ColorEffect {} }

                                M3.Icon {
                                    anchors.centerIn: parent
                                    icon: NetworkState.wifiEnabled ? "wifi" : "wifi_off"
                                    size: 24
                                    color: NetworkState.wifiEnabled ? Theme.textOnPrimaryContainer : Theme.textOnSurfaceVariant
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                M3.Label {
                                    Layout.fillWidth: true
                                    text: "Wi-Fi"
                                    font.pixelSize: Theme.typeTitle
                                    font.weight: Font.Bold
                                }

                                M3.Label {
                                    Layout.fillWidth: true
                                    text: !NetworkState.wifiEnabled ? "Off"
                                        : NetworkState.netType === "wifi" ? NetworkState.connectionName
                                        : NetworkState.netType === "ethernet" ? "Ethernet" : "Not connected"
                                    color: Theme.textOnSurfaceVariant
                                    font.pixelSize: Theme.typeLabel
                                }
                            }

                            M3.Switch {
                                checked: NetworkState.wifiEnabled
                                onClicked: NetworkState.toggleWifi()
                            }
                        }

                        Loader {
                            width: parent.width
                            sourceComponent: NetworkState.connecting ? connectingView
                                : root.selectedSsid.length > 0 ? passwordView
                                : networkListView
                        }
                    }
                }
            }

            Component {
                id: networkListView

                Column {
                    width: parent.width
                    spacing: 10

                    RowLayout {
                        width: parent.width
                        height: 24

                        M3.Label {
                            Layout.fillWidth: true
                            leftPadding: 4
                            text: NetworkState.wifiEnabled ? "Available networks" : "Wi-Fi is off"
                            color: Theme.primary
                            font.pixelSize: Theme.typeLabel
                            font.weight: Font.Bold
                        }

                        M3.LoadingIndicator {
                            visible: NetworkState.scanning && NetworkState.wifiEnabled
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            contained: false
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 2

                        Repeater {
                            id: networkRepeater
                            model: NetworkState.wifiEnabled ? NetworkState.availableNetworks : []
                            delegate: NetworkRow {
                                required property var modelData
                                required property int index
                                networkData: modelData
                                first: index === 0
                                last: index === networkRepeater.count - 1
                                selected: modelData.connected
                                onClicked: root.chooseNetwork(modelData)
                            }
                        }
                    }
                }
            }

            Component {
                id: passwordView

                Column {
                    width: parent.width
                    spacing: 16

                    RowLayout {
                        width: parent.width
                        spacing: 10

                        M3.IconButton {
                            icon: "arrow_back"
                            onClicked: root.selectedSsid = ""
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            M3.Label {
                                Layout.fillWidth: true
                                text: root.selectedSsid
                                font.pixelSize: Theme.typeTitle
                                font.weight: Font.Bold
                            }

                            M3.Label {
                                Layout.fillWidth: true
                                text: "Secured network"
                                color: Theme.textOnSurfaceVariant
                                font.pixelSize: Theme.typeLabel
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 52
                        radius: Theme.shapeL
                        color: Theme.surfaceContainerHighest
                        border.width: passwordInput.activeFocus ? 2 : 0
                        border.color: Theme.primary

                        M3.Label {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.leftMargin: 16
                            anchors.topMargin: 9
                            text: "Password"
                            color: passwordInput.activeFocus ? Theme.primary : Theme.textOnSurfaceVariant
                            font.pixelSize: Theme.typeLabelS
                            font.weight: Font.Bold
                        }

                        TextInput {
                            id: passwordInput
                            anchors.left: parent.left
                            anchors.right: eyeButton.left
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: 16
                            anchors.rightMargin: 8
                            anchors.bottomMargin: 11
                            echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                            color: Theme.textOnSurface
                            selectionColor: Theme.primary
                            selectedTextColor: Theme.textOnPrimary
                            clip: true
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.typeTitle
                            font.weight: Theme.fontWeight
                            Component.onCompleted: Qt.callLater(() => forceActiveFocus())
                            Keys.onReturnPressed: {
                                NetworkState.connectToNetwork(root.selectedSsid, text, root.savePassword);
                                root.selectedSsid = "";
                            }
                        }

                        M3.IconButton {
                            id: eyeButton
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            icon: root.showPassword ? "visibility_off" : "visibility"
                            onClicked: root.showPassword = !root.showPassword
                        }
                    }

                    RowLayout {
                        width: parent.width
                        spacing: 12

                        M3.Label {
                            Layout.fillWidth: true
                            leftPadding: 4
                            text: "Save password"
                        }

                        M3.Switch {
                            checked: root.savePassword
                            onClicked: root.savePassword = !root.savePassword
                        }
                    }

                    RowLayout {
                        width: parent.width
                        spacing: 8

                        M3.Button {
                            Layout.fillWidth: true
                            variant: "outlined"
                            text: "Cancel"
                            onClicked: root.selectedSsid = ""
                        }

                        M3.Button {
                            Layout.fillWidth: true
                            variant: "filled"
                            text: "Connect"
                            onClicked: {
                                NetworkState.connectToNetwork(root.selectedSsid, passwordInput.text, root.savePassword);
                                root.selectedSsid = "";
                            }
                        }
                    }
                }
            }

            Component {
                id: connectingView

                Column {
                    width: parent.width
                    topPadding: 8
                    bottomPadding: 8
                    spacing: 14

                    M3.LoadingIndicator {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 64
                        height: 48
                    }

                    M3.Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(implicitWidth, parent.width)
                        text: "Connecting to " + (NetworkState.connectionName || "network")
                        font.pixelSize: Theme.typeTitle
                        font.weight: Font.Bold
                    }

                    M3.Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Please wait"
                        color: Theme.textOnSurfaceVariant
                    }
                }
            }
        }
    }
}
