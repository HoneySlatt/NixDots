import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Mpris
import "services" as Services
import "m3" as M3

Item {
    id: powerMenuScope

    readonly property int entryCount: 14
    readonly property int powerStartIndex: 10

    component SliderEntry: Item {
        id: sliderEntry

        property int entry: 0
        property alias slider: control

        height: 48

        M3.Slider {
            id: control
            anchors.fill: parent
            trackHeight: 36
            handleHeight: 48
        }

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 6
            anchors.bottomMargin: 6
            radius: 22
            color: "transparent"

            M3.FocusRing { shown: root.selectedIndex === sliderEntry.entry }
        }

        HoverHandler {
            onHoveredChanged: if (hovered) root.selectedIndex = sliderEntry.entry
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root

            required property var modelData
            screen: modelData
            visible: PowerMenuState.visible && monitorIsFocused

            readonly property bool monitorIsFocused: Services.NiriData.activeWorkspace !== null && Services.NiriData.activeWorkspace.output === root.screen.name
            onMonitorIsFocusedChanged: if (!monitorIsFocused) PowerMenuState.close()
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

            WlrLayershell.namespace: "quickshell:powermenu"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore
            anchors { top: true; bottom: true; left: true; right: true }

            function clampSelection() {
                selectedIndex = Math.max(0, Math.min(powerMenuScope.entryCount - 1, selectedIndex));
            }

            function refreshSystemState() {
                if (!bluetoothProc.running) bluetoothProc.running = true;
                if (!dndProc.running) dndProc.running = true;
                if (!brightnessProc.running) brightnessProc.running = true;
                if (!nightLightProc.running) nightLightProc.running = true;
                if (!batteryProc.running) batteryProc.running = true;
            }

            function initializeMenu() {
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
                PowerMenuState.close();
            }

            function entryTitle(index) {
                switch (index) {
                case 0: return "Wi-Fi";
                case 1: return "Bluetooth";
                case 2: return "VPN";
                case 3: return "DND";
                case 4: return "Volume";
                case 5: return "Brightness";
                case 6: return "Previous";
                case 7: return player && player.playbackState === MprisPlaybackState.Playing ? "Pause" : "Play";
                case 8: return "Next";
                case 9: return "Night Light";
                case 10: return "Lock";
                case 11: return "Logout";
                case 12: return "Reboot";
                case 13: return "Shutdown";
                default: return "";
                }
            }

            function entryValue(index) {
                switch (index) {
                case 0: return NetworkState.wifiEnabled ? (NetworkState.connectionName || NetworkState.netType) : "Off";
                case 1: return bluetoothPowered ? "On" : "Off";
                case 2: return NetworkState.vpnConnected ? "On" : "Off";
                case 3: return dndEnabled ? "On" : "Off";
                case 4: return (VolumeState.muted ? "Muted " : "") + VolumeState.volume + "%";
                case 5: return brightness + "%";
                case 9: return nightLightEnabled ? "On" : "Off";
                default: return "";
                }
            }

            function entryIcon(index) {
                switch (index) {
                case 0: return "wifi";
                case 1: return "bluetooth";
                case 2: return "shield_lock";
                case 3: return "do_not_disturb_on";
                case 4: return VolumeState.muted ? "volume_off" : "volume_up";
                case 5: return "brightness_6";
                case 6: return "skip_previous";
                case 7: return player && player.playbackState === MprisPlaybackState.Playing ? "pause" : "play_arrow";
                case 8: return "skip_next";
                case 9: return "nightlight";
                case 10: return "lock";
                case 11: return "logout";
                case 12: return "restart_alt";
                case 13: return "power_settings_new";
                default: return "";
                }
            }

            function entryActive(index) {
                switch (index) {
                case 0: return NetworkState.wifiEnabled && NetworkState.netType !== "offline";
                case 1: return bluetoothPowered;
                case 2: return NetworkState.vpnConnected;
                case 3: return dndEnabled;
                case 4: return !VolumeState.muted && VolumeState.volume > 0;
                case 5: return brightness > 0;
                case 7: return player && player.playbackState === MprisPlaybackState.Playing;
                case 9: return nightLightEnabled;
                default: return false;
                }
            }

            function triggerEntry(index) {
                switch (index) {
                case 0:
                    NetworkState.toggleWifi();
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
                    VolumeState.toggleMute();
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
                    VolumeState.setVolume(VolumeState.volume + delta * 5);
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
                if (event.key === Qt.Key_Escape) {
                    PowerMenuState.close();
                    event.accepted = true;
                    return;
                }

                const key = event.text ? event.text.toLowerCase() : "";
                if (key === "s") {
                    executeCommand("systemctl poweroff");
                    event.accepted = true;
                    return;
                }
                if (key === "r") {
                    executeCommand("systemctl reboot");
                    event.accepted = true;
                    return;
                }
                if (key === "x" || key === "e") {
                    executeCommand("niri msg action quit");
                    event.accepted = true;
                    return;
                }
                if (key === "o") {
                    executeCommand("lock-screen");
                    event.accepted = true;
                    return;
                }
                if (key === "m") {
                    VolumeState.toggleMute();
                    event.accepted = true;
                    return;
                }
                if (key === "n") {
                    nightLightToggleProc.running = true;
                    event.accepted = true;
                    return;
                }
                if (key === "w") {
                    NetworkState.toggleWifi();
                    event.accepted = true;
                    return;
                }
                if (key === "b") {
                    bluetoothToggleProc.running = true;
                    event.accepted = true;
                    return;
                }
                if (key === "v") {
                    vpnToggleProc.running = true;
                    event.accepted = true;
                    return;
                }
                if (key === "d") {
                    dndToggleProc.running = true;
                    event.accepted = true;
                    return;
                }
                if (key === "p") {
                    if (player) player.togglePlaying();
                    event.accepted = true;
                    return;
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

            Process {
                id: bluetoothProc
                command: ["bluetoothctl", "show"]
                running: false
                stdout: StdioCollector { onStreamFinished: root.bluetoothPowered = this.text.includes("Powered: yes") }
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
                stdout: StdioCollector { onStreamFinished: root.dndEnabled = this.text.trim() === "true" }
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
                id: vpnToggleProc
                command: ["/etc/profiles/per-user/honey/bin/toggle-nym"]
                running: false
            }

            Process {
                id: nightLightProc
                command: ["pgrep", "-x", "wlsunset"]
                running: false
                onExited: root.nightLightEnabled = exitCode === 0
            }

            Process {
                id: nightLightToggleProc
                command: ["bash", "-c", "if pgrep -x wlsunset >/dev/null; then pkill wlsunset; else wlsunset -T 6001 -t 6000 >/dev/null 2>&1 & fi"]
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

            Component.onCompleted: {
                if (PowerMenuState.visible) root.initializeMenu();
            }

            Connections {
                target: PowerMenuState
                function onVisibleChanged() {
                    if (PowerMenuState.visible) {
                        root.initializeMenu();
                    }
                }
            }

            Timer {
                id: focusTimer
                interval: 80
                repeat: false
                onTriggered: panel.forceActiveFocus()
            }

            Timer {
                interval: 2000
                running: PowerMenuState.visible
                repeat: true
                onTriggered: root.refreshSystemState()
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.scrim
            }

            MouseArea {
                anchors.fill: parent
                onClicked: PowerMenuState.close()
            }

            M3.Surface {
                id: panel
                anchors.centerIn: parent
                width: 720
                height: contentCol.implicitHeight + 48
                radius: Theme.shapeXLI
                growFrom: "center"
                focus: PowerMenuState.visible

                MouseArea { anchors.fill: parent; onClicked: panel.forceActiveFocus() }
                Keys.onPressed: event => root.handleKey(event)

                Column {
                    id: contentCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 20
                    spacing: 12

                    RowLayout {
                        width: parent.width

                        M3.Label {
                            Layout.fillWidth: true
                            text: "Power"
                            font.pixelSize: Theme.typeHeadline
                            font.weight: Font.Bold
                        }

                        M3.Chip {
                            visible: root.batteryText !== "--"
                            clickable: false
                            icon: "battery_full"
                            text: root.batteryText
                        }
                    }

                    GridLayout {
                        width: parent.width
                        columns: 4
                        columnSpacing: 8

                        Repeater {
                            model: [0, 1, 2, 3]
                            delegate: M3.QuickTile {
                                required property int modelData
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                icon: root.entryIcon(modelData)
                                title: root.entryTitle(modelData)
                                subtitle: root.entryValue(modelData)
                                active: root.entryActive(modelData)
                                selected: root.selectedIndex === modelData
                                onEntered: root.selectedIndex = modelData
                                onClicked: root.triggerEntry(modelData)
                            }
                        }
                    }

                    SliderEntry {
                        width: parent.width
                        entry: 4
                        slider.icon: root.entryIcon(4)
                        slider.iconClickable: true
                        slider.value: VolumeState.volume
                        slider.muted: VolumeState.muted
                        slider.onIconClicked: VolumeState.toggleMute()
                        slider.onMoved: value => VolumeState.setVolume(value)
                    }

                    SliderEntry {
                        width: parent.width
                        entry: 5
                        slider.icon: root.entryIcon(5)
                        slider.value: root.brightness
                        slider.onMoved: value => root.setBrightness(value)
                    }

                    Rectangle {
                        width: parent.width
                        height: 76
                        radius: Theme.shapeXL
                        color: Theme.surfaceContainerHighest

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 16
                            spacing: 14

                            Rectangle {
                                Layout.preferredWidth: 52
                                Layout.preferredHeight: 52
                                radius: Theme.shapeL
                                color: Theme.surfaceContainerHigh

                                M3.Icon {
                                    anchors.centerIn: parent
                                    visible: menuCover.status !== Image.Ready
                                    icon: "music_note"
                                    size: 26
                                    color: Theme.textOnSurfaceVariant
                                }

                                M3.RoundedImage {
                                    id: menuCover
                                    anchors.fill: parent
                                    radius: parent.radius
                                    source: root.player ? root.player.trackArtUrl : ""
                                    sourceSize: Qt.size(120, 120)
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                M3.Label {
                                    Layout.fillWidth: true
                                    text: root.player ? (root.player.trackTitle || "Media") : "No media"
                                    font.pixelSize: Theme.typeTitle
                                    font.weight: Font.Bold
                                }

                                M3.Label {
                                    Layout.fillWidth: true
                                    text: root.player ? (root.player.trackArtist || "") : "Nothing playing"
                                    color: Theme.textOnSurfaceVariant
                                    font.pixelSize: Theme.typeLabel
                                }
                            }

                            Repeater {
                                model: [6, 7, 8, 9]
                                delegate: M3.IconButton {
                                    required property int modelData
                                    size: modelData === 7 ? 56 : 48
                                    implicitWidth: modelData === 7 ? 72 : 48
                                    variant: modelData === 7 ? "filled" : "tonal"
                                    toggle: modelData === 7 || modelData === 9
                                    checked: root.entryActive(modelData)
                                    icon: root.entryIcon(modelData)
                                    onClicked: root.triggerEntry(modelData)

                                    M3.FocusRing { shown: root.selectedIndex === modelData }
                                    HoverHandler { onHoveredChanged: if (hovered) root.selectedIndex = modelData }
                                }
                            }
                        }
                    }

                    Row {
                        id: powerRow
                        width: parent.width
                        spacing: 2

                        Repeater {
                            model: [10, 11, 12, 13]
                            delegate: M3.Button {
                                required property int modelData
                                required property int index
                                width: (powerRow.width - 3 * powerRow.spacing) / 4
                                size: 52
                                variant: "error"
                                grouped: true
                                groupStart: index === 0
                                groupEnd: index === 3
                                icon: root.entryIcon(modelData)
                                text: root.entryTitle(modelData)
                                onClicked: root.triggerEntry(modelData)

                                M3.FocusRing { shown: root.selectedIndex === modelData }
                                HoverHandler { onHoveredChanged: if (hovered) root.selectedIndex = modelData }
                            }
                        }
                    }
                }
            }
        }
    }
}
