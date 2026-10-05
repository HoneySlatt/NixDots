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
            visible: LauncherState.visible && monitorIsFocused

            readonly property bool monitorIsFocused: Services.NiriData.activeWorkspace !== null && Services.NiriData.activeWorkspace.output === root.screen.name
            onMonitorIsFocusedChanged: if (!monitorIsFocused) LauncherState.close()
            

            property string searchQuery: ""
            property int selectedIndex: 0
            property var sortedApps: []
            property var filteredApps: []

            color: "transparent"

            WlrLayershell.namespace: "quickshell:applauncher"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors { top: true; bottom: true; left: true; right: true }

            function rebuildList() {
                let apps = [];
                let seen = new Set();
                for (let i = 0; i < sourceRepeater.count; i++) {
                    const item = sourceRepeater.itemAt(i);
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
                } else {
                    filteredApps = sortedApps.filter(app =>
                        app.name?.toLowerCase().includes(searchQuery)
                    );
                }
                selectedIndex = Math.min(selectedIndex, Math.max(filteredApps.length - 1, 0));
                if (filteredApps.length > 0 && selectedIndex < 0) selectedIndex = 0;
                appList.currentIndex = selectedIndex;
            }

            function launchSelected() {
                if (filteredApps.length === 0 || selectedIndex < 0 || selectedIndex >= filteredApps.length)
                    return;
                filteredApps[selectedIndex].execute();
                LauncherState.close();
            }

            onSearchQueryChanged: filterList()
            onSelectedIndexChanged: {
                appList.currentIndex = selectedIndex;
                appList.positionViewAtIndex(selectedIndex, ListView.Contain);
            }

            Connections {
                target: LauncherState
                function onVisibleChanged() {
                    if (LauncherState.visible) {
                        searchField.text = "";
                        root.searchQuery = "";
                        root.selectedIndex = 0;
                        root.rebuildList();
                        searchFocusTimer.start();
                    } else {
                        searchFocusTimer.stop();
                    }
                }
            }

            Timer {
                id: searchFocusTimer
                interval: 80
                repeat: false
                onTriggered: searchField.forceActiveFocus()
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
                onClicked: LauncherState.close()
            }

            FocusScope {
                anchors.fill: parent
                focus: LauncherState.visible

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        LauncherState.close();
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.launchSelected();
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_Down) {
                        root.selectedIndex = Math.min(root.selectedIndex + 1, root.filteredApps.length - 1);
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_Up) {
                        root.selectedIndex = Math.max(root.selectedIndex - 1, 0);
                        event.accepted = true;
                        return;
                    }
                }

                M3.Surface {
                    id: panelClip
                    anchors.top: BarState.isTop ? parent.top : undefined
                    anchors.bottom: BarState.isTop ? undefined : parent.bottom
                    anchors.topMargin: Theme.popupGap
                    anchors.left: parent.left
                    anchors.leftMargin: BarState.isTop ? Theme.margin : 0
                    width: 380
                    height: 430
                    flushBottom: !BarState.isTop
                    growFrom: BarState.isTop ? "top" : "bottom"

                    MouseArea { anchors.fill: parent }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        M3.SearchField {
                            id: searchField
                            width: parent.width
                            placeholder: "Search apps"
                            onTextChanged: root.searchQuery = text.toLowerCase()
                        }

                        ListView {
                            id: appList
                            width: parent.width
                            height: parent.height - searchField.height - parent.spacing
                            clip: true
                            model: root.filteredApps
                            currentIndex: root.selectedIndex
                            spacing: 2
                            boundsBehavior: Flickable.StopAtBounds
                            interactive: true

                            delegate: M3.ListSegment {
                                id: appRow

                                required property var modelData
                                required property int index

                                width: appList.width
                                height: 48
                                first: index === 0
                                last: index === appList.count - 1
                                selected: index === root.selectedIndex
                                baseColor: Theme.surfaceContainerHigh
                                onEntered: root.selectedIndex = index
                                onClicked: {
                                    appRow.modelData.execute();
                                    LauncherState.close();
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 16
                                    spacing: 14

                                    Item {
                                        Layout.preferredWidth: 28
                                        Layout.preferredHeight: 28

                                        Image {
                                            id: appIcon
                                            anchors.fill: parent
                                            source: {
                                                const icon = appRow.modelData.icon ?? "";
                                                return icon.startsWith("/") ? icon : Quickshell.iconPath(icon || "application-x-executable", "application-x-executable");
                                            }
                                            sourceSize: Qt.size(28, 28)
                                            smooth: true
                                            asynchronous: true
                                            visible: status === Image.Ready
                                        }

                                        M3.Icon {
                                            anchors.centerIn: parent
                                            visible: appIcon.status !== Image.Ready
                                            icon: "apps"
                                            size: 24
                                            color: Theme.primary
                                        }
                                    }

                                    M3.Label {
                                        Layout.fillWidth: true
                                        text: appRow.modelData.name ?? ""
                                        color: appRow.selected ? Theme.textOnSecondaryContainer : Theme.textOnSurface
                                        font.pixelSize: Theme.typeBody + 1
                                        font.weight: appRow.selected ? Font.Bold : Theme.fontWeight
                                    }

                                    M3.Icon {
                                        icon: "chevron_right"
                                        size: 20
                                        color: Theme.textOnSecondaryContainer
                                        opacity: appRow.selected ? 1 : 0

                                        Behavior on opacity { M3.Effect {} }
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
