import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
    id: scope

    component GlassPanel: Rectangle {
        property color fillColor: Theme.card

        radius: 24
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
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            anchors.topMargin: 1
            height: 1
            radius: 1
            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.15)
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

    component ControlTile: Rectangle {
        id: tile

        property string icon: ""
        property string title: ""
        property string subtitle: ""
        property bool active: false
        signal clicked()

        radius: 18
        color: tileMouse.containsMouse
            ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.055)
            : Qt.rgba(Theme.separator.r, Theme.separator.g, Theme.separator.b, 0.34)
        border.color: active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.55)
            : Qt.rgba(Theme.separator.r, Theme.separator.g, Theme.separator.b, 0.55)
        border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: 8

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 54
                height: 54
                radius: 27
                color: tile.active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.28)
                    : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.055)
                border.color: tile.active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.62)
                    : Qt.rgba(Theme.separator.r, Theme.separator.g, Theme.separator.b, 0.60)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: tile.icon
                    color: tile.active ? Theme.accent : Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 15
                    font.weight: Font.Bold
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: tile.title
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Font.Bold
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: tile.width - 12
                text: tile.subtitle
                color: tile.active ? Theme.accent : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                font.weight: Theme.fontWeight
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: tileMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.clicked()
        }
    }

    component SliderRow: Rectangle {
        id: sliderRow

        property string icon: ""
        property string label: ""
        property int value: 0
        property bool muted: false
        signal valueSelected(int percent)
        signal iconClicked()

        radius: 14
        color: Qt.rgba(Theme.separator.r, Theme.separator.g, Theme.separator.b, 0.34)
        border.color: Qt.rgba(Theme.separator.r, Theme.separator.g, Theme.separator.b, 0.35)
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 12

            Text {
                text: sliderRow.icon
                color: sliderRow.muted ? Theme.muted : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 7
                Layout.alignment: Qt.AlignVCenter

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sliderRow.iconClicked()
                }
            }

            Text {
                text: sliderRow.label
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Font.Bold
                Layout.preferredWidth: 92
                Layout.alignment: Qt.AlignVCenter
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    id: sliderTrack
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 5
                    radius: 3
                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10)

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, sliderRow.value / 100))
                        height: parent.height
                        radius: parent.radius
                        color: sliderRow.muted ? Theme.muted : Theme.accent
                    }

                    Rectangle {
                        x: parent.width * Math.max(0, Math.min(1, sliderRow.value / 100)) - width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14
                        height: 14
                        radius: 7
                        color: Theme.text
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    preventStealing: true
                    function setFromMouse(mouse) {
                        sliderRow.valueSelected(Math.max(0, Math.min(100, Math.round(mouse.x / width * 100))));
                    }
                    onClicked: mouse => setFromMouse(mouse)
                    onPositionChanged: mouse => {
                        if (pressed) setFromMouse(mouse);
                    }
                }
            }

            Text {
                text: sliderRow.value + "%"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Theme.fontWeight
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 42
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    component BottomButton: Rectangle {
        id: bottomButton

        property string icon: ""
        property string title: ""
        property string subtitle: ""
        property bool active: false
        property bool danger: false
        property bool iconOnly: false
        signal clicked()

        radius: 14
        color: buttonMouse.containsMouse
            ? Qt.rgba((danger ? Theme.warning : Theme.text).r, (danger ? Theme.warning : Theme.text).g, (danger ? Theme.warning : Theme.text).b, 0.09)
            : Qt.rgba(Theme.separator.r, Theme.separator.g, Theme.separator.b, 0.34)
        border.color: active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.48)
            : Qt.rgba(Theme.separator.r, Theme.separator.g, Theme.separator.b, 0.35)
        border.width: 1

        RowLayout {
            visible: !bottomButton.iconOnly
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            Text {
                text: bottomButton.icon
                color: bottomButton.danger ? Theme.warning : bottomButton.active ? Theme.accent : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 9
                Layout.alignment: Qt.AlignVCenter
            }

            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 1

                Text {
                    width: parent.width
                    text: bottomButton.title
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 1
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: bottomButton.subtitle
                    color: bottomButton.active ? Theme.accent : Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    font.weight: Theme.fontWeight
                    elide: Text.ElideRight
                }
            }
        }

        Text {
            visible: bottomButton.iconOnly
            anchors.centerIn: parent
            text: bottomButton.icon
            color: bottomButton.danger ? Theme.warning : bottomButton.active ? Theme.accent : Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 18
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: bottomButton.clicked()
        }
    }

    component RoundCover: Item {
        id: roundCover

        property string source: ""

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Theme.subtle
            border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.28)
            border.width: 1
        }

        Canvas {
            anchors.fill: parent
            anchors.margins: 3
            renderTarget: Canvas.FramebufferObject
            smooth: true
            property string artUrl: roundCover.source

            onArtUrlChanged: {
                if (artUrl !== "") loadImage(artUrl);
                requestPaint();
            }

            onImageLoaded: requestPaint()

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const r = width / 2;
                ctx.beginPath();
                ctx.arc(r, r, r, 0, 2 * Math.PI);
                ctx.clip();
                if (artUrl !== "" && isImageLoaded(artUrl)) {
                    ctx.drawImage(artUrl, 0, 0, width, height);
                }
            }

            Component.onCompleted: {
                if (artUrl !== "") loadImage(artUrl);
            }
        }

        Text {
            anchors.centerIn: parent
            visible: roundCover.source === ""
            text: "\uf001"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 14
        }
    }

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

                Item {
                    id: popupClip
                    anchors.top: BarState.isTop ? parent.top : undefined
                    anchors.bottom: BarState.isTop ? undefined : parent.bottom
                    anchors.right: parent.right
                    anchors.rightMargin: BarState.isTop ? Theme.margin : 0
                    width: 520
                    height: root.showPowerActions ? 570 : 500
                    clip: true

                    GlassPanel {
                        anchors.fill: parent
                        anchors.topMargin: 0
                        anchors.bottomMargin: BarState.isTop ? 0 : -radius
                        height: parent.height + radius
                        fillColor: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, Theme.popupOpacity)
                    }

                    MouseArea { anchors.fill: parent }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 14

                        RowLayout {
                            width: parent.width
                            height: 118
                            spacing: 12

                            ControlTile {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                icon: "\uf1eb"
                                title: "Wi-Fi"
                                subtitle: NetworkState.netType === "wifi" ? NetworkState.connectionName : NetworkState.netType === "ethernet" ? "Ethernet" : "Off"
                                active: NetworkState.netType !== "offline"
                                onClicked: wifiToggleProc.running = true
                            }

                            ControlTile {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                icon: "\uf293"
                                title: "Bluetooth"
                                subtitle: root.bluetoothPowered ? "On" : "Off"
                                active: root.bluetoothPowered
                                onClicked: bluetoothToggleProc.running = true
                            }

                            ControlTile {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                icon: "\uf132"
                                title: "VPN"
                                subtitle: NetworkState.vpnConnected ? "On" : "Off"
                                active: NetworkState.vpnConnected
                                onClicked: vpnToggleProc.running = true
                            }

                            ControlTile {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                icon: "\uf186"
                                title: "DND"
                                subtitle: root.dndEnabled ? "On" : "Off"
                                active: root.dndEnabled
                                onClicked: dndToggleProc.running = true
                            }
                        }

                        SliderRow {
                            width: parent.width
                            height: 56
                            icon: VolumeState.muted ? "\uf026" : "\uf028"
                            label: "Volume"
                            value: VolumeState.volume
                            muted: VolumeState.muted
                            onIconClicked: VolumeState.toggleMute()
                            onValueSelected: percent => VolumeState.setVolume(percent)
                        }

                        SliderRow {
                            width: parent.width
                            height: 56
                            icon: "\uf185"
                            label: "Brightness"
                            value: root.brightness
                            onValueSelected: percent => {
                                root.brightness = percent;
                                brightnessSetProc.command = ["brightnessctl", "set", percent + "%"];
                                brightnessSetProc.running = true;
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 96
                            radius: 16
                            color: Qt.rgba(Theme.separator.r, Theme.separator.g, Theme.separator.b, 0.34)
                            border.color: Qt.rgba(Theme.separator.r, Theme.separator.g, Theme.separator.b, 0.35)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 14

                                RoundCover {
                                    Layout.preferredWidth: 68
                                    Layout.preferredHeight: 68
                                    source: root.player ? root.player.trackArtUrl : ""
                                }

                                Column {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 4

                                    Text {
                                        width: parent.width
                                        text: root.player ? root.player.trackTitle : "No media"
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSize + 3
                                        font.weight: Font.Bold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: root.player ? root.player.trackArtist : ""
                                        color: Theme.muted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSize
                                        font.weight: Theme.fontWeight
                                        elide: Text.ElideRight
                                    }
                                }

                                Row {
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 18

                                    Text {
                                        text: "\uf04a"
                                        color: mediaPrevMouse.containsMouse ? Theme.text : Theme.muted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSize + 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        MouseArea {
                                            id: mediaPrevMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (root.player) root.player.previous();
                                            }
                                        }
                                    }

                                    Text {
                                        text: root.player && root.player.playbackState === MprisPlaybackState.Playing ? "\uf04c" : "\uf04b"
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSize + 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (root.player) root.player.togglePlaying();
                                            }
                                        }
                                    }

                                    Text {
                                        text: "\uf04e"
                                        color: mediaNextMouse.containsMouse ? Theme.text : Theme.muted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSize + 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        MouseArea {
                                            id: mediaNextMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (root.player) root.player.next();
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            width: parent.width
                            height: 70
                            spacing: 10

                            BottomButton {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                icon: "\uf240"
                                title: "Battery"
                                subtitle: root.batteryText
                            }

                            BottomButton {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                icon: "\uf185"
                                title: "Night Light"
                                subtitle: root.nightLightEnabled ? "On" : "Off"
                                active: root.nightLightEnabled
                                onClicked: nightLightToggleProc.running = true
                            }

                            BottomButton {
                                Layout.preferredWidth: 72
                                Layout.fillHeight: true
                                icon: "\uf011"
                                title: ""
                                subtitle: ""
                                danger: true
                                iconOnly: true
                                active: root.showPowerActions
                                onClicked: root.showPowerActions = !root.showPowerActions
                            }
                        }

                        RowLayout {
                            visible: root.showPowerActions
                            width: parent.width
                            height: visible ? 56 : 0
                            spacing: 10

                            Repeater {
                                model: [
                                    { label: "Lock", icon: "\uf023", command: "lock-screen" },
                                    { label: "Logout", icon: "\uf2f5", command: "hyprctl dispatch 'hl.dsp.exit()'" },
                                    { label: "Reboot", icon: "\uf021", command: "systemctl reboot" },
                                    { label: "Shutdown", icon: "\uf011", command: "systemctl poweroff" }
                                ]

                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 14
                                    color: actionMouse.containsMouse ? Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.12)
                                        : Qt.rgba(Theme.separator.r, Theme.separator.g, Theme.separator.b, 0.34)
                                    border.color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.22)
                                    border.width: 1

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 3
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.icon; color: Theme.warning; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize + 4 }
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize - 2; font.weight: Font.Bold }
                                    }

                                    MouseArea {
                                        id: actionMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.executeAction(modelData.command)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
