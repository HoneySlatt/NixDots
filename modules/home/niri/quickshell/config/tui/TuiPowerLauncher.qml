import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "services" as Services
import Quickshell.Services.Mpris

Item {
    id: scope

    readonly property int entryCount: 14

    function barStr(value, slots) {
        let count = slots || 42;
        let filled = Math.max(0, Math.min(count, Math.round(value / 100 * count)));
        let out = "";
        for (let i = 0; i < filled; i++) out += "█";
        for (let i = filled; i < count; i++) out += "░";
        return out;
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root

            required property var modelData
            screen: modelData
            visible: TuiPowerLauncherState.visible && monitorIsFocused

            readonly property bool monitorIsFocused: Services.NiriData.focusedOutput === root.screen.name
            readonly property MprisPlayer player: {
                const players = Mpris.players.values;
                if (players.length === 0) return null;
                const playing = players.find(p => p.playbackState === MprisPlaybackState.Playing);
                return playing ?? players[0];
            }

            property int selectedIndex: 0
            property bool bluetoothPowered: false
            property bool dndEnabled: false
            property bool nightLightEnabled: false
            property int brightness: 0
            property string batteryText: "--"

            color: "transparent"

            WlrLayershell.namespace: "quickshell:tui:powerlauncher"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors { top: true; bottom: true; left: true; right: true }

            function clampSelection() {
                selectedIndex = Math.max(0, Math.min(scope.entryCount - 1, selectedIndex));
            }

            function refreshSystemState() {
                if (!bluetoothProc.running) bluetoothProc.running = true;
                if (!dndProc.running) dndProc.running = true;
                if (!brightnessProc.running) brightnessProc.running = true;
                if (!nightLightProc.running) nightLightProc.running = true;
                if (!batteryProc.running) batteryProc.running = true;
            }

            function initializeLauncher() {
                selectedIndex = 0;
                refreshSystemState();
                focusTimer.start();
            }

            function setBrightness(value) {
                brightness = Math.max(0, Math.min(100, value));
                brightnessSetProc.command = ["brightnessctl", "set", brightness + "%"];
                brightnessSetProc.running = true;
            }

            function executeCommand(command) {
                Quickshell.execDetached(["sh", "-c", command]);
                TuiPowerLauncherState.close();
            }

            function entryLabel(index) {
                switch (index) {
                case 0: return "Wi-Fi";
                case 1: return "Bluetooth";
                case 2: return "NymVPN";
                case 3: return "DND";
                case 4: return "Volume";
                case 5: return "Brightness";
                case 6: return "Prev";
                case 7: return player && player.playbackState === MprisPlaybackState.Playing ? "Pause" : "Play";
                case 8: return "Next";
                case 9: return "Night";
                case 10: return "Lock";
                case 11: return "Logout";
                case 12: return "Reboot";
                case 13: return "Shutdown";
                default: return "";
                }
            }

            function entryIcon(index) {
                switch (index) {
                case 0: return "\uf1eb";
                case 1: return "\uf293";
                case 2: return "\uf132";
                case 3: return "\uf186";
                case 4: return TuiVolumeState.muted ? "\uf026" : "\uf028";
                case 5: return "\uf185";
                case 6: return "\uf04a";
                case 7: return player && player.playbackState === MprisPlaybackState.Playing ? "\uf04c" : "\uf04b";
                case 8: return "\uf04e";
                case 9: return "\uf186";
                case 10: return "\uf023";
                case 11: return "\uf2f5";
                case 12: return "\uf021";
                case 13: return "\uf011";
                default: return "";
                }
            }

            function entryValue(index) {
                switch (index) {
                case 0: return TuiNetworkState.wifiEnabled ? (TuiNetworkState.connectionName || TuiNetworkState.netType) : "off";
                case 1: return bluetoothPowered ? "on" : "off";
                case 2: return TuiNetworkState.vpnConnected ? "on" : "off";
                case 3: return dndEnabled ? "on" : "off";
                case 4: return (TuiVolumeState.muted ? "muted " : "") + TuiVolumeState.volume + "%";
                case 5: return brightness + "%";
                case 6:
                case 7:
                case 8: return player ? (player.trackTitle || "media") : "none";
                case 9: return nightLightEnabled ? "on" : "off";
                default: return "";
                }
            }

            function entryActive(index) {
                switch (index) {
                case 0: return TuiNetworkState.wifiEnabled && TuiNetworkState.netType !== "offline";
                case 1: return bluetoothPowered;
                case 2: return TuiNetworkState.vpnConnected;
                case 3: return dndEnabled;
                case 4: return !TuiVolumeState.muted && TuiVolumeState.volume > 0;
                case 5: return brightness > 0;
                case 7: return player && player.playbackState === MprisPlaybackState.Playing;
                case 9: return nightLightEnabled;
                default: return false;
                }
            }

            function triggerEntry(index) {
                switch (index) {
                case 0:
                    TuiNetworkState.toggleWifi();
                    return;
                case 1:
                    bluetoothToggleProc.running = true;
                    return;
                case 2:
                    vpnToggleProc.running = true;
                    return;
                case 3:
                    dndToggleProc.running = true;
                    return;
                case 4:
                    TuiVolumeState.toggleMute();
                    return;
                case 6:
                    if (player) player.previous();
                    return;
                case 7:
                    if (player) player.togglePlaying();
                    return;
                case 8:
                    if (player) player.next();
                    return;
                case 9:
                    nightLightToggleProc.running = true;
                    return;
                case 10:
                    executeCommand("lock-screen");
                    return;
                case 11:
                    executeCommand("niri msg action quit");
                    return;
                case 12:
                    executeCommand("systemctl reboot");
                    return;
                case 13:
                    executeCommand("systemctl poweroff");
                    return;
                }
            }

            function handleHorizontal(delta) {
                if (selectedIndex === 4) {
                    TuiVolumeState.setVolume(TuiVolumeState.volume + delta * 5);
                    return;
                }
                if (selectedIndex === 5) {
                    setBrightness(brightness + delta * 5);
                    return;
                }
                selectedIndex += delta;
                clampSelection();
            }

            function handleKey(event) {
                if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) {
                    TuiPowerLauncherState.close();
                    event.accepted = true;
                    return;
                }

                if (event.text.length > 0 && !event.modifiers) {
                    switch (event.text.toLowerCase()) {
                    case "s": executeCommand("systemctl poweroff"); event.accepted = true; return;
                    case "r": executeCommand("systemctl reboot"); event.accepted = true; return;
                    case "x": executeCommand("niri msg action quit"); event.accepted = true; return;
                    case "o": executeCommand("lock-screen"); event.accepted = true; return;
                    case "m": TuiVolumeState.toggleMute(); event.accepted = true; return;
                    case "n": nightLightToggleProc.running = true; event.accepted = true; return;
                    case "w": TuiNetworkState.toggleWifi(); event.accepted = true; return;
                    case "b": bluetoothToggleProc.running = true; event.accepted = true; return;
                    case "v": vpnToggleProc.running = true; event.accepted = true; return;
                    case "d": dndToggleProc.running = true; event.accepted = true; return;
                    case "p": if (player) player.togglePlaying(); event.accepted = true; return;
                    }
                }

                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    triggerEntry(selectedIndex);
                    event.accepted = true;
                    return;
                }
                if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
                    selectedIndex += 1;
                    clampSelection();
                    event.accepted = true;
                    return;
                }
                if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
                    selectedIndex -= 1;
                    clampSelection();
                    event.accepted = true;
                    return;
                }
                if (event.key === Qt.Key_H || event.key === Qt.Key_Left) {
                    handleHorizontal(-1);
                    event.accepted = true;
                    return;
                }
                if (event.key === Qt.Key_L || event.key === Qt.Key_Right) {
                    handleHorizontal(1);
                    event.accepted = true;
                }
            }

            Process { id: bluetoothProc; command: ["bluetoothctl", "show"]; running: false; stdout: StdioCollector { onStreamFinished: root.bluetoothPowered = this.text.includes("Powered: yes") } }
            Process { id: bluetoothToggleProc; command: ["bash", "-c", "if bluetoothctl show | grep -q 'Powered: yes'; then bluetoothctl power off; else bluetoothctl power on; fi"]; running: false; onExited: bluetoothProc.running = true }
            Process { id: dndProc; command: ["swaync-client", "-D"]; running: false; stdout: StdioCollector { onStreamFinished: root.dndEnabled = this.text.trim() === "true" } }
            Process { id: dndToggleProc; command: ["swaync-client", "-d"]; running: false; onExited: dndProc.running = true }
            Process {
                id: brightnessProc
                command: ["bash", "-c", "cur=$(brightnessctl g 2>/dev/null || echo 0); max=$(brightnessctl m 2>/dev/null || echo 1); awk -v c=\"$cur\" -v m=\"$max\" 'BEGIN { if (m <= 0) m = 1; printf \"%d\", (c / m) * 100 }'"]
                running: false
                stdout: StdioCollector { onStreamFinished: { let value = parseInt(this.text.trim()); if (!isNaN(value)) root.brightness = Math.max(0, Math.min(100, value)); } }
            }
            Process { id: brightnessSetProc; running: false; onExited: brightnessProc.running = true }
            Process { id: vpnToggleProc; command: ["/etc/profiles/per-user/honey/bin/toggle-nym"]; running: false }
            Process { id: nightLightProc; command: ["pgrep", "-x", "wlsunset"]; running: false; onExited: exitCode => root.nightLightEnabled = exitCode === 0 }
            Process { id: nightLightToggleProc; command: ["bash", "-c", "if pgrep -x wlsunset >/dev/null; then pkill wlsunset; else wlsunset -T 6001 -t 6000 >/dev/null 2>&1 & fi"]; running: false; onExited: nightLightProc.running = true }
            Process {
                id: batteryProc
                command: ["bash", "-c", "for d in /sys/class/power_supply/*; do [ -e \"$d/capacity\" ] || continue; [ \"$(cat \"$d/type\" 2>/dev/null)\" = Battery ] || continue; base=${d##*/}; case \"$base\" in hidpp_*|ps-controller-*) continue;; esac; cat \"$d/capacity\"; exit 0; done; echo --"]
                running: false
                stdout: StdioCollector { onStreamFinished: { let value = this.text.trim(); root.batteryText = value === "--" ? "--" : value + "%"; } }
            }

            Component.onCompleted: {
                if (TuiPowerLauncherState.visible) root.initializeLauncher();
            }

            Connections {
                target: TuiPowerLauncherState
                function onVisibleChanged() {
                    if (TuiPowerLauncherState.visible) root.initializeLauncher();
                    else {
                        focusTimer.stop();
                    }
                }
            }

            Timer { id: focusTimer; interval: 80; repeat: false; onTriggered: panel.forceActiveFocus() }
            Timer { interval: 2000; running: TuiPowerLauncherState.visible; repeat: true; onTriggered: root.refreshSystemState() }

            MouseArea { anchors.fill: parent; onClicked: TuiPowerLauncherState.close() }

            Rectangle {
                id: panel
                anchors.centerIn: parent
                width: 860
                height: 520
                color: TuiTheme.barBg
                border.color: TuiTheme.barBorder
                border.width: 1
                focus: TuiPowerLauncherState.visible

                MouseArea { anchors.fill: parent; onClicked: panel.forceActiveFocus() }
                Keys.onPressed: event => root.handleKey(event)

                Rectangle { anchors.fill: parent; anchors.margins: 4; color: "transparent"; border.color: TuiTheme.barInnerBorder; border.width: 1 }

                Rectangle {
                    id: quickFrame
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    anchors.topMargin: 28
                    height: 124
                    color: "transparent"
                    border.color: TuiTheme.barInnerBorder
                    border.width: 1

                    Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.leftMargin: 14; anchors.topMargin: -1; width: quickTitle.implicitWidth + 16; height: 18; color: TuiTheme.barBg }
                    Text { id: quickTitle; anchors.left: parent.left; anchors.top: parent.top; anchors.leftMargin: 22; anchors.topMargin: -2; text: "POWER"; color: TuiTheme.barMuted; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.fontSize; font.weight: TuiTheme.fontWeight }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 0

                        Repeater {
                            model: [0, 1, 2, 3]

                            delegate: Rectangle {
                                id: toggleTile
                                required property int modelData
                                readonly property bool selected: root.selectedIndex === modelData
                                readonly property bool active: root.entryActive(modelData)

                                width: parent.width / 4
                                height: parent.height
                                color: selected ? TuiTheme.barHover : "transparent"
                                border.color: selected ? TuiTheme.highlight : TuiTheme.barInnerBorder
                                border.width: selected ? 2 : 1

                                Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; anchors.leftMargin: 22; text: root.entryIcon(toggleTile.modelData); color: toggleTile.active ? TuiTheme.highlight : TuiTheme.barMuted; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.barIconSize + 6; font.weight: TuiTheme.fontWeight }
                                Text { anchors.left: parent.left; anchors.top: parent.top; anchors.leftMargin: 74; anchors.topMargin: 28; text: root.entryLabel(toggleTile.modelData); color: TuiTheme.barText; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.fontSize + 1; font.weight: TuiTheme.fontWeight }
                                Text { anchors.left: parent.left; anchors.top: parent.top; anchors.leftMargin: 74; anchors.topMargin: 56; width: parent.width - 86; text: root.entryValue(toggleTile.modelData); color: toggleTile.active ? TuiTheme.highlight : TuiTheme.barMuted; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.fontSize; font.weight: TuiTheme.fontWeight; elide: Text.ElideRight }

                                MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: root.selectedIndex = toggleTile.modelData; onClicked: root.triggerEntry(toggleTile.modelData) }
                            }
                        }
                    }
                }

                Column {
                    id: middleRows
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: quickFrame.bottom
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    anchors.topMargin: 18
                    spacing: 0

                    Repeater {
                        model: [4, 5]

                        delegate: Rectangle {
                            id: meter
                            required property int modelData
                            readonly property bool selected: root.selectedIndex === modelData
                            readonly property int value: modelData === 4 ? TuiVolumeState.volume : root.brightness

                            width: parent.width
                            height: 54
                            color: selected ? TuiTheme.barHover : "transparent"
                            border.color: selected ? TuiTheme.highlight : TuiTheme.barInnerBorder
                            border.width: selected ? 2 : 1

                            Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; anchors.leftMargin: 22; text: root.entryIcon(meter.modelData); color: TuiTheme.highlight; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.barIconSize; font.weight: TuiTheme.fontWeight }
                            Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; anchors.leftMargin: 62; width: 120; text: root.entryLabel(meter.modelData); color: TuiTheme.barText; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.fontSize; font.weight: TuiTheme.fontWeight }
                            Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; anchors.leftMargin: 178; text: "[-]"; color: TuiTheme.barMuted; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.fontSize; font.weight: TuiTheme.fontWeight }
                            Text { id: meterBar; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; anchors.leftMargin: 250; text: scope.barStr(meter.value, 48); color: TuiTheme.barText; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.fontSize; font.weight: TuiTheme.fontWeight }
                            Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.rightMargin: 24; width: 58; horizontalAlignment: Text.AlignRight; text: root.entryValue(meter.modelData); color: TuiTheme.barMuted; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.fontSize; font.weight: TuiTheme.fontWeight }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                preventStealing: true
                                onEntered: root.selectedIndex = meter.modelData
                                function setFromMouse(mouse) {
                                    let mapped = meterBar.mapToItem(meter, 0, 0);
                                    let value = Math.max(0, Math.min(100, Math.round((mouse.x - mapped.x) / meterBar.width * 100)));
                                    if (meter.modelData === 4) TuiVolumeState.setVolume(value);
                                    else root.setBrightness(value);
                                }
                                onPressed: mouse => setFromMouse(mouse)
                                onPositionChanged: mouse => { if (pressed) setFromMouse(mouse); }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 78
                        color: "transparent"
                        border.color: TuiTheme.barInnerBorder
                        border.width: 1

                        Text { anchors.left: parent.left; anchors.top: parent.top; anchors.leftMargin: 22; anchors.topMargin: 14; text: "Media"; color: TuiTheme.barText; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.fontSize; font.weight: TuiTheme.fontWeight }
                        Text { anchors.left: parent.left; anchors.top: parent.top; anchors.leftMargin: 22; anchors.topMargin: 42; width: parent.width - 280; text: root.player ? (root.player.trackTitle || "media") : "No media playing"; color: TuiTheme.barMuted; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.fontSize; font.weight: TuiTheme.fontWeight; elide: Text.ElideRight }

                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.rightMargin: 18
                            spacing: 0

                            Repeater {
                                model: [6, 7, 8]

                                delegate: Rectangle {
                                    id: mediaButton
                                    required property int modelData
                                    readonly property bool selected: root.selectedIndex === modelData

                                    width: 74
                                    height: 46
                                    color: selected ? TuiTheme.barHover : "transparent"
                                    border.color: selected ? TuiTheme.highlight : TuiTheme.barInnerBorder
                                    border.width: selected ? 2 : 1

                                    Text { anchors.centerIn: parent; text: root.entryIcon(mediaButton.modelData); color: TuiTheme.barText; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.barIconSize; font.weight: TuiTheme.fontWeight }
                                    MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: root.selectedIndex = mediaButton.modelData; onClicked: root.triggerEntry(mediaButton.modelData) }
                                }
                            }
                        }
                    }
                }

                Row {
                    id: powerRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: middleRows.bottom
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    anchors.topMargin: 22
                    height: 58
                    spacing: 0

                    Repeater {
                        model: [10, 11, 12, 13]

                        delegate: Rectangle {
                            id: powerButton
                            required property int modelData
                            readonly property bool selected: root.selectedIndex === modelData

                            width: parent.width / 4
                            height: parent.height
                            color: selected ? TuiTheme.barHover : "transparent"
                            border.color: selected ? TuiTheme.warn : TuiTheme.barInnerBorder
                            border.width: selected ? 2 : 1

                            Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; anchors.leftMargin: 24; text: root.entryIcon(powerButton.modelData); color: TuiTheme.warn; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.barIconSize; font.weight: TuiTheme.fontWeight }
                            Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; anchors.leftMargin: 72; text: root.entryLabel(powerButton.modelData); color: TuiTheme.barText; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.fontSize; font.weight: TuiTheme.fontWeight }
                            MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: root.selectedIndex = powerButton.modelData; onClicked: root.triggerEntry(powerButton.modelData) }
                        }
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 48
                    color: "transparent"
                    border.color: TuiTheme.barInnerBorder
                    border.width: 1

                    Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; anchors.leftMargin: 24; text: "BATTERY   " + root.batteryText + "  [" + scope.barStr(parseInt(root.batteryText) || 0, 20) + "]"; color: TuiTheme.barText; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.fontSize; font.weight: TuiTheme.fontWeight }
                    Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.rightMargin: 24; text: "[Q] Quit   [↑/↓] Navigate   [←/→] Adjust   [Enter] Select"; color: TuiTheme.barMuted; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.fontSize; font.weight: TuiTheme.fontWeight }
                }
            }
        }
    }
}
