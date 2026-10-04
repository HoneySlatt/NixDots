import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Mpris
import "services" as Services

Item {
    id: powerMenuScope

    readonly property int entryCount: 14
    readonly property int powerStartIndex: 10

    component GlassPanel: Rectangle {
        property color fillColor: Theme.card

        radius: 26
        color: "transparent"
        border.color: Qt.tint(Theme.separator, Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.34))
        border.width: 1
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.tint(fillColor, Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)) }
            GradientStop { position: 0.58; color: fillColor }
            GradientStop { position: 1.0; color: Qt.tint(fillColor, Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.20)) }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 28
            anchors.rightMargin: 28
            anchors.topMargin: 1
            height: 1
            radius: 1
            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.16)
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius - 1
            color: "transparent"
            border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.10)
            border.width: 1
        }
    }

    component StatusCard: Rectangle {
        id: statusCard

        property string icon: ""
        property string title: ""
        property string value: ""
        property bool selected: false
        property bool danger: false
        property bool active: false
        signal clicked()
        signal hovered()

        radius: 16
        color: selected || cardMouse.containsMouse
            ? Qt.rgba((danger ? Theme.warning : Theme.accent).r, (danger ? Theme.warning : Theme.accent).g, (danger ? Theme.warning : Theme.accent).b, 0.14)
            : Qt.rgba(Theme.separator.r, Theme.separator.g, Theme.separator.b, 0.32)
        border.color: selected
            ? Qt.rgba((danger ? Theme.warning : Theme.accent).r, (danger ? Theme.warning : Theme.accent).g, (danger ? Theme.warning : Theme.accent).b, 0.58)
            : active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.38)
            : Qt.rgba(Theme.separator.r, Theme.separator.g, Theme.separator.b, 0.42)
        border.width: selected ? 2 : 1

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 42
                Layout.preferredHeight: 42
                radius: 21
                color: Qt.rgba((statusCard.danger ? Theme.warning : Theme.accent).r, (statusCard.danger ? Theme.warning : Theme.accent).g, (statusCard.danger ? Theme.warning : Theme.accent).b, statusCard.active || statusCard.selected ? 0.22 : 0.10)
                border.color: Qt.rgba((statusCard.danger ? Theme.warning : Theme.accent).r, (statusCard.danger ? Theme.warning : Theme.accent).g, (statusCard.danger ? Theme.warning : Theme.accent).b, statusCard.active || statusCard.selected ? 0.44 : 0.20)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: statusCard.icon
                    color: statusCard.danger ? Theme.warning : statusCard.active || statusCard.selected ? Theme.accent : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 10
                }
            }

            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: statusCard.title
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: statusCard.value
                    color: statusCard.active || statusCard.selected ? (statusCard.danger ? Theme.warning : Theme.accent) : Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    font.weight: Theme.fontWeight
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: statusCard.hovered()
            onClicked: statusCard.clicked()
        }
    }

    component MeterCard: Rectangle {
        id: meterCard

        property string icon: ""
        property string title: ""
        property int value: 0
        property bool muted: false
        property bool selected: false
        signal hovered()
        signal valueSelected(int percent)
        signal iconClicked()

        radius: 16
        color: selected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.13)
            : Qt.rgba(Theme.separator.r, Theme.separator.g, Theme.separator.b, 0.32)
        border.color: selected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.58)
            : Qt.rgba(Theme.separator.r, Theme.separator.g, Theme.separator.b, 0.42)
        border.width: selected ? 2 : 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 12

            Text {
                text: meterCard.icon
                color: meterCard.muted ? Theme.muted : meterCard.selected ? Theme.accent : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 8
                Layout.preferredWidth: 28
                Layout.alignment: Qt.AlignVCenter

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: meterCard.iconClicked()
                }
            }

            Text {
                text: meterCard.title
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Font.Bold
                Layout.preferredWidth: 94
                Layout.alignment: Qt.AlignVCenter
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 5
                    radius: 3
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10)

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, meterCard.value / 100))
                        height: parent.height
                        radius: parent.radius
                        color: meterCard.muted ? Theme.muted : Theme.accent
                    }

                    Rectangle {
                        x: parent.width * Math.max(0, Math.min(1, meterCard.value / 100)) - width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 12
                        height: 12
                        radius: 6
                        color: Theme.text
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    preventStealing: true
                    onEntered: meterCard.hovered()
                    function setFromMouse(mouse) {
                        meterCard.valueSelected(Math.max(0, Math.min(100, Math.round(mouse.x / width * 100))));
                    }
                    onClicked: mouse => setFromMouse(mouse)
                    onPositionChanged: mouse => {
                        if (pressed) setFromMouse(mouse);
                    }
                }
            }

            Text {
                text: meterCard.value + "%"
                color: meterCard.selected ? Theme.accent : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Theme.fontWeight
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 42
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    component MediaButton: Rectangle {
        id: mediaButton

        property string icon: ""
        property bool active: false
        property bool selected: false
        signal clicked()
        signal hovered()

        radius: 13
        color: selected || mediaMouse.containsMouse
            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)
            : Qt.rgba(Theme.separator.r, Theme.separator.g, Theme.separator.b, 0.32)
        border.color: selected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.58)
            : active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.36)
            : Qt.rgba(Theme.separator.r, Theme.separator.g, Theme.separator.b, 0.42)
        border.width: selected ? 2 : 1

        Text {
            anchors.centerIn: parent
            text: mediaButton.icon
            color: mediaButton.active || mediaButton.selected ? Theme.accent : Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 8
        }

        MouseArea {
            id: mediaMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: mediaButton.hovered()
            onClicked: mediaButton.clicked()
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
                case 0: return "\uf1eb";
                case 1: return "\uf293";
                case 2: return "\uf132";
                case 3: return "\uf186";
                case 4: return VolumeState.muted ? "\uf026" : "\uf028";
                case 5: return "\uf185";
                case 6: return "\uf04a";
                case 7: return player && player.playbackState === MprisPlaybackState.Playing ? "\uf04c" : "\uf04b";
                case 8: return "\uf04e";
                case 9: return "\uf185";
                case 10: return "\uf023";
                case 11: return "\uf2f5";
                case 12: return "\uf021";
                case 13: return "\uf011";
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
                color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.58)
            }

            MouseArea {
                anchors.fill: parent
                onClicked: PowerMenuState.close()
            }

            GlassPanel {
                id: panel
                anchors.centerIn: parent
                width: 720
                height: 560
                focus: PowerMenuState.visible
                fillColor: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, Theme.popupOpacity)

                MouseArea { anchors.fill: parent; onClicked: panel.forceActiveFocus() }
                Keys.onPressed: event => root.handleKey(event)

                Column {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    RowLayout {
                        width: parent.width
                        height: 30

                        Text {
                            Layout.fillWidth: true
                            text: "Power"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize + 6
                            font.weight: Font.Bold
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: root.batteryText
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.weight: Theme.fontWeight
                            Layout.alignment: Qt.AlignVCenter
                        }

                    }

                    GridLayout {
                        width: parent.width
                        height: 158
                        columns: 4
                        rowSpacing: 10
                        columnSpacing: 10

                        Repeater {
                            model: [0, 1, 2, 3]
                            delegate: StatusCard {
                                required property int modelData
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                icon: root.entryIcon(modelData)
                                title: root.entryTitle(modelData)
                                value: root.entryValue(modelData)
                                active: root.entryActive(modelData)
                                selected: root.selectedIndex === modelData
                                onHovered: root.selectedIndex = modelData
                                onClicked: root.triggerEntry(modelData)
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 8

                        MeterCard {
                            width: parent.width
                            height: 48
                            icon: root.entryIcon(4)
                            title: root.entryTitle(4)
                            value: VolumeState.volume
                            muted: VolumeState.muted
                            selected: root.selectedIndex === 4
                            onHovered: root.selectedIndex = 4
                            onIconClicked: VolumeState.toggleMute()
                            onValueSelected: percent => VolumeState.setVolume(percent)
                        }

                        MeterCard {
                            width: parent.width
                            height: 48
                            icon: root.entryIcon(5)
                            title: root.entryTitle(5)
                            value: root.brightness
                            selected: root.selectedIndex === 5
                            onHovered: root.selectedIndex = 5
                            onValueSelected: percent => root.setBrightness(percent)
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 92
                        radius: 16
                        color: Qt.rgba(Theme.separator.r, Theme.separator.g, Theme.separator.b, 0.32)
                        border.color: Qt.rgba(Theme.separator.r, Theme.separator.g, Theme.separator.b, 0.42)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Column {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 4

                                Text {
                                    width: parent.width
                                    text: root.player ? (root.player.trackTitle || "Media") : "No media"
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize + 2
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: root.player ? (root.player.trackArtist || "") : ""
                                    color: Theme.muted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                    font.weight: Theme.fontWeight
                                    elide: Text.ElideRight
                                }
                            }

                            RowLayout {
                                Layout.preferredWidth: 300
                                Layout.fillHeight: true
                                spacing: 8

                                Repeater {
                                    model: [6, 7, 8, 9]
                                    delegate: MediaButton {
                                        required property int modelData
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        icon: root.entryIcon(modelData)
                                        active: root.entryActive(modelData)
                                        selected: root.selectedIndex === modelData
                                        onHovered: root.selectedIndex = modelData
                                        onClicked: root.triggerEntry(modelData)
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        width: parent.width
                        height: 76
                        spacing: 10

                        Repeater {
                            model: [10, 11, 12, 13]
                            delegate: StatusCard {
                                required property int modelData
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                icon: root.entryIcon(modelData)
                                title: root.entryTitle(modelData)
                                value: ""
                                danger: true
                                selected: root.selectedIndex === modelData
                                onHovered: root.selectedIndex = modelData
                                onClicked: root.triggerEntry(modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
