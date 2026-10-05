import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "services" as Services
import "m3" as M3

Item {
    id: launcherScope

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
                launcherScope.allGames = JSON.parse(gamesProc.buffer);
            } catch (e) {
                launcherScope.allGames = [];
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
            visible: SteamLauncherState.visible && monitorIsFocused

            readonly property bool monitorIsFocused: Services.NiriData.activeWorkspace !== null && Services.NiriData.activeWorkspace.output === root.screen.name
            onMonitorIsFocusedChanged: if (!monitorIsFocused) SteamLauncherState.close()
            

            color: "transparent"

            WlrLayershell.namespace: "quickshell:steam-launcher"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors { top: true; bottom: true; left: true; right: true }

            property int selectedIndex: 0
            property string searchQuery: ""
            property var filteredGames: []

            readonly property int cardW: 280
            readonly property int cardH: 420
            readonly property int carouselHeight: cardH + 44

            function centerIndex() {
                return Math.floor(filteredGames.length / 2);
            }

            function clampSelection() {
                selectedIndex = Math.max(0, Math.min(filteredGames.length - 1, selectedIndex));
            }

            function positionCarousel() {
                if (filteredGames.length > 0)
                    carousel.positionViewAtIndex(selectedIndex, ListView.Center);
            }

            function filterList() {
                if (searchQuery.length === 0) {
                    filteredGames = launcherScope.allGames;
                    selectedIndex = centerIndex();
                } else {
                    filteredGames = launcherScope.allGames.filter(g =>
                        g.name?.toLowerCase().includes(searchQuery)
                    );
                    selectedIndex = 0;
                }
                carousel.currentIndex = selectedIndex;
                positionCarousel();
            }

            function launchSelected() {
                if (filteredGames.length === 0) return;
                const game = filteredGames[selectedIndex];
                const launchUrl = game.launchUrl || (game.appid ? "steam://rungameid/" + game.appid : "");
                if (!launchUrl) return;
                Qt.openUrlExternally(launchUrl);
                SteamLauncherState.close();
            }

            onSearchQueryChanged: filterList()
            onSelectedIndexChanged: positionCarousel()

            onVisibleChanged: {
                if (visible) {
                    launcherScope.refreshGames();
                    searchField.text = "";
                    searchQuery = "";
                    selectedIndex = centerIndex();
                    focusTimer.start();
                    Qt.callLater(positionCarousel);
                }
            }

            Connections {
                target: launcherScope
                function onAllGamesChanged() { root.filterList(); }
            }

            Timer {
                id: focusTimer
                interval: 80
                repeat: false
                onTriggered: keyLayer.forceActiveFocus()
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.alpha(Theme.surfaceContainerLowest, 0.86)
            }

            MouseArea {
                anchors.fill: parent
                onClicked: SteamLauncherState.close()
            }

            Item {
                id: keyLayer
                anchors.fill: parent
                focus: SteamLauncherState.visible

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        SteamLauncherState.close();
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.launchSelected();
                        event.accepted = true;
                        return;
                    }
                    if ((event.key === Qt.Key_H && event.modifiers & Qt.ControlModifier) || event.key === Qt.Key_Left) {
                        if (root.selectedIndex > 0) root.selectedIndex--;
                        event.accepted = true;
                        return;
                    }
                    if ((event.key === Qt.Key_L && event.modifiers & Qt.ControlModifier) || event.key === Qt.Key_Right) {
                        if (root.selectedIndex < root.filteredGames.length - 1) root.selectedIndex++;
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
            }

            M3.SearchField {
                id: searchField
                anchors.horizontalCenter: parent.horizontalCenter
                y: Math.max(54, parent.height * 0.115)
                width: 480
                placeholder: "Search games"
                onTextChanged: root.searchQuery = text.toLowerCase()
            }

            M3.IconButton {
                anchors.left: parent.left
                z: 200
                anchors.leftMargin: 40
                anchors.verticalCenter: carousel.verticalCenter
                size: 64
                variant: "tonal"
                icon: "\u{f0141}"
                onClicked: if (root.selectedIndex > 0) root.selectedIndex--
            }

            M3.IconButton {
                anchors.right: parent.right
                z: 200
                anchors.rightMargin: 40
                anchors.verticalCenter: carousel.verticalCenter
                size: 64
                variant: "tonal"
                icon: "\u{f0142}"
                onClicked: if (root.selectedIndex < root.filteredGames.length - 1) root.selectedIndex++
            }

            ListView {
                id: carousel
                anchors.left: parent.left
                anchors.right: parent.right
                y: Math.round(parent.height * 0.27)
                height: root.carouselHeight
                orientation: ListView.Horizontal
                model: root.filteredGames
                currentIndex: root.selectedIndex
                spacing: 30
                clip: false
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

                    property int offset: index - carousel.currentIndex
                    property real absOff: Math.abs(offset)
                    property real cardScale: Math.max(0.48, 1.0 - absOff * 0.145)
                    property real cardOpacity: Math.max(0.25, 1.0 - absOff * 0.17)
                    property bool isSelected: offset === 0

                    opacity: cardOpacity
                    z: 100 - absOff

                    transform: [
                        Rotation {
                            origin.x: root.cardW / 2
                            origin.y: root.cardH / 2
                            axis { x: 0; y: 1; z: 0 }
                            angle: -(card.offset < 0 ? -1 : card.offset > 0 ? 1 : 0) * Math.min(16, Math.pow(card.absOff, 1.28) * 5.2)
                        },
                        Scale {
                            origin.x: root.cardW / 2
                            origin.y: root.cardH / 2
                            xScale: card.cardScale
                            yScale: card.cardScale
                        }
                    ]

                    Rectangle {
                        id: artFrame
                        anchors.fill: parent
                        radius: card.isSelected ? Theme.shapeXXL : Theme.shapeXL
                        color: Theme.surfaceContainerHigh

                        Behavior on radius { M3.Spring {} }

                        M3.Icon {
                            anchors.centerIn: parent
                            visible: art.status !== Image.Ready
                            icon: "\u{f0297}"
                            size: 64
                            color: Theme.textOnSurfaceVariant
                        }

                        M3.RoundedImage {
                            id: art
                            anchors.fill: parent
                            radius: artFrame.radius
                            source: launcherScope.artSource(card.modelData.art)
                            sourceSize: Qt.size(root.cardW * 2, root.cardH * 2)
                        }

                        M3.FocusRing {
                            shown: card.isSelected
                            border.color: Theme.primary
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (card.isSelected) root.launchSelected();
                            else root.selectedIndex = index;
                        }
                    }
                }
            }

            M3.Label {
                id: gameTitle
                anchors.horizontalCenter: parent.horizontalCenter
                y: carousel.y + root.cardH + 36
                width: Math.min(implicitWidth, parent.width - 120)
                text: root.filteredGames[root.selectedIndex]?.name ?? ""
                font.pixelSize: Theme.typeHeadline + 6
                font.weight: Font.ExtraBold
                horizontalAlignment: Text.AlignHCenter
            }

            M3.Button {
                id: launchBar
                anchors.horizontalCenter: parent.horizontalCenter
                y: gameTitle.y + gameTitle.height + 24
                size: 64
                implicitWidth: 220
                variant: "filled"
                icon: "\u{f040a}"
                iconSize: 26
                text: "Play"
                labelSize: Theme.typeTitleL
                onClicked: root.launchSelected()
            }
        }
    }
}
