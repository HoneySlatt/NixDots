import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "services" as Services
import "m3" as M3

Item {
    id: scope

    property var allNodes: []
    property string vpnState: ""
    property string entryCountry: ""
    property string exitCountry: ""

    function refreshNodes() {
        nodesProc.buffer = "";
        nodesProc.running = true;
    }

    Process {
        id: nodesProc
        command: ["/etc/profiles/per-user/honey/bin/nym-countries"]
        running: false
        property string buffer: ""

        stdout: SplitParser { onRead: data => nodesProc.buffer += data }

        onExited: {
            try {
                const data = JSON.parse(nodesProc.buffer);
                scope.vpnState = data.state;
                scope.entryCountry = data.entry;
                scope.exitCountry = data.exit;
                scope.allNodes = data.countries;
            } catch (e) {
                scope.allNodes = [];
            }
            nodesProc.buffer = "";
        }
    }

    Component.onCompleted: refreshNodes()


    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root

            required property var modelData
            screen: modelData
            visible: VpnLauncherState.visible && monitorIsFocused

            readonly property bool monitorIsFocused: Services.Compositor.focusedOutput === root.screen.name
            onMonitorIsFocusedChanged: if (!monitorIsFocused) VpnLauncherState.close()

            property string searchQuery: ""
            property int selectedIndex: 0
            property var filteredNodes: []
            readonly property var selectedNode: filteredNodes.length > 0 ? filteredNodes[selectedIndex] : null
            // Entry is picked first, then exit
            property string step: "entry"
            property var pendingEntry: null

            function isCurrent(node) {
                return step === "entry" ? node.entry : node.exit;
            }

            color: "transparent"
            WlrLayershell.namespace: "quickshell:vpnlauncher"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore
            anchors { top: true; bottom: true; left: true; right: true }

            function filterList() {
                const q = searchQuery.toLowerCase();
                filteredNodes = q.length === 0
                    ? scope.allNodes
                    : scope.allNodes.filter(n => (n.name + " " + n.code).toLowerCase().includes(q));
                selectedIndex = Math.max(0, Math.min(selectedIndex, filteredNodes.length - 1));
                nodeList.currentIndex = selectedIndex;
                Qt.callLater(centerSelection);
            }

            function centerSelection() {
                if (filteredNodes.length > 0)
                    nodeList.positionViewAtIndex(selectedIndex, ListView.Contain);
            }

            function initializeLauncher() {
                step = "entry";
                pendingEntry = null;
                searchField.text = "";
                searchQuery = "";
                selectedIndex = 0;
                scope.refreshNodes();
                filterList();
                focusTimer.start();
            }

            function setSelectedNode() {
                if (!selectedNode) return;
                if (step === "entry") {
                    pendingEntry = selectedNode;
                    step = "exit";
                    searchField.text = "";
                    selectedIndex = Math.max(0, scope.allNodes.findIndex(n => n.exit));
                    return;
                }
                // Connecting takes several seconds, so detach and close right away
                Quickshell.execDetached(["/etc/profiles/per-user/honey/bin/toggle-nym", "set", pendingEntry.code, selectedNode.code]);
                VpnLauncherState.close();
            }

            function clearNode() {
                Quickshell.execDetached(["/etc/profiles/per-user/honey/bin/toggle-nym", "off"]);
                VpnLauncherState.close();
            }

            function previousStep() {
                step = "entry";
                selectedIndex = Math.max(0, scope.allNodes.findIndex(n => n.code === pendingEntry.code));
                pendingEntry = null;
            }

            function handleKey(event) {
                if (event.key === Qt.Key_Escape) { VpnLauncherState.close(); event.accepted = true; return; }
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { setSelectedNode(); event.accepted = true; return; }
                if (event.key === Qt.Key_Delete) { clearNode(); event.accepted = true; return; }
                if ((event.key === Qt.Key_J && event.modifiers & Qt.ControlModifier) || event.key === Qt.Key_Down) {
                    if (selectedIndex < filteredNodes.length - 1) selectedIndex++;
                    event.accepted = true;
                    return;
                }
                if ((event.key === Qt.Key_K && event.modifiers & Qt.ControlModifier) || event.key === Qt.Key_Up) {
                    if (selectedIndex > 0) selectedIndex--;
                    event.accepted = true;
                    return;
                }
                if (event.key === Qt.Key_Backspace && searchField.text.length === 0 && step === "exit") { previousStep(); event.accepted = true; return; }
                if (event.key === Qt.Key_Backspace) { searchField.text = searchField.text.slice(0, -1); event.accepted = true; return; }
                if (event.text.length > 0 && !event.modifiers) { searchField.text += event.text; event.accepted = true; }
            }

            onSelectedIndexChanged: {
                nodeList.currentIndex = selectedIndex;
                centerSelection();
            }
            onSearchQueryChanged: filterList()

            Connections { target: scope; function onAllNodesChanged() { root.filterList(); } }

            Timer { id: focusTimer; interval: 80; repeat: false; onTriggered: keyLayer.forceActiveFocus() }

            Rectangle { anchors.fill: parent; color: Theme.scrim }
            MouseArea { anchors.fill: parent; onClicked: VpnLauncherState.close() }

            Item {
                id: keyLayer
                anchors.fill: parent
                focus: VpnLauncherState.visible
                Keys.onPressed: event => root.handleKey(event)

                M3.Surface {
                    id: panel
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 96, 1040)
                    height: Math.min(parent.height - 120, 680)
                    radius: Theme.shapeXLI
                    growFrom: "center"

                    MouseArea { anchors.fill: parent; onClicked: keyLayer.forceActiveFocus() }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 16

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 16

                            Rectangle {
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 48
                                radius: scope.vpnState === "Connected" ? Theme.shapeM : 24
                                color: scope.vpnState === "Connected" ? Theme.primary : Theme.surfaceContainerHighest

                                Behavior on radius { M3.Spring {} }
                                Behavior on color { M3.ColorEffect {} }

                                M3.Icon {
                                    anchors.centerIn: parent
                                    icon: "shield_lock"
                                    size: 28
                                    color: scope.vpnState === "Connected" ? Theme.textOnPrimary : Theme.textOnSurfaceVariant
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                M3.Label {
                                    text: "NymVPN"
                                    font.pixelSize: Theme.typeHeadline
                                    font.weight: Font.Bold
                                }

                                M3.Label {
                                    Layout.fillWidth: true
                                    text: (scope.vpnState || "Unknown") + "  •  " + (scope.entryCountry || "random") + " → " + (scope.exitCountry || "random")
                                    color: scope.vpnState === "Connected" ? Theme.primary : Theme.textOnSurfaceVariant
                                }
                            }

                            M3.Button {
                                variant: "error"
                                icon: "power_settings_new"
                                text: "Disconnect"
                                onClicked: root.clearNode()
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            M3.Chip {
                                clickable: root.step === "exit"
                                selected: root.step === "entry"
                                icon: "public"
                                text: root.step === "exit" ? "Entry: " + root.pendingEntry.name : "Entry"
                                onClicked: root.previousStep()
                            }

                            M3.Icon {
                                icon: "chevron_right"
                                size: 18
                                color: Theme.textOnSurfaceVariant
                            }

                            M3.Chip {
                                clickable: false
                                selected: root.step === "exit"
                                icon: "logout"
                                text: "Exit"
                            }

                            Item { Layout.fillWidth: true }

                            M3.Label {
                                text: root.filteredNodes.length + " countries"
                                color: Theme.textOnSurfaceVariant
                            }
                        }

                        M3.SearchField {
                            id: searchField
                            Layout.fillWidth: true
                            readOnly: true
                            color: Theme.surfaceContainerHighest
                            placeholder: root.step === "entry" ? "Search entry country" : "Search exit country"
                            onTextChanged: root.searchQuery = text
                        }

                        ListView {
                            id: nodeList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            model: root.filteredNodes
                            currentIndex: root.selectedIndex
                            clip: true
                            spacing: 2

                            delegate: M3.ListSegment {
                                id: row
                                required property var modelData
                                required property int index

                                readonly property bool current: root.isCurrent(modelData)

                                width: nodeList.width
                                height: 56
                                first: index === 0
                                last: index === nodeList.count - 1
                                selected: index === root.selectedIndex
                                baseColor: Theme.surfaceContainerHigh
                                onEntered: root.selectedIndex = index
                                onClicked: root.setSelectedNode()

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 18
                                    spacing: 14

                                    Rectangle {
                                        Layout.preferredWidth: 40
                                        Layout.preferredHeight: 40
                                        radius: row.current ? Theme.shapeM : 20
                                        color: row.current ? Theme.primary : Theme.surfaceContainerHighest

                                        M3.Label {
                                            anchors.centerIn: parent
                                            visible: !row.current
                                            text: row.modelData.code
                                            color: Theme.textOnSurfaceVariant
                                            font.pixelSize: Theme.typeLabel
                                            font.weight: Font.Bold
                                        }

                                        M3.Icon {
                                            anchors.centerIn: parent
                                            visible: row.current
                                            icon: "check"
                                            size: 20
                                            color: Theme.textOnPrimary
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        M3.Label {
                                            Layout.fillWidth: true
                                            text: row.modelData.name
                                            color: row.selected ? Theme.textOnSecondaryContainer : Theme.textOnSurface
                                            font.pixelSize: Theme.typeBody + 1
                                            font.weight: Font.Bold
                                        }

                                        M3.Label {
                                            Layout.fillWidth: true
                                            text: row.modelData.servers + (row.modelData.servers === 1 ? " server" : " servers") + (row.current ? "  •  current" : "")
                                            color: row.current ? Theme.primary : Theme.textOnSurfaceVariant
                                            font.pixelSize: Theme.typeLabel
                                        }
                                    }

                                    M3.Icon {
                                        icon: "chevron_right"
                                        size: 20
                                        color: Theme.textOnSecondaryContainer
                                        opacity: row.selected ? 1 : 0

                                        Behavior on opacity { M3.Effect {} }
                                    }
                                }
                            }
                        }

                        M3.Label {
                            Layout.fillWidth: true
                            text: "ctrl+j/k navigate   enter select   backspace back   del off   esc close"
                            color: Theme.outline
                            font.pixelSize: Theme.typeLabel
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
        }
    }
}
