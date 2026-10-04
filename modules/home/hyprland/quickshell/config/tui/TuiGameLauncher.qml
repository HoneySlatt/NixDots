import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: scope

    property var allGames: []

    function refreshGames() {
        if (gamesProc.running) return;
        gamesProc.buffer = "";
        gamesProc.running = true;
    }

    function artSource(art) {
        if (!art) return "";
        return art.startsWith("http://") || art.startsWith("https://") ? art : "file://" + art;
    }

    Process {
        id: gamesProc
        command: ["steam-games"]
        running: false
        property string buffer: ""
        stdout: SplitParser {
            onRead: data => gamesProc.buffer += data
        }
        onExited: {
            try {
                scope.allGames = JSON.parse(gamesProc.buffer);
            } catch (e) {
                scope.allGames = [];
            }
            gamesProc.buffer = "";
        }
    }

    Component.onCompleted: refreshGames()

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root

            required property var modelData
            screen: modelData
            visible: TuiGameLauncherState.visible && monitorIsFocused

            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
            readonly property bool monitorIsFocused: Hyprland.focusedMonitor?.id === monitor?.id

            property string searchQuery: ""
            property int selectedIndex: 0
            property var filteredGames: []

            readonly property var selectedGame: filteredGames.length > 0 ? filteredGames[selectedIndex] : null
            readonly property int cardW: 134
            readonly property int cardH: 214
            readonly property int carouselHeight: cardH + 28

            color: "transparent"

            WlrLayershell.namespace: "quickshell:tui:gamelauncher"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors { top: true; bottom: true; left: true; right: true }

            function centerIndex() {
                return Math.floor(filteredGames.length / 2);
            }

            function positionCarousel() {
                if (filteredGames.length > 0)
                    carousel.positionViewAtIndex(selectedIndex, ListView.Center);
            }

            function filterList() {
                if (searchQuery.length === 0) {
                    filteredGames = scope.allGames;
                    selectedIndex = centerIndex();
                } else {
                    filteredGames = scope.allGames.filter(g => g.name?.toLowerCase().includes(searchQuery));
                    selectedIndex = 0;
                }
                carousel.currentIndex = selectedIndex;
                positionCarousel();
            }

            function launchSelected() {
                if (!selectedGame) return;
                const launchUrl = selectedGame.launchUrl || (selectedGame.appid ? "steam://rungameid/" + selectedGame.appid : "");
                if (!launchUrl) return;
                Qt.openUrlExternally(launchUrl);
                TuiGameLauncherState.close();
            }

            function initializeLauncher() {
                searchField.text = "";
                root.searchQuery = "";
                root.selectedIndex = centerIndex();
                root.filterList();
                grabTimer.start();
                focusTimer.start();
                scope.refreshGames();
            }

            function handleKey(event) {
                if (event.key === Qt.Key_Escape) {
                    TuiGameLauncherState.close();
                    event.accepted = true;
                    return;
                }
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.launchSelected();
                    event.accepted = true;
                    return;
                }
                if (event.key === Qt.Key_Left || (event.key === Qt.Key_H && event.modifiers & Qt.ControlModifier)) {
                    if (root.selectedIndex > 0)
                        root.selectedIndex--;
                    event.accepted = true;
                    return;
                }
                if (event.key === Qt.Key_Right || (event.key === Qt.Key_L && event.modifiers & Qt.ControlModifier)) {
                    if (root.selectedIndex < root.filteredGames.length - 1)
                        root.selectedIndex++;
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
                }
            }

            onSearchQueryChanged: filterList()
            onSelectedIndexChanged: positionCarousel()

            Connections {
                target: scope
                function onAllGamesChanged() { root.filterList(); }
            }

            HyprlandFocusGrab {
                id: grab
                windows: [root]
                active: false
                onCleared: () => {
                    if (!active) TuiGameLauncherState.close();
                }
                onActiveChanged: if (active) focusTimer.start()
            }

            Component.onCompleted: {
                if (TuiGameLauncherState.visible)
                    root.initializeLauncher();
            }

            Connections {
                target: TuiGameLauncherState
                function onVisibleChanged() {
                    if (TuiGameLauncherState.visible) {
                        root.initializeLauncher();
                    } else {
                        grabTimer.stop();
                        focusTimer.stop();
                        grab.active = false;
                    }
                }
            }

            Timer {
                id: grabTimer
                interval: 50
                repeat: false
                onTriggered: grab.active = TuiGameLauncherState.visible
            }

            Timer {
                id: focusTimer
                interval: 80
                repeat: false
                onTriggered: panel.forceActiveFocus()
            }

            MouseArea {
                anchors.fill: parent
                onClicked: TuiGameLauncherState.close()
            }

            Rectangle {
                id: panel
                anchors.centerIn: parent
                width: Math.min(parent.width - 120, 960)
                height: Math.min(parent.height - 120, 500)
                color: TuiTheme.bg
                border.color: TuiTheme.dim
                border.width: 2
                focus: TuiGameLauncherState.visible

                MouseArea { anchors.fill: parent; onClicked: panel.forceActiveFocus() }

                Keys.onPressed: event => root.handleKey(event)

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 6
                    color: "transparent"
                    border.color: TuiTheme.caution
                    border.width: 1
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    Rectangle {
                        width: parent.width
                        height: 42
                        color: TuiTheme.dim
                        border.color: searchField.text.length > 0 ? TuiTheme.accent : TuiTheme.caution
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 10

                            Text {
                                width: 22
                                height: parent.height
                                text: ">"
                                color: TuiTheme.bright
                                font.family: TuiTheme.fontFamily
                                font.pixelSize: TuiTheme.fontSize + 4
                                font.weight: TuiTheme.fontWeight
                                verticalAlignment: Text.AlignVCenter
                            }

                            TextInput {
                                id: searchField
                                width: parent.width - 32
                                height: parent.height
                                color: TuiTheme.fg
                                selectionColor: TuiTheme.accent
                                selectedTextColor: TuiTheme.bg
                                font.family: TuiTheme.fontFamily
                                font.pixelSize: TuiTheme.fontSize + 2
                                font.weight: TuiTheme.fontWeight
                                verticalAlignment: TextInput.AlignVCenter
                                clip: true
                                readOnly: true
                                onTextChanged: root.searchQuery = text.toLowerCase()

                                Keys.onPressed: event => root.handleKey(event)

                                Text {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: "search games..."
                                    color: TuiTheme.barMuted
                                    font.family: searchField.font.family
                                    font.pixelSize: searchField.font.pixelSize
                                    font.weight: searchField.font.weight
                                    visible: searchField.text.length === 0
                                }
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: Math.max(0, parent.height - 188)

                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.color: TuiTheme.dim
                            border.width: 1
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 26
                            anchors.verticalCenter: carousel.verticalCenter
                            width: 42
                            height: 42
                            color: leftMouse.containsMouse ? TuiTheme.accent : TuiTheme.bg
                            border.color: TuiTheme.caution
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "<"
                                color: leftMouse.containsMouse ? TuiTheme.bg : TuiTheme.fg
                                font.family: TuiTheme.fontFamily
                                font.pixelSize: TuiTheme.fontSize + 8
                                font.weight: TuiTheme.fontWeight
                            }

                            MouseArea {
                                id: leftMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (root.selectedIndex > 0) root.selectedIndex--
                            }
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: 26
                            anchors.verticalCenter: carousel.verticalCenter
                            width: 42
                            height: 42
                            color: rightMouse.containsMouse ? TuiTheme.accent : TuiTheme.bg
                            border.color: TuiTheme.caution
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: ">"
                                color: rightMouse.containsMouse ? TuiTheme.bg : TuiTheme.fg
                                font.family: TuiTheme.fontFamily
                                font.pixelSize: TuiTheme.fontSize + 8
                                font.weight: TuiTheme.fontWeight
                            }

                            MouseArea {
                                id: rightMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (root.selectedIndex < root.filteredGames.length - 1) root.selectedIndex++
                            }
                        }

                        ListView {
                            id: carousel
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 92
                            anchors.rightMargin: 92
                            anchors.verticalCenter: parent.verticalCenter
                            height: root.carouselHeight
                            orientation: ListView.Horizontal
                            model: root.filteredGames
                            currentIndex: root.selectedIndex
                            spacing: 28
                            clip: true
                            interactive: false
                            highlightMoveDuration: 0
                            preferredHighlightBegin: (width - root.cardW) / 2
                            preferredHighlightEnd: (width + root.cardW) / 2
                            highlightRangeMode: ListView.StrictlyEnforceRange

                            Behavior on contentX {
                                SmoothedAnimation { velocity: 1400 }
                            }

                            delegate: Item {
                                id: card

                                required property var modelData
                                required property int index

                                width: root.cardW
                                height: root.cardH

                                readonly property int offset: index - carousel.currentIndex
                                readonly property int absOff: Math.abs(offset)
                                readonly property bool selected: offset === 0

                                scale: selected ? 1.06 : 1.0
                                z: selected ? 10 : 10 - absOff

                                Rectangle {
                                    anchors.fill: parent
                                    color: card.selected ? TuiTheme.bg : TuiTheme.dim
                                    border.color: card.selected ? TuiTheme.highlight : TuiTheme.caution
                                    border.width: card.selected ? 2 : 1
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        source: scope.artSource(modelData.art)
                                        fillMode: Image.PreserveAspectCrop
                                        smooth: true
                                        asynchronous: true
                                        cache: true
                                        sourceSize: Qt.size(root.cardW * 2, root.cardH * 2)
                                    }

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        height: 34
                                        color: card.selected ? TuiTheme.highlight : TuiTheme.caution
                                    }

                                    Text {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        anchors.margins: 7
                                        height: 24
                                        text: modelData.name ?? "?"
                                        color: card.selected ? TuiTheme.bg : TuiTheme.fg
                                        font.family: TuiTheme.fontFamily
                                        font.pixelSize: TuiTheme.fontSize
                                        font.weight: TuiTheme.fontWeight
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: !modelData.art
                                        text: "NO ART"
                                        color: TuiTheme.barMuted
                                        font.family: TuiTheme.fontFamily
                                        font.pixelSize: TuiTheme.fontSize
                                        font.weight: TuiTheme.fontWeight
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: root.selectedIndex = index
                                    onClicked: {
                                        if (card.selected) root.launchSelected();
                                        else root.selectedIndex = index;
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: root.filteredGames.length === 0
                            text: searchField.text.length > 0 ? "NO MATCHES" : "NO GAMES FOUND"
                            color: TuiTheme.barMuted
                            font.family: TuiTheme.fontFamily
                            font.pixelSize: TuiTheme.fontSize + 2
                            font.weight: TuiTheme.fontWeight
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 82
                        color: "transparent"
                        border.color: TuiTheme.dim
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            spacing: 10

                            Text {
                                text: root.selectedGame?.name ?? "NO GAME SELECTED"
                                color: TuiTheme.highlight
                                font.family: TuiTheme.fontFamily
                                font.pixelSize: TuiTheme.fontSize + 4
                                font.weight: TuiTheme.fontWeight
                                width: panel.width - 80
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                width: 170
                                height: 34
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: launchMouse.containsMouse ? TuiTheme.highlight : TuiTheme.bg
                                border.color: TuiTheme.highlight
                                border.width: 1

                                Text {
                                    anchors.fill: parent
                                    text: "[ Launch ]"
                                    color: launchMouse.containsMouse ? TuiTheme.bg : TuiTheme.fg
                                    font.family: TuiTheme.fontFamily
                                    font.pixelSize: TuiTheme.fontSize + 1
                                    font.weight: TuiTheme.fontWeight
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                MouseArea {
                                    id: launchMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.launchSelected()
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 34
                        color: "transparent"
                        border.color: TuiTheme.dim
                        border.width: 1

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 28

                            Text {
                                text: "ctrl+h/l navigate"
                                color: TuiTheme.fg
                                font.family: TuiTheme.fontFamily
                                font.pixelSize: TuiTheme.fontSize
                                font.weight: TuiTheme.fontWeight
                            }

                            Text {
                                text: "enter launch"
                                color: TuiTheme.fg
                                font.family: TuiTheme.fontFamily
                                font.pixelSize: TuiTheme.fontSize
                                font.weight: TuiTheme.fontWeight
                            }

                            Text {
                                text: "esc quit"
                                color: TuiTheme.fg
                                font.family: TuiTheme.fontFamily
                                font.pixelSize: TuiTheme.fontSize
                                font.weight: TuiTheme.fontWeight
                            }
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.filteredGames.length + " GAMES"
                            color: TuiTheme.barMuted
                            font.family: TuiTheme.fontFamily
                            font.pixelSize: TuiTheme.fontSize
                            font.weight: TuiTheme.fontWeight
                        }
                    }
                }
            }
        }
    }
}
