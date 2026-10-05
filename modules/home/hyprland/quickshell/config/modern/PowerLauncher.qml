import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Hyprland
import "m3" as M3

Item {
    id: scope

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root

            required property var modelData
            screen: modelData
            visible: PowerLauncherState.visible && monitorIsFocused

            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
            property bool monitorIsFocused: Hyprland.focusedMonitor?.id == monitor?.id
            onMonitorIsFocusedChanged: if (!monitorIsFocused) PowerLauncherState.close()

            property bool bluetoothPowered: false
            property bool dndEnabled: false
            property bool nightLightEnabled: false
            property bool showPowerActions: false
            property int brightness: 0
            property string batteryText: "--"

            readonly property MprisPlayer player: {
                const players = Mpris.players.values;
                if (players.length === 0) return null;
                const playing = players.find(p => p.playbackState === MprisPlaybackState.Playing);
                return playing ?? players[0];
            }

            color: "transparent"

            WlrLayershell.namespace: "quickshell:controlcenter"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            anchors { top: true; bottom: true; left: true; right: true }

            function refreshSystemState() {
                bluetoothProc.running = true;
                dndProc.running = true;
                brightnessProc.running = true;
                nightLightProc.running = true;
                batteryProc.running = true;
            }

            function executeAction(command) {
                PowerLauncherState.close();
                Quickshell.execDetached(["sh", "-c", command]);
            }

            HyprlandFocusGrab {
                id: grab
                windows: [root]
                active: false
                onCleared: () => {
                    if (!active) PowerLauncherState.close();
                }
            }

            Connections {
                target: PowerLauncherState
                function onVisibleChanged() {
                    if (PowerLauncherState.visible) {
                        root.showPowerActions = false;
                        root.refreshSystemState();
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
                onTriggered: grab.active = PowerLauncherState.visible
            }

            Timer {
                interval: 2000
                running: PowerLauncherState.visible
                repeat: true
                onTriggered: root.refreshSystemState()
            }

            Process {
                id: bluetoothProc
                command: ["bluetoothctl", "show"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: root.bluetoothPowered = this.text.includes("Powered: yes")
                }
            }

            Process {
                id: bluetoothToggleProc
                command: ["bash", "-c", "if bluetoothctl show | grep -q 'Powered: yes'; then bluetoothctl power off; else bluetoothctl power on; fi"]
                running: false
                onExited: bluetoothProc.running = true
            }

            Process {
                id: dndProc
                command: ["swaync-client", "-D"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: root.dndEnabled = this.text.trim() === "true"
                }
            }

            Process {
                id: dndToggleProc
                command: ["swaync-client", "-d"]
                running: false
                onExited: dndProc.running = true
            }

            Process {
                id: brightnessProc
                command: ["bash", "-c", "cur=$(brightnessctl g 2>/dev/null || echo 0); max=$(brightnessctl m 2>/dev/null || echo 1); awk -v c=\"$cur\" -v m=\"$max\" 'BEGIN { if (m <= 0) m = 1; printf \"%d\", (c / m) * 100 }'"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        const value = parseInt(this.text.trim());
                        if (!isNaN(value)) root.brightness = Math.max(0, Math.min(100, value));
                    }
                }
            }

            Process {
                id: brightnessSetProc
                running: false
                onExited: brightnessProc.running = true
            }

            Process {
                id: wifiToggleProc
                command: ["bash", "-c", "if [ \"$(nmcli radio wifi)\" = enabled ]; then nmcli radio wifi off; else nmcli radio wifi on; fi"]
                running: false
            }

            Process {
                id: vpnToggleProc
                command: ["/etc/profiles/per-user/honey/bin/toggle-nym"]
                running: false
            }

            Process {
                id: nightLightProc
                command: ["pgrep", "-x", "hyprsunset"]
                running: false
                onExited: root.nightLightEnabled = exitCode === 0
            }

            Process {
                id: nightLightToggleProc
                command: ["bash", "-c", "if pgrep -x hyprsunset >/dev/null; then pkill hyprsunset; else hyprsunset >/dev/null 2>&1 & fi"]
                running: false
                onExited: nightLightProc.running = true
            }

            Process {
                id: batteryProc
                command: ["bash", "-c", "for d in /sys/class/power_supply/*; do [ -e \"$d/capacity\" ] || continue; [ \"$(cat \"$d/type\" 2>/dev/null)\" = Battery ] || continue; base=${d##*/}; case \"$base\" in hidpp_*|ps-controller-*) continue;; esac; cat \"$d/capacity\"; exit 0; done; echo --"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        const value = this.text.trim();
                        root.batteryText = value === "--" ? "--" : value + "%";
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: PowerLauncherState.close()
            }

            FocusScope {
                anchors.fill: parent
                focus: PowerLauncherState.visible

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        if (root.showPowerActions) root.showPowerActions = false;
                        else PowerLauncherState.close();
                        event.accepted = true;
                    }
                }


                M3.Surface {
                    id: popup
                    anchors.top: BarState.isTop ? parent.top : undefined
                    anchors.bottom: BarState.isTop ? undefined : parent.bottom
                    anchors.topMargin: Theme.popupGap
                    anchors.right: parent.right
                    anchors.rightMargin: BarState.isTop ? Theme.margin : 0
                    width: 520
                    height: contentCol.implicitHeight + 32
                    radius: Theme.shapeXLI
                    flushBottom: !BarState.isTop
                    growFrom: BarState.isTop ? "top" : "bottom"

                    Behavior on height { M3.Spring { speed: "default" } }

                    MouseArea { anchors.fill: parent }

                    Column {
                        id: contentCol
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 16
                        spacing: 10

                        RowLayout {
                            width: parent.width
                            spacing: 8

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                M3.Label {
                                    Layout.fillWidth: true
                                    text: Qt.formatDateTime(new Date(), "dddd")
                                    font.pixelSize: Theme.typeTitleL
                                    font.weight: Font.Bold
                                }

                                M3.Label {
                                    text: Qt.formatDateTime(new Date(), "d MMMM")
                                    color: Theme.textOnSurfaceVariant
                                    font.pixelSize: Theme.typeLabel
                                }
                            }

                            M3.Chip {
                                visible: root.batteryText !== "--"
                                clickable: false
                                icon: "\u{f0079}"
                                text: root.batteryText
                            }

                            M3.IconButton {
                                size: 40
                                variant: "error"
                                toggle: true
                                checked: root.showPowerActions
                                icon: "\u{f0425}"
                                onClicked: root.showPowerActions = !root.showPowerActions
                            }
                        }

                        Item {
                            width: parent.width
                            height: root.showPowerActions ? powerGroup.height : 0
                            visible: height > 0
                            clip: true
                            opacity: root.showPowerActions ? 1 : 0

                            Behavior on height { M3.Spring { speed: "default" } }
                            Behavior on opacity { M3.Effect {} }

                            Row {
                                id: powerGroup
                                width: parent.width
                                spacing: 2

                                Repeater {
                                    id: powerRepeater
                                    model: [
                                        { label: "Lock", icon: "\u{f033e}", command: "lock-screen" },
                                        { label: "Logout", icon: "\u{f0343}", command: "hyprctl dispatch 'hl.dsp.exit()'" },
                                        { label: "Reboot", icon: "\u{f0709}", command: "systemctl reboot" },
                                        { label: "Shutdown", icon: "\u{f0425}", command: "systemctl poweroff" }
                                    ]

                                    delegate: M3.Button {
                                        required property var modelData
                                        required property int index
                                        width: (powerGroup.width - 3 * powerGroup.spacing) / 4
                                        size: 56
                                        variant: "error"
                                        grouped: true
                                        groupStart: index === 0
                                        groupEnd: index === powerRepeater.count - 1
                                        icon: modelData.icon
                                        text: modelData.label
                                        labelSize: Theme.typeLabel
                                        onClicked: root.executeAction(modelData.command)
                                    }
                                }
                            }
                        }

                        GridLayout {
                            width: parent.width
                            columns: 2
                            rowSpacing: 8
                            columnSpacing: 8

                            M3.QuickTile {
                                Layout.fillWidth: true
                                icon: NetworkState.netType === "ethernet" ? "\u{f0200}" : NetworkState.netType === "offline" ? "\u{f05aa}" : "\u{f05a9}"
                                title: NetworkState.netType === "ethernet" ? "Ethernet" : "Wi-Fi"
                                subtitle: NetworkState.netType === "wifi" ? NetworkState.connectionName : NetworkState.netType === "ethernet" ? "Connected" : "Off"
                                active: NetworkState.netType !== "offline"
                                onClicked: wifiToggleProc.running = true
                            }

                            M3.QuickTile {
                                Layout.fillWidth: true
                                icon: root.bluetoothPowered ? "\u{f00af}" : "\u{f00b2}"
                                title: "Bluetooth"
                                subtitle: root.bluetoothPowered ? "On" : "Off"
                                active: root.bluetoothPowered
                                onClicked: bluetoothToggleProc.running = true
                            }

                            M3.QuickTile {
                                Layout.fillWidth: true
                                icon: "\u{f099d}"
                                title: "VPN"
                                subtitle: NetworkState.vpnConnected ? "Connected" : "Off"
                                active: NetworkState.vpnConnected
                                onClicked: vpnToggleProc.running = true
                            }

                            M3.QuickTile {
                                Layout.fillWidth: true
                                icon: "\u{f009b}"
                                title: "Do not disturb"
                                subtitle: root.dndEnabled ? "On" : "Off"
                                active: root.dndEnabled
                                onClicked: dndToggleProc.running = true
                            }

                            M3.QuickTile {
                                Layout.fillWidth: true
                                Layout.columnSpan: 2
                                icon: "\u{f0594}"
                                title: "Night light"
                                subtitle: root.nightLightEnabled ? "On" : "Off"
                                active: root.nightLightEnabled
                                onClicked: nightLightToggleProc.running = true
                            }
                        }

                        M3.Slider {
                            width: parent.width
                            trackHeight: 36
                            handleHeight: 48
                            icon: VolumeState.muted ? "\u{f0581}" : "\u{f057e}"
                            iconClickable: true
                            value: VolumeState.volume
                            muted: VolumeState.muted
                            onIconClicked: VolumeState.toggleMute()
                            onMoved: value => VolumeState.setVolume(value)
                        }

                        M3.Slider {
                            width: parent.width
                            trackHeight: 36
                            handleHeight: 48
                            icon: "\u{f00df}"
                            value: root.brightness
                            onMoved: value => {
                                root.brightness = value;
                                brightnessSetProc.command = ["brightnessctl", "set", value + "%"];
                                brightnessSetProc.running = true;
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 80
                            radius: Theme.shapeXL
                            color: Theme.surfaceContainerHigh

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 14

                                Rectangle {
                                    Layout.preferredWidth: 56
                                    Layout.preferredHeight: 56
                                    radius: Theme.shapeL
                                    color: Theme.surfaceContainerHighest

                                    M3.Icon {
                                        anchors.centerIn: parent
                                        visible: cover.status !== Image.Ready
                                        icon: "\u{f075a}"
                                        size: 28
                                        color: Theme.textOnSurfaceVariant
                                    }

                                    M3.RoundedImage {
                                        id: cover
                                        anchors.fill: parent
                                        radius: parent.radius
                                        source: root.player ? root.player.trackArtUrl : ""
                                        sourceSize: Qt.size(136, 136)
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    M3.Label {
                                        Layout.fillWidth: true
                                        text: root.player ? root.player.trackTitle : "No media"
                                        font.pixelSize: Theme.typeTitle
                                        font.weight: Font.Bold
                                    }

                                    M3.Label {
                                        Layout.fillWidth: true
                                        text: root.player ? root.player.trackArtist : "Nothing playing"
                                        color: Theme.textOnSurfaceVariant
                                        font.pixelSize: Theme.typeLabel
                                    }
                                }

                                M3.IconButton {
                                    icon: "\u{f04ae}"
                                    onClicked: if (root.player) root.player.previous()
                                }

                                M3.IconButton {
                                    size: 52
                                    variant: "filled"
                                    toggle: true
                                    checked: root.player !== null && root.player.playbackState === MprisPlaybackState.Playing
                                    icon: checked ? "\u{f03e4}" : "\u{f040a}"
                                    onClicked: if (root.player) root.player.togglePlaying()
                                }

                                M3.IconButton {
                                    icon: "\u{f04ad}"
                                    onClicked: if (root.player) root.player.next()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
