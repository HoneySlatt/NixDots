import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "services" as Services

Item {
    id: launcherScope

    component GlowPanel: Rectangle {
        radius: 34
        color: "transparent"
        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.42)
        border.width: 2

        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.tint(Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, Theme.popupOpacity), Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.10)) }
            GradientStop { position: 0.55; color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, Theme.popupOpacity) }
            GradientStop { position: 1.0; color: Qt.tint(Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, Theme.popupOpacity), Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08)) }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: parent.radius - 2
            color: "transparent"
            border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10)
            border.width: 1
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 18
            radius: parent.radius - 10
            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.035)
        }
    }

    component RoundButton: Rectangle {
        id: button

        property string icon: ""
        property bool primary: false
        signal clicked()

        width: primary ? 60 : 46
        height: primary ? 60 : 46
        radius: width / 2
        color: primary
            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, mouse.containsMouse ? 0.34 : 0.24)
            : Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, mouse.containsMouse ? 0.58 : 0.36)
        border.color: primary ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.92) : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.34)
        border.width: primary ? 2 : 1

        Rectangle {
            anchors.fill: parent
            anchors.margins: primary ? -7 : -4
            radius: width / 2
            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, primary ? 0.12 : 0.06)
            visible: button.primary || mouse.containsMouse
        }

        Text {
            anchors.centerIn: parent
            text: button.icon
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: button.primary ? Theme.fontSize + 10 : Theme.fontSize + 5
            font.weight: Font.Bold
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root

            required property var modelData
            screen: modelData
            visible: MusicLauncherState.visible && monitorIsFocused

            readonly property bool monitorIsFocused: Services.NiriData.activeWorkspace !== null && Services.NiriData.activeWorkspace.output === root.screen.name
            onMonitorIsFocusedChanged: if (!monitorIsFocused) MusicLauncherState.close()
            

            property int sectionIndex: 0
            property int selectedIndex: 0
            property string searchQuery: ""
            property bool pendingAutoPlayCollection: false

            readonly property var sectionTabs: [
                { label: "Playlists", icon: "\uf03a" },
                { label: "Albums", icon: "\uf51f" },
                { label: "Artists", icon: "\uf007" },
                { label: "Songs", icon: "\uf001" },
                { label: "Favorites", icon: "\uf005" }
            ]

            color: "transparent"

            WlrLayershell.namespace: "quickshell:music-launcher"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore

            anchors { top: true; bottom: true; left: true; right: true }

            function rawItems() {
                if (sectionIndex === 0) return MusicService.playlists;
                if (sectionIndex === 1) return MusicService.albums;
                if (sectionIndex === 2) return MusicService.artists;
                if (sectionIndex === 3) return MusicService.songs;
                return MusicService.favorites;
            }

            function currentItems() {
                const query = searchQuery.trim().toLowerCase();
                const items = rawItems();
                if (query.length === 0) return items;
                return items.filter(item => (titleFor(item) + " " + subtitleFor(item)).toLowerCase().includes(query));
            }

            function titleFor(item) {
                if (!item) return "";
                return item.title ?? item.name ?? "Unknown";
            }

            function subtitleFor(item) {
                if (!item) return "";
                if (item.itemType === "playlist") return (item.songCount ?? 0) + " tracks";
                if (item.itemType === "album") return item.artist ?? "Album";
                if (item.itemType === "artist") return (item.albumCount ?? 0) + " albums";
                return [item.artist, item.album].filter(v => v && v.length > 0).join(" - ");
            }

            function artFor(item) {
                if (!item) return "";
                if (item.itemType === "artist" && item.artistImageUrl) return item.artistImageUrl;
                return MusicService.coverUrl(item.coverArt ?? item.id);
            }

            function clampSelection() {
                const count = currentItems().length;
                selectedIndex = Math.max(0, Math.min(count - 1, selectedIndex));
            }

            function playSelected(index) {
                const items = currentItems();
                const item = items[index];
                if (!item) return;

                selectedIndex = index;
                if (!MusicService.shuffleEnabled) MusicService.toggleShuffle();

                if (item.itemType === "song") {
                    MusicService.playTracks(items, sectionIndex === 3 ? "Songs" : "Favorites", index);
                    return;
                }

                pendingAutoPlayCollection = true;
                if (item.itemType === "playlist") MusicService.openPlaylist(item.id, titleFor(item));
                else if (item.itemType === "album") MusicService.openAlbum(item.id, titleFor(item));
                else if (item.itemType === "artist") MusicService.openArtist(item.id, titleFor(item));
            }

            function activate() {
                playSelected(selectedIndex);
            }

            function moveSelection(delta) {
                const count = currentItems().length;
                if (count === 0) return;
                selectedIndex = (selectedIndex + delta + count) % count;
                Qt.callLater(() => cardList.positionViewAtIndex(selectedIndex, ListView.Center));
            }

            function formatTime(seconds) {
                if (isNaN(seconds) || seconds < 0) return "0:00";
                const minutes = Math.floor(seconds / 60);
                const remaining = Math.floor(seconds % 60);
                return minutes + ":" + (remaining < 10 ? "0" : "") + remaining;
            }

            onSectionIndexChanged: {
                selectedIndex = 0;
                searchField.text = "";
                Qt.callLater(() => cardList.positionViewAtIndex(0, ListView.Beginning));
            }

            onSelectedIndexChanged: Qt.callLater(() => cardList.positionViewAtIndex(selectedIndex, ListView.Center))

            onVisibleChanged: {
                if (visible) {
                    focusTimer.start();
                    clampSelection();
                }
            }

            Connections {
                target: MusicService
                function onTracksChanged() {
                    if (!root.pendingAutoPlayCollection || MusicService.tracks.length === 0) return;
                    root.pendingAutoPlayCollection = false;
                    const startIndex = Math.floor(Math.random() * MusicService.tracks.length);
                    if (!MusicService.shuffleEnabled) MusicService.toggleShuffle();
                    MusicService.playTracks(MusicService.tracks, MusicService.currentCollectionTitle, startIndex);
                }
                function onPlaylistsChanged() { root.clampSelection(); }
                function onAlbumsChanged() { root.clampSelection(); }
                function onArtistsChanged() { root.clampSelection(); }
                function onSongsChanged() { root.clampSelection(); }
                function onFavoritesChanged() { root.clampSelection(); }
            }

            Timer {
                id: focusTimer
                interval: 80
                repeat: false
                onTriggered: keyLayer.forceActiveFocus()
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.70)
            }

            Rectangle {
                anchors.fill: parent
                opacity: 0.24
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.34) }
                    GradientStop { position: 0.48; color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.06) }
                    GradientStop { position: 1.0; color: Qt.rgba(Theme.highlight.r, Theme.highlight.g, Theme.highlight.b, 0.18) }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: MusicLauncherState.close()
            }

            Item {
                id: keyLayer
                anchors.fill: parent
                focus: MusicLauncherState.visible

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        MusicLauncherState.close();
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_Space && event.modifiers & Qt.ControlModifier) {
                        MusicService.togglePause();
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.activate();
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_N && event.modifiers & Qt.ControlModifier) {
                        MusicService.next();
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_P && event.modifiers & Qt.ControlModifier) {
                        MusicService.previous();
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_Minus && event.modifiers & Qt.ControlModifier) {
                        MusicService.adjustVolume(-10);
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_Equal && event.modifiers & Qt.ControlModifier) {
                        MusicService.adjustVolume(10);
                        event.accepted = true;
                        return;
                    }
                    if (event.modifiers & Qt.ControlModifier && event.key >= Qt.Key_1 && event.key <= Qt.Key_5) {
                        root.sectionIndex = event.key - Qt.Key_1;
                        event.accepted = true;
                        return;
                    }
                    if ((event.key === Qt.Key_H && event.modifiers & Qt.ControlModifier) || event.key === Qt.Key_Left || (event.key === Qt.Key_K && event.modifiers & Qt.ControlModifier) || event.key === Qt.Key_Up) {
                        root.moveSelection(-1);
                        event.accepted = true;
                        return;
                    }
                    if ((event.key === Qt.Key_L && event.modifiers & Qt.ControlModifier) || event.key === Qt.Key_Right || (event.key === Qt.Key_J && event.modifiers & Qt.ControlModifier) || event.key === Qt.Key_Down) {
                        root.moveSelection(1);
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

            GlowPanel {
                id: panel
                anchors.centerIn: parent
                width: Math.min(parent.width - 96, 1360)
                height: Math.min(parent.height - 126, 800)

                MouseArea { anchors.fill: parent; onClicked: keyLayer.forceActiveFocus() }

                Rectangle {
                    id: searchBox
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 34
                    width: Math.min(parent.width * 0.52, 660)
                    height: 58
                    radius: 22
                    color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.48)
                    border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, searchMouse.containsMouse || searchField.activeFocus ? 0.54 : 0.22)
                    border.width: 2

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 22
                        anchors.rightMargin: 22
                        spacing: 14

                        Text {
                            text: "\uf002"
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize + 7
                        }

                        TextInput {
                            id: searchField
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.text
                            selectionColor: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.62)
                            selectedTextColor: Theme.background
                            clip: true
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize + 3
                            onTextChanged: {
                                root.searchQuery = text;
                                root.selectedIndex = 0;
                            }

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Search music..."
                                color: Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.78)
                                font.family: searchField.font.family
                                font.pixelSize: searchField.font.pixelSize
                                visible: searchField.text.length === 0
                            }
                        }
                    }

                    MouseArea {
                        id: searchMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                }
                RowLayout {
                    id: tabs
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: searchBox.bottom
                    anchors.topMargin: 32
                    spacing: 26

                    Repeater {
                        model: root.sectionTabs

                        Rectangle {
                            required property var modelData
                            required property int index

                            Layout.preferredWidth: Math.max(132, tabLabel.implicitWidth + 54)
                            Layout.preferredHeight: 44
                            radius: 16
                            color: root.sectionIndex === index ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.24) : "transparent"
                            border.color: root.sectionIndex === index ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.58) : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, tabMouse.containsMouse ? 0.30 : 0.08)
                            border.width: 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 10

                                Text {
                                    text: modelData.icon
                                    color: root.sectionIndex === index ? Theme.text : Theme.muted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                }

                                Text {
                                    id: tabLabel
                                    text: modelData.label
                                    color: root.sectionIndex === index ? Theme.text : Theme.muted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize + 1
                                    font.weight: Font.Bold
                                }
                            }

                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.sectionIndex = index
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: tabs.bottom
                    anchors.leftMargin: 170
                    anchors.rightMargin: 170
                    anchors.topMargin: 18
                    height: 1
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.10)
                }

                Text {
                    anchors.left: cardList.left
                    anchors.bottom: cardList.top
                    anchors.bottomMargin: 8
                    text: root.currentItems().length + " items"
                    color: Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.72)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 52
                    anchors.verticalCenter: cardList.verticalCenter
                    text: "\uf104"
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.86)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 24

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -18
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.moveSelection(-1)
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 52
                    anchors.verticalCenter: cardList.verticalCenter
                    text: "\uf105"
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.86)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 24

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -18
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.moveSelection(1)
                    }
                }

                ListView {
                    id: cardList
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: tabs.bottom
                    anchors.leftMargin: 118
                    anchors.rightMargin: 118
                    anchors.topMargin: 64
                    height: 258
                    orientation: ListView.Horizontal
                    spacing: 26
                    clip: true
                    model: root.currentItems()
                    currentIndex: root.selectedIndex
                    highlightMoveDuration: 160

                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        required property int index

                        readonly property bool selected: root.selectedIndex === index

                        width: selected ? 226 : 176
                        height: selected ? 250 : 212
                        y: selected ? 0 : 24
                        radius: 0
                        color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, selected ? 0.86 : 0.66)
                        border.color: selected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.96) : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, mouse.containsMouse ? 0.38 : 0.14)
                        border.width: selected ? 2 : 1

                        Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                        Image {
                            anchors.fill: parent
                            source: root.artFor(modelData)
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            asynchronous: true
                            sourceSize: Qt.size(520, 520)
                            opacity: root.artFor(modelData).length > 0 ? 1.0 : 0.0
                        }

                        Rectangle {
                            anchors.fill: parent
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.10) }
                                GradientStop { position: 0.52; color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.20) }
                                GradientStop { position: 1.0; color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.90) }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: root.artFor(modelData).length === 0
                            text: modelData.itemType === "artist" ? "\uf007" : "\uf001"
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.42)
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize + 36
                        }

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: selected ? 22 : 18
                            anchors.rightMargin: selected ? 22 : 18
                            anchors.bottomMargin: selected ? 22 : 18
                            spacing: 5

                            Text {
                                Layout.fillWidth: true
                                text: root.titleFor(modelData)
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: selected ? Theme.fontSize + 5 : Theme.fontSize + 1
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.subtitleFor(modelData)
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: selected ? Theme.fontSize + 1 : Theme.fontSize - 2
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.playSelected(index)
                        }
                    }
                }

                Rectangle {
                    id: divider
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: cardList.bottom
                    anchors.leftMargin: 36
                    anchors.rightMargin: 36
                    anchors.topMargin: 22
                    height: 2
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                }

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: divider.bottom
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 116
                    anchors.rightMargin: 116
                    anchors.topMargin: 18
                    anchors.bottomMargin: 24
                    spacing: 32

                    Rectangle {
                        Layout.preferredWidth: 178
                        Layout.preferredHeight: 178
                        radius: 0
                        color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.72)
                        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.92)
                        border.width: 2
                        clip: true

                        Image {
                            anchors.fill: parent
                            anchors.margins: 2
                            source: MusicService.currentTrack ? MusicService.coverUrl(MusicService.currentTrack.coverArt ?? MusicService.currentTrack.id) : ""
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            asynchronous: true
                            sourceSize: Qt.size(540, 540)
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: MusicService.currentTrack === null
                            text: "\uf001"
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.38)
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize + 44
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Text {
                                text: MusicService.currentTrack ? "Now Playing" : (root.pendingAutoPlayCollection ? "Loading collection" : "Ready")
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 1
                                font.weight: Font.Bold
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: MusicService.ready ? "Navidrome" : "Disconnected"
                                color: MusicService.ready ? Theme.accent : Theme.warning
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 2
                                font.weight: Font.Bold
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: MusicService.currentTrack?.title ?? "Nothing playing"
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize + 18
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: MusicService.currentTrack ? [MusicService.currentTrack.artist, MusicService.currentTrack.album].filter(v => v && v.length > 0).join(" - ") : "Choose a playlist, album, artist, song, or favorite"
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize + 2
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }

                        Item { Layout.preferredHeight: 4 }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 18

                            Text {
                                text: root.formatTime(MusicService.position)
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 1
                                font.weight: Font.Bold
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 7
                                radius: 4
                                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10)

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: parent.width * Math.max(0, Math.min(1, MusicService.duration > 0 ? MusicService.position / MusicService.duration : 0))
                                    radius: parent.radius
                                    color: Theme.accent
                                }

                                Rectangle {
                                    width: 18
                                    height: 18
                                    radius: 9
                                    x: Math.max(0, Math.min(parent.width - width, parent.width * Math.max(0, Math.min(1, MusicService.duration > 0 ? MusicService.position / MusicService.duration : 0)) - width / 2))
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: Theme.accent
                                }
                            }

                            Text {
                                text: root.formatTime(MusicService.duration)
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize - 1
                                font.weight: Font.Bold
                            }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 10
                            spacing: 28

                            RoundButton { icon: "\uf074"; primary: MusicService.shuffleEnabled; onClicked: MusicService.toggleShuffle() }
                            RoundButton { icon: "\uf048"; onClicked: MusicService.previous() }
                            RoundButton { icon: MusicService.playing ? "\uf04c" : "\uf04b"; primary: true; onClicked: MusicService.togglePause() }
                            RoundButton { icon: "\uf051"; onClicked: MusicService.next() }
                            RoundButton { icon: MusicService.currentTrackFavorite ? "\uf004" : "\uf08a"; primary: MusicService.currentTrackFavorite; onClicked: MusicService.toggleCurrentFavorite() }
                        }
                    }
                }
            }
        }
    }
}
