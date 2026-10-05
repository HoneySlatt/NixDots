import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "services" as Services
import "m3" as M3

Item {
    id: launcherScope

    function applyTheme(key) {
        Theme.setTheme(key);
        ThemeLauncherState.close();
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root

            required property var modelData
            screen: modelData
            visible: ThemeLauncherState.visible && monitorIsFocused

            readonly property bool monitorIsFocused: Services.NiriData.activeWorkspace !== null && Services.NiriData.activeWorkspace.output === root.screen.name
            onMonitorIsFocusedChanged: if (!monitorIsFocused) ThemeLauncherState.close()
            

            color: "transparent"

            WlrLayershell.namespace: "quickshell:themelauncher"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore

            anchors { top: true; bottom: true; left: true; right: true }

            readonly property int cardW: 154
            readonly property int cardH: 210
            readonly property int cardSpacing: 16
            property int selectedIndex: 0
            readonly property string selectedKey: Theme.themeKeys[selectedIndex] ?? Theme.currentTheme
            readonly property var selectedTheme: Theme.themes[selectedKey] ?? Theme.themes[Theme.currentTheme]
            readonly property color selectedBg: selectedTheme.background
            readonly property color selectedText: selectedTheme.text
            readonly property color selectedSeparator: selectedTheme.separator
            readonly property color selectedWarning: selectedTheme.warning
            readonly property color selectedCaution: selectedTheme.caution
            readonly property color selectedMisc: selectedTheme.misc
            readonly property color selectedProcess: selectedTheme.process
            readonly property color selectedAccent: selectedTheme.accent

            function clampSelection() {
                selectedIndex = Math.max(0, Math.min(Theme.themeKeys.length - 1, selectedIndex));
            }

            function selectCurrentTheme() {
                const idx = Theme.themeKeys.indexOf(Theme.currentTheme);
                selectedIndex = idx >= 0 ? idx : 0;
            }

            onVisibleChanged: {
                if (visible) {
                    selectCurrentTheme();
                    focusTimer.start();
                }
            }

            Timer {
                id: focusTimer
                interval: 80
                repeat: false
                onTriggered: keyLayer.forceActiveFocus()
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.scrim
            }

            MouseArea {
                anchors.fill: parent
                onClicked: ThemeLauncherState.close()
            }

            Item {
                id: keyLayer
                anchors.fill: parent
                focus: ThemeLauncherState.visible

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        ThemeLauncherState.close();
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        launcherScope.applyTheme(root.selectedKey);
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_H || event.key === Qt.Key_Left) {
                        root.selectedIndex--;
                        root.clampSelection();
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_L || event.key === Qt.Key_Right) {
                        root.selectedIndex++;
                        root.clampSelection();
                        event.accepted = true;
                    }
                }
            }

            M3.Surface {
                id: previewPanel
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: mainPanel.top
                anchors.bottomMargin: 16
                width: 470
                height: 190
                radius: Theme.shapeXLI
                color: root.selectedBg
                growFrom: "center"

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: launcherScope.applyTheme(root.selectedKey)
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 18

                    RowLayout {
                        width: parent.width
                        spacing: 12

                        M3.Label {
                            Layout.fillWidth: true
                            text: root.selectedTheme.name
                            color: root.selectedText
                            font.pixelSize: Theme.typeHeadline
                            font.weight: Font.Bold
                        }

                        M3.Badge {
                            visible: root.selectedKey === Theme.currentTheme
                            text: "Active"
                            color: root.selectedAccent
                            contentColor: Theme.contentOn(root.selectedAccent)
                        }
                    }

                    Row {
                        spacing: 10

                        Rectangle {
                            width: applyLabel.implicitWidth + 40
                            height: 40
                            radius: 20
                            color: root.selectedAccent

                            M3.Label {
                                id: applyLabel
                                anchors.centerIn: parent
                                text: "Apply"
                                color: Theme.contentOn(root.selectedAccent)
                                font.weight: Font.Bold
                            }
                        }

                        Rectangle {
                            width: tonalLabel.implicitWidth + 40
                            height: 40
                            radius: Theme.shapeM
                            color: Theme.mix(root.selectedBg, root.selectedAccent, 0.22)

                            M3.Label {
                                id: tonalLabel
                                anchors.centerIn: parent
                                text: "Tonal"
                                color: root.selectedText
                                font.weight: Font.Bold
                            }
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 52
                            height: 32
                            radius: 16
                            color: root.selectedAccent

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                x: parent.width - width - 4
                                width: 24
                                height: 24
                                radius: 12
                                color: Theme.contentOn(root.selectedAccent)
                            }
                        }

                        Repeater {
                            model: [root.selectedProcess, root.selectedMisc, root.selectedWarning]
                            delegate: Rectangle {
                                required property var modelData
                                anchors.verticalCenter: parent.verticalCenter
                                width: 28
                                height: 28
                                radius: 14
                                color: modelData
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 6

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width * 0.62
                            height: 14
                            radius: 7
                            color: root.selectedAccent
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 4
                            height: 32
                            radius: 2
                            color: root.selectedAccent
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width * 0.38 - 16
                            height: 14
                            radius: 7
                            color: Theme.mix(root.selectedBg, root.selectedAccent, 0.22)
                        }
                    }
                }
            }

            M3.Surface {
                id: mainPanel
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 110
                width: Math.min(parent.width - 80, 1080)
                height: 330
                radius: Theme.shapeXLI
                growFrom: "center"

                MouseArea { anchors.fill: parent; onClicked: keyLayer.forceActiveFocus() }

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: 28
                    anchors.rightMargin: 28
                    anchors.topMargin: 22

                    M3.Label {
                        Layout.fillWidth: true
                        text: "Themes"
                        font.pixelSize: Theme.typeTitleL
                        font.weight: Font.Bold
                    }

                    M3.Label {
                        text: "←/→ browse  •  enter apply"
                        color: Theme.textOnSurfaceVariant
                        font.pixelSize: Theme.typeLabel
                    }
                }

                ListView {
                    id: themeList
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    anchors.bottomMargin: 26
                    height: root.cardH + 12
                    orientation: ListView.Horizontal
                    model: Theme.themeKeys
                    currentIndex: root.selectedIndex
                    spacing: root.cardSpacing
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Center)

                    header: Item { width: Math.max(0, (themeList.width - Theme.themeKeys.length * (root.cardW + root.cardSpacing) + root.cardSpacing) / 2); height: 1 }

                    delegate: Item {
                        id: themeCell

                        required property string modelData
                        required property int index

                        readonly property var palette: Theme.themes[modelData]
                        readonly property bool selected: root.selectedIndex === index
                        readonly property bool active: Theme.currentTheme === modelData

                        width: root.cardW
                        height: themeList.height

                        Rectangle {
                            id: card
                            anchors.centerIn: parent
                            width: root.cardW
                            height: root.cardH
                            radius: themeCell.selected ? Theme.shapeXLI : Theme.shapeLI
                            color: themeCell.palette.background
                            scale: themeCell.selected ? 1 : 0.94

                            Behavior on radius { M3.Spring {} }
                            Behavior on scale { M3.Spring {} }

                            M3.FocusRing {
                                shown: themeCell.selected
                                border.color: themeCell.palette.accent
                            }

                            M3.StateLayer {
                                tint: themeCell.palette.text
                                hovered: cardMouse.containsMouse
                                pressed: cardMouse.pressed
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 16

                                M3.PaletteSwatch {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 88
                                    height: 76
                                    topColor: themeCell.palette.accent
                                    leftColor: themeCell.palette.process
                                    rightColor: themeCell.palette.misc
                                    rotation: themeCell.selected ? 0 : -45

                                    Behavior on rotation { M3.Spring { speed: "default" } }
                                }

                                M3.Label {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: Math.min(implicitWidth, root.cardW - 24)
                                    text: themeCell.palette.name
                                    color: themeCell.palette.text
                                    font.pixelSize: Theme.typeBody + 1
                                    font.weight: Font.Bold
                                }

                                Row {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 5
                                    Repeater {
                                        model: [themeCell.palette.separator, themeCell.palette.text, themeCell.palette.highlight, themeCell.palette.warning]
                                        delegate: Rectangle { required property var modelData; width: 12; height: 12; radius: 6; color: modelData }
                                    }
                                }
                            }

                            Rectangle {
                                visible: themeCell.active
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 12
                                width: 28
                                height: 28
                                radius: 14
                                color: themeCell.palette.accent

                                M3.Icon {
                                    anchors.centerIn: parent
                                    icon: "check"
                                    size: 16
                                    color: Theme.contentOn(themeCell.palette.accent)
                                }
                            }

                            MouseArea {
                                id: cardMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: root.selectedIndex = themeCell.index
                                onClicked: {
                                    if (root.selectedIndex === themeCell.index) launcherScope.applyTheme(themeCell.modelData);
                                    else root.selectedIndex = themeCell.index;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
