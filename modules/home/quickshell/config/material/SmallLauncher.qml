import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "services" as Services
import "m3" as M3

Item {
    id: launcherScope

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root

            required property var modelData
            screen: modelData
            visible: SmallLauncherState.visible && monitorIsFocused

            readonly property bool monitorIsFocused: Services.Compositor.focusedOutput === root.screen.name
            onMonitorIsFocusedChanged: if (!monitorIsFocused) SmallLauncherState.close()

            color: "transparent"

            WlrLayershell.namespace: "quickshell:small-launcher"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors { top: true; bottom: true; left: true; right: true }

            property string searchQuery: ""
            property var sortedApps: []
            property var filteredApps: []
            property int selectedIndex: 0

            readonly property int cardW: 96
            readonly property int cardH: 116
            readonly property int cellW: 110
            readonly property int cellH: 130
            readonly property int appsContentWidth: root.filteredApps.length * root.cellW

            function rebuildList() {
                let apps = [];
                let seen = new Set();
                for (let i = 0; i < sourceRepeater.count; i++) {
                    let item = sourceRepeater.itemAt(i);
                    if (!item || item.modelData.noDisplay) continue;
                    const key = item.modelData.id ?? item.modelData.name ?? "";
                    if (seen.has(key)) continue;
                    seen.add(key);
                    apps.push(item.modelData);
                }
                apps.sort((a, b) => (a.name ?? "").localeCompare(b.name ?? ""));
                sortedApps = apps;
                filterList();
            }

            function filterList() {
                if (searchQuery.length === 0) {
                    filteredApps = sortedApps;
                    root.selectedIndex = Math.floor(filteredApps.length / 2);
                } else {
                    filteredApps = sortedApps.filter(app =>
                        app.name?.toLowerCase().includes(searchQuery)
                    );
                    root.selectedIndex = 0;
                }
                if (appGrid) {
                    appGrid.positionViewAtIndex(root.selectedIndex, ListView.Center);
                }
            }

            onSelectedIndexChanged: {
                if (appGrid) {
                    appGrid.positionViewAtIndex(root.selectedIndex, ListView.Center);
                }
            }

            onSearchQueryChanged: filterList()

            Connections {
                target: SmallLauncherState
                function onVisibleChanged() {
                    if (SmallLauncherState.visible) {
                        searchField.text = "";
                        root.searchQuery = "";
                        root.rebuildList();
                    }
                }
            }

            Item {
                visible: false
                Repeater {
                    id: sourceRepeater
                    model: DesktopEntries.applications
                    Item { required property var modelData }
                    Component.onCompleted: root.rebuildList()
                    onCountChanged: root.rebuildList()
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: SmallLauncherState.close()
            }

            FocusScope {
                anchors.fill: parent
                focus: SmallLauncherState.visible

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        SmallLauncherState.close();
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (root.filteredApps.length > 0 && root.selectedIndex >= 0) {
                            root.filteredApps[root.selectedIndex].execute();
                            SmallLauncherState.close();
                        }
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_Left) {
                        root.selectedIndex = Math.max(0, root.selectedIndex - 1);
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_Right) {
                        root.selectedIndex = Math.min(root.filteredApps.length - 1, root.selectedIndex + 1);
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_Backspace) {
                        searchField.text = searchField.text.slice(0, -1);
                        event.accepted = true;
                        return;
                    }
                    if (event.text.length > 0 && !event.modifiers) {
                        searchField.text += event.text;
                        event.accepted = true;
                        return;
                    }
                }

                M3.Surface {
                    id: panel
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 40, 720)
                    height: 20 + 48 + 16 + root.cellH + 20
                    radius: Theme.shapeXLI
                    growFrom: "center"

                    MouseArea { anchors.fill: parent }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 16

                        M3.SearchField {
                            id: searchField
                            width: parent.width
                            placeholder: "Search apps"
                            onTextChanged: root.searchQuery = text.toLowerCase()
                        }

                        ListView {
                            id: appGrid
                            width: parent.width
                            height: root.cellH
                            orientation: ListView.Horizontal
                            model: root.filteredApps
                            clip: true
                            interactive: false
                            boundsBehavior: Flickable.StopAtBounds
                            focus: false
                            currentIndex: root.selectedIndex

                            preferredHighlightBegin: (width - root.cardW) / 2
                            preferredHighlightEnd: (width + root.cardW) / 2
                            highlightRangeMode: ListView.StrictlyEnforceRange

                            delegate: Item {
                                id: cell
                                width: root.cellW
                                height: root.cellH

                                readonly property bool selected: index === root.selectedIndex

                                Rectangle {
                                    id: appCard
                                    anchors.centerIn: parent
                                    width: root.cardW
                                    height: root.cardH
                                    radius: cell.selected ? Theme.shapeXL : Theme.shapeLI
                                    color: cell.selected ? Theme.primaryContainer : "transparent"
                                    scale: cell.selected ? 1 : 0.9

                                    Behavior on radius { M3.Spring {} }
                                    Behavior on scale { M3.Spring {} }
                                    Behavior on color { M3.ColorEffect {} }

                                    M3.StateLayer {
                                        tint: cell.selected ? Theme.textOnPrimaryContainer : Theme.textOnSurface
                                        hovered: appMouse.containsMouse
                                        pressed: appMouse.pressed
                                    }

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 10

                                        Item {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: 48
                                            height: 48

                                            Image {
                                                id: appIcon
                                                anchors.fill: parent
                                                source: {
                                                    const icon = modelData.icon ?? "";
                                                    return icon.startsWith("/") ? icon : Quickshell.iconPath(icon || "application-x-executable", "application-x-executable");
                                                }
                                                sourceSize: Qt.size(48, 48)
                                                smooth: true
                                                asynchronous: true
                                                visible: status === Image.Ready
                                            }

                                            M3.Icon {
                                                anchors.centerIn: parent
                                                visible: appIcon.status !== Image.Ready
                                                icon: "apps"
                                                size: 36
                                                color: Theme.primary
                                            }
                                        }

                                        M3.Label {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: appCard.width - 12
                                            text: modelData.name ?? ""
                                            color: cell.selected ? Theme.textOnPrimaryContainer : Theme.textOnSurface
                                            font.weight: Font.Bold
                                            maximumLineCount: 1
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                    }

                                    MouseArea {
                                        id: appMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: root.selectedIndex = index
                                        onClicked: {
                                            modelData.execute();
                                            SmallLauncherState.close();
                                        }
                                    }
                                }
                            }

                            M3.Label {
                                anchors.centerIn: parent
                                visible: root.filteredApps.length === 0
                                text: "No applications found"
                                color: Theme.textOnSurfaceVariant
                            }
                        }
                    }
                }
            }
        }
    }
}
