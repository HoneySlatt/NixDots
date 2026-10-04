import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "services" as Services

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

    component GlassPill: Rectangle {
        property color fillColor: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.50)

        color: "transparent"
        border.color: Qt.tint(Theme.separator, Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.46))
        border.width: 1
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.tint(fillColor, Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.075)) }
            GradientStop { position: 0.62; color: fillColor }
            GradientStop { position: 1.0; color: Qt.tint(fillColor, Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.20)) }
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

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, parent.radius - 1)
            color: "transparent"
            border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.10)
            border.width: 1
        }
    }

    component ArrowButton: GlassPill {
        id: arrowButton

        property string icon: ""
        signal clicked()

        width: 54
        height: 54
        radius: 27
        fillColor: arrowMouse.containsMouse
            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22)
            : Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.40)

        Text {
            anchors.centerIn: parent
            text: arrowButton.icon
            color: arrowMouse.containsMouse ? Theme.text : Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 10
            font.weight: Font.Bold
        }

        MouseArea {
            id: arrowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: arrowButton.clicked()
        }
    }

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
                color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.75)
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

            GlassPill {
                id: searchBar
                anchors.horizontalCenter: parent.horizontalCenter
                y: Math.max(54, parent.height * 0.115)
                width: 430
                height: 48
                radius: 24
                fillColor: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.48)

                Rectangle {
                    visible: searchField.activeFocus
                    anchors.fill: parent
                    anchors.margins: -3
                    radius: parent.radius + 3
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 16
                    spacing: 12

                    Text {
                        text: "\uf002"
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 4
                        Layout.alignment: Qt.AlignVCenter
                    }

                    TextInput {
                        id: searchField
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.text
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.background
                        clip: true
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 1
                        font.weight: Theme.fontWeight
                        onTextChanged: root.searchQuery = text.toLowerCase()

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Search games..."
                            color: Theme.muted
                            opacity: 0.72
                            font.family: searchField.font.family
                            font.pixelSize: searchField.font.pixelSize
                            font.weight: searchField.font.weight
                            visible: searchField.text.length === 0
                        }
                    }
                }
            }

            ArrowButton {
                anchors.left: parent.left
                anchors.leftMargin: 32
                anchors.verticalCenter: carousel.verticalCenter
                icon: "\uf053"
                onClicked: if (root.selectedIndex > 0) root.selectedIndex--
            }

            ArrowButton {
                anchors.right: parent.right
                anchors.rightMargin: 32
                anchors.verticalCenter: carousel.verticalCenter
                icon: "\uf054"
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
                        radius: 12
                        color: Qt.rgba(Theme.separator.r, Theme.separator.g, Theme.separator.b, 0.36)
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: launcherScope.artSource(modelData.art)
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            asynchronous: true
                            sourceSize: Qt.size(root.cardW * 2, root.cardH * 2)
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: "transparent"
                            border.color: card.isSelected
                                ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.90)
                                : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
                            border.width: card.isSelected ? 2 : 1
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

            Text {
                id: gameTitle
                anchors.horizontalCenter: parent.horizontalCenter
                y: carousel.y + root.cardH + 28
                text: root.filteredGames[root.selectedIndex]?.name ?? ""
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 12
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
                style: Text.Outline
                styleColor: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.50)
            }

            GlassPill {
                id: launchBar
                anchors.horizontalCenter: parent.horizontalCenter
                y: gameTitle.y + gameTitle.height + 28
                width: 250
                height: 50
                radius: 25
                fillColor: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.48)

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 12

                    Text {
                        text: "\uf04b"
                        color: launchMouse.containsMouse ? Theme.text : Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 2
                        font.weight: Font.Bold
                    }

                    Text {
                        text: "Launch"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 1
                        font.weight: Font.Bold
                    }
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
}
