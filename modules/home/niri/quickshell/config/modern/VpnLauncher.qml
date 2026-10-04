import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "services" as Services

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

    component GlassPanel: Rectangle {
        property color fillColor: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.56)

        radius: 26
        color: "transparent"
        border.color: Qt.tint(Theme.separator, Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.44))
        border.width: 1
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.tint(fillColor, Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)) }
            GradientStop { position: 0.62; color: fillColor }
            GradientStop { position: 1.0; color: Qt.tint(fillColor, Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.24)) }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: parent.radius
            anchors.rightMargin: parent.radius
            anchors.topMargin: 1
            height: 1
            radius: 1
            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.16)
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root

            required property var modelData
            screen: modelData
            visible: VpnLauncherState.visible && monitorIsFocused

            readonly property bool monitorIsFocused: Services.NiriData.activeWorkspace !== null && Services.NiriData.activeWorkspace.output === root.screen.name
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

            Rectangle { anchors.fill: parent; color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.76) }
            MouseArea { anchors.fill: parent; onClicked: VpnLauncherState.close() }

            Item {
                id: keyLayer
                anchors.fill: parent
                focus: VpnLauncherState.visible
                Keys.onPressed: event => root.handleKey(event)

                GlassPanel {
                    id: panel
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 96, 1040)
                    height: Math.min(parent.height - 120, 680)

                    MouseArea { anchors.fill: parent; onClicked: keyLayer.forceActiveFocus() }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 16

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 18

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 5

                                Text {
                                    text: root.step === "entry" ? "NymVPN Entry" : "NymVPN Exit"
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize + 12
                                    font.weight: Font.Bold
                                }

                                Text {
                                    text: root.step === "exit"
                                        ? "Entry " + root.pendingEntry.name + ", choose exit country"
                                        : scope.vpnState + "   " + (scope.entryCountry || "random") + " -> " + (scope.exitCountry || "random")
                                    color: scope.vpnState === "Connected" ? Theme.accent : Theme.muted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            Rectangle {
                                width: 118
                                height: 38
                                radius: 19
                                color: offMouse.containsMouse ? Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.28) : Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.42)
                                border.color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.68)
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "OFF"
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                    font.weight: Font.Bold
                                }

                                MouseArea { id: offMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.clearNode() }
                            }
                        }

                        GlassPanel {
                            Layout.fillWidth: true
                            height: 48
                            radius: 24
                            fillColor: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.42)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 18
                                anchors.rightMargin: 18
                                spacing: 12

                                Text { text: "\uf002"; color: Theme.accent; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize + 4; Layout.alignment: Qt.AlignVCenter }
                                TextInput {
                                    id: searchField
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    readOnly: true
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize + 1
                                    verticalAlignment: TextInput.AlignVCenter
                                    onTextChanged: root.searchQuery = text

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "Search country..."
                                        color: Theme.muted
                                        visible: searchField.text.length === 0
                                        font.family: searchField.font.family
                                        font.pixelSize: searchField.font.pixelSize
                                    }
                                }
                            }
                        }

                        ListView {
                            id: nodeList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            model: root.filteredNodes
                            currentIndex: root.selectedIndex
                            clip: true
                            spacing: 10

                            delegate: Rectangle {
                                id: row
                                required property var modelData
                                required property int index

                                width: nodeList.width
                                height: 72
                                radius: 18
                                color: root.isCurrent(modelData)
                                    ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22)
                                    : index === root.selectedIndex
                                        ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.075)
                                        : Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.34)
                                border.color: index === root.selectedIndex ? Theme.accent : Qt.rgba(Theme.separator.r, Theme.separator.g, Theme.separator.b, 0.52)
                                border.width: index === root.selectedIndex ? 2 : 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 18
                                    anchors.rightMargin: 18
                                    spacing: 16

                                    Text { text: root.isCurrent(modelData) ? "\uf058" : "\uf132"; color: root.isCurrent(modelData) ? Theme.accent : Theme.muted; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize + 10; Layout.alignment: Qt.AlignVCenter }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 3

                                        Text { text: modelData.name; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize + 1; font.weight: Font.Bold; elide: Text.ElideRight; Layout.fillWidth: true }
                                        Text { text: modelData.servers + (modelData.servers === 1 ? " server" : " servers"); color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize - 1; elide: Text.ElideRight; Layout.fillWidth: true }
                                    }

                                    Text { text: modelData.code; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize - 1; Layout.alignment: Qt.AlignVCenter }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: root.selectedIndex = index
                                    onClicked: root.setSelectedNode()
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "ctrl+j/k navigate   enter select   backspace back   del off   esc close"; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize - 1; Layout.fillWidth: true }
                            Text { text: root.filteredNodes.length + " countries"; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize - 1 }
                        }
                    }
                }
            }
        }
    }
}
