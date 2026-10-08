import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "services" as Services
import "m3" as M3

Item {
    id: volumePopup

    function volumeIcon(volume, muted) {
        if (muted) return "volume_off";
        if (volume <= 30) return "volume_mute";
        if (volume <= 65) return "volume_down";
        return "volume_up";
    }

    component Section: M3.ListSegment {
        id: section

        property string icon: ""
        property string title: ""
        property string summary: ""
        property bool expanded: false
        default property alias body: bodyCol.data
        signal toggled()

        interactive: false
        rounded: expanded
        clip: true
        height: header.height + (expanded ? bodyCol.implicitHeight + 8 : 0)

        Behavior on height { M3.Spring { speed: "default" } }

        Item {
            id: header
            width: parent.width
            height: 48

            Rectangle {
                anchors.fill: parent
                topLeftRadius: section.topLeftRadius
                topRightRadius: section.topRightRadius
                bottomLeftRadius: section.expanded ? 0 : section.bottomLeftRadius
                bottomRightRadius: section.expanded ? 0 : section.bottomRightRadius
                color: Theme.textOnSurface
                opacity: headerMouse.pressed ? Theme.statePressed : headerMouse.containsMouse ? Theme.stateHover : 0

                Behavior on opacity { M3.Effect {} }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 14

                M3.Icon {
                    icon: section.icon
                    size: 20
                    color: Theme.textOnSurfaceVariant
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    M3.Label {
                        Layout.fillWidth: true
                        text: section.title
                        font.pixelSize: Theme.typeBody + 1
                        font.weight: Font.Bold
                    }

                    M3.Label {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: section.summary
                        color: Theme.textOnSurfaceVariant
                        font.pixelSize: Theme.typeLabel
                    }
                }

                M3.Icon {
                    icon: "expand_more"
                    size: 20
                    color: Theme.textOnSurfaceVariant
                    rotation: section.expanded ? 180 : 0

                    Behavior on rotation { M3.Spring {} }
                }
            }

            MouseArea {
                id: headerMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: section.toggled()
            }
        }

        Column {
            id: bodyCol
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 2
            opacity: section.expanded ? 1 : 0

            Behavior on opacity { M3.Effect {} }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root

            required property var modelData
            screen: modelData
            visible: VolumePopupState.visible && monitorIsFocused

            readonly property bool monitorIsFocused: Services.Compositor.focusedOutput === root.screen.name
            onMonitorIsFocusedChanged: if (!monitorIsFocused) VolumePopupState.close()

            property bool showDevices: false
            property bool showApps: false

            color: "transparent"

            WlrLayershell.namespace: "quickshell:volumepopup"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors { top: true; bottom: true; left: true; right: true }

            Connections {
                target: VolumePopupState
                function onVisibleChanged() {
                    if (VolumePopupState.visible) {
                        VolumeState.popupVisible = true;
                        VolumeState.refreshSinks();
                        VolumeState.refreshAppStreams();
                    } else {
                        VolumeState.popupVisible = false;
                        root.showDevices = false;
                        root.showApps = false;
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: VolumePopupState.close()
            }

            FocusScope {
                anchors.fill: parent
                focus: VolumePopupState.visible

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        VolumePopupState.close();
                        event.accepted = true;
                    }
                }

                M3.Surface {
                    id: popup
                    anchors.top: BarState.isTop ? parent.top : undefined
                    anchors.bottom: BarState.isTop ? undefined : parent.bottom
                    anchors.topMargin: Theme.popupGap
                    anchors.right: parent.right
                    anchors.rightMargin: 86
                    width: 288
                    height: contentCol.implicitHeight + 24
                    flushBottom: !BarState.isTop
                    growFrom: BarState.isTop ? "top" : "bottom"

                    MouseArea { anchors.fill: parent }

                    Column {
                        id: contentCol
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 12
                        spacing: 10

                        RowLayout {
                            width: parent.width
                            spacing: 14

                            M3.IconButton {
                                size: 40
                                variant: "filled"
                                toggle: true
                                checked: !VolumeState.muted
                                icon: volumePopup.volumeIcon(VolumeState.volume, VolumeState.muted)
                                onClicked: VolumeState.toggleMute()
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                M3.Label {
                                    Layout.fillWidth: true
                                    text: "Volume"
                                    font.pixelSize: Theme.typeTitle
                                    font.weight: Font.Bold
                                }

                                M3.Label {
                                    Layout.fillWidth: true
                                    text: VolumeState.muted ? "Muted" : (VolumeState.sinks.find(s => s.active)?.label ?? "Output")
                                    color: Theme.textOnSurfaceVariant
                                    font.pixelSize: Theme.typeLabel
                                }
                            }

                            M3.Label {
                                text: VolumeState.volume + "%"
                                color: VolumeState.muted ? Theme.textOnSurfaceVariant : Theme.primary
                                font.pixelSize: Theme.typeTitle
                                font.weight: Font.Bold
                            }
                        }

                        M3.Slider {
                            width: parent.width
                            value: VolumeState.volume
                            muted: VolumeState.muted
                            onMoved: value => VolumeState.setVolume(value)
                        }

                        Column {
                            width: parent.width
                            spacing: 2

                            Section {
                                width: parent.width
                                first: true
                                icon: "speaker"
                                title: "Output device"
                                summary: VolumeState.sinks.find(s => s.active)?.label ?? ""
                                expanded: root.showDevices
                                onToggled: {
                                    root.showDevices = !root.showDevices;
                                    if (root.showDevices) VolumeState.refreshSinks();
                                }

                                Repeater {
                                    model: VolumeState.sinks
                                    delegate: Rectangle {
                                        id: sinkRow
                                        required property var modelData
                                        width: parent.width
                                        height: 44
                                        radius: height / 2
                                        color: modelData.active ? Theme.secondaryContainer : "transparent"

                                        Behavior on color { M3.ColorEffect {} }

                                        M3.StateLayer {
                                            tint: sinkRow.modelData.active ? Theme.textOnSecondaryContainer : Theme.textOnSurface
                                            hovered: sinkMouse.containsMouse
                                            pressed: sinkMouse.pressed
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 14
                                            anchors.rightMargin: 14
                                            spacing: 12

                                            M3.Icon {
                                                icon: sinkRow.modelData.label.toLowerCase().includes("head") ? "headphones" : "speaker"
                                                size: 18
                                                color: sinkRow.modelData.active ? Theme.textOnSecondaryContainer : Theme.textOnSurfaceVariant
                                            }

                                            M3.Label {
                                                Layout.fillWidth: true
                                                text: sinkRow.modelData.label
                                                color: sinkRow.modelData.active ? Theme.textOnSecondaryContainer : Theme.textOnSurface
                                                font.weight: sinkRow.modelData.active ? Font.Bold : Theme.fontWeight
                                            }

                                            M3.Icon {
                                                visible: sinkRow.modelData.active
                                                icon: "check"
                                                size: 18
                                                color: Theme.textOnSecondaryContainer
                                            }
                                        }

                                        MouseArea {
                                            id: sinkMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: VolumeState.setDefaultSink(sinkRow.modelData.sinkId)
                                        }
                                    }
                                }
                            }

                            Section {
                                width: parent.width
                                last: true
                                icon: "tune"
                                title: "App volumes"
                                summary: VolumeState.appStreams.length + (VolumeState.appStreams.length === 1 ? " stream" : " streams")
                                expanded: root.showApps
                                onToggled: {
                                    root.showApps = !root.showApps;
                                    if (root.showApps) VolumeState.refreshAppStreams();
                                }

                                M3.Label {
                                    visible: VolumeState.appStreams.length === 0
                                    width: parent.width
                                    height: 40
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    text: "No app streams"
                                    color: Theme.textOnSurfaceVariant
                                }

                                Repeater {
                                    model: VolumeState.appStreams
                                    delegate: RowLayout {
                                        id: streamRow
                                        required property var modelData
                                        width: parent.width
                                        height: 44
                                        spacing: 10

                                        M3.Icon {
                                            Layout.leftMargin: 8
                                            icon: "apps"
                                            size: 18
                                            color: Theme.textOnSurfaceVariant
                                        }

                                        M3.Label {
                                            Layout.preferredWidth: 72
                                            text: streamRow.modelData.label
                                        }

                                        M3.Slider {
                                            Layout.fillWidth: true
                                            trackHeight: 10
                                            handleHeight: 24
                                            value: streamRow.modelData.volume
                                            muted: streamRow.modelData.muted
                                            onMoved: value => VolumeState.setAppVolume(streamRow.modelData.streamId, value)
                                        }

                                        M3.IconButton {
                                            size: 32
                                            toggle: true
                                            checked: streamRow.modelData.muted
                                            icon: streamRow.modelData.muted ? "volume_off" : "volume_up"
                                            onClicked: VolumeState.toggleAppMute(streamRow.modelData.streamId)
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
}
