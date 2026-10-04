import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: scope

    component ControlButton: Rectangle {
        id: button

        property string label: ""
        property bool active: false
        signal clicked()

        width: 72
        height: 38
        color: mouse.containsMouse || active ? TuiTheme.highlight : TuiTheme.bg
        border.color: active ? TuiTheme.highlight : TuiTheme.caution
        border.width: active ? 2 : 1

        Text {
            anchors.fill: parent
            text: button.label
            color: mouse.containsMouse || button.active ? TuiTheme.bg : TuiTheme.fg
            font.family: TuiTheme.fontFamily
            font.pixelSize: TuiTheme.fontSize + 1
            font.weight: TuiTheme.fontWeight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
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
            visible: TuiMusicLauncherState.visible && monitorIsFocused

            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
            readonly property bool monitorIsFocused: Hyprland.focusedMonitor?.id === monitor?.id

            property int sectionIndex: 0
            property int selectedIndex: 0
            property string searchQuery: ""
            property bool pendingAutoPlayCollection: false

            readonly property var sectionTabs: [
                { label: "Playlists" },
                { label: "Albums" },
                { label: "Artists" },
                { label: "Songs" },
                { label: "Favorites" }
            ]

            color: "transparent"

            WlrLayershell.namespace: "quickshell:tui:musiclauncher"
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

            function currentCover() {
                return MusicService.currentTrack ? MusicService.coverUrl(MusicService.currentTrack.coverArt ?? MusicService.currentTrack.id) : "";
            }

            function clampSelection() {
                const count = currentItems().length;
                selectedIndex = Math.max(0, Math.min(count - 1, selectedIndex));
            }

            function positionCards() {
                if (currentItems().length > 0)
                    cardList.positionViewAtIndex(selectedIndex, ListView.Center);
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

            function moveSelection(delta) {
                const count = currentItems().length;
                if (count === 0) return;
                selectedIndex = (selectedIndex + delta + count) % count;
                Qt.callLater(positionCards);
            }

            function formatTime(seconds) {
                if (isNaN(seconds) || seconds < 0) return "0:00";
                const minutes = Math.floor(seconds / 60);
                const remaining = Math.floor(seconds % 60);
                return minutes + ":" + (remaining < 10 ? "0" : "") + remaining;
            }

            function handleKey(event) {
                if (event.key === Qt.Key_Escape) { TuiMusicLauncherState.close(); event.accepted = true; return; }
                if (event.key === Qt.Key_Space && event.modifiers & Qt.ControlModifier) { MusicService.togglePause(); event.accepted = true; return; }
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { playSelected(selectedIndex); event.accepted = true; return; }
                if (event.key === Qt.Key_N && event.modifiers & Qt.ControlModifier) { MusicService.next(); event.accepted = true; return; }
                if (event.key === Qt.Key_P && event.modifiers & Qt.ControlModifier) { MusicService.previous(); event.accepted = true; return; }
                if (event.key === Qt.Key_Minus && event.modifiers & Qt.ControlModifier) { MusicService.adjustVolume(-10); event.accepted = true; return; }
                if (event.key === Qt.Key_Equal && event.modifiers & Qt.ControlModifier) { MusicService.adjustVolume(10); event.accepted = true; return; }
                if (event.modifiers & Qt.ControlModifier && event.key >= Qt.Key_1 && event.key <= Qt.Key_5) { sectionIndex = event.key - Qt.Key_1; event.accepted = true; return; }
                if ((event.key === Qt.Key_H && event.modifiers & Qt.ControlModifier) || event.key === Qt.Key_Left || (event.key === Qt.Key_K && event.modifiers & Qt.ControlModifier) || event.key === Qt.Key_Up) { moveSelection(-1); event.accepted = true; return; }
                if ((event.key === Qt.Key_L && event.modifiers & Qt.ControlModifier) || event.key === Qt.Key_Right || (event.key === Qt.Key_J && event.modifiers & Qt.ControlModifier) || event.key === Qt.Key_Down) { moveSelection(1); event.accepted = true; return; }
                if (event.key === Qt.Key_Backspace) { searchField.text = searchField.text.slice(0, -1); event.accepted = true; return; }
                if (event.text.length > 0 && !event.modifiers) { searchField.text += event.text; event.accepted = true; }
            }

            onSectionIndexChanged: {
                selectedIndex = 0;
                searchField.text = "";
                Qt.callLater(positionCards);
            }

            onSelectedIndexChanged: Qt.callLater(positionCards)

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

            HyprlandFocusGrab {
                id: grab
                windows: [root]
                active: false
                onCleared: () => { if (!active) TuiMusicLauncherState.close(); }
                onActiveChanged: if (active) focusTimer.start()
            }

            Connections {
                target: TuiMusicLauncherState
                function onVisibleChanged() {
                    if (TuiMusicLauncherState.visible) {
                        grabTimer.start();
                        focusTimer.start();
                        clampSelection();
                        Qt.callLater(positionCards);
                    } else {
                        grabTimer.stop();
                        focusTimer.stop();
                        grab.active = false;
                    }
                }
            }

            Timer { id: grabTimer; interval: 50; repeat: false; onTriggered: grab.active = TuiMusicLauncherState.visible }
            Timer { id: focusTimer; interval: 80; repeat: false; onTriggered: keyLayer.forceActiveFocus() }

            MouseArea { anchors.fill: parent; onClicked: TuiMusicLauncherState.close() }

            Item {
                id: keyLayer
                anchors.fill: parent
                focus: TuiMusicLauncherState.visible
                Keys.onPressed: event => root.handleKey(event)
            }

            Rectangle {
                id: panel
                anchors.centerIn: parent
                width: Math.min(parent.width - 120, 1260)
                height: Math.min(parent.height - 120, 720)
                color: TuiTheme.bg
                border.color: TuiTheme.dim
                border.width: 2

                MouseArea { anchors.fill: parent; onClicked: keyLayer.forceActiveFocus() }

                Rectangle { anchors.fill: parent; anchors.margins: 6; color: "transparent"; border.color: TuiTheme.caution; border.width: 1 }

                Column {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 14

                    Rectangle {
                        width: parent.width
                        height: 46
                        color: TuiTheme.dim
                        border.color: searchField.text.length > 0 ? TuiTheme.highlight : TuiTheme.caution
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 12

                            Text { width: 22; height: parent.height; text: ">"; color: TuiTheme.bright; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.fontSize + 5; font.weight: TuiTheme.fontWeight; verticalAlignment: Text.AlignVCenter }

                            TextInput {
                                id: searchField
                                width: parent.width - 34
                                height: parent.height
                                readOnly: true
                                clip: true
                                color: TuiTheme.fg
                                selectionColor: TuiTheme.highlight
                                selectedTextColor: TuiTheme.bg
                                font.family: TuiTheme.fontFamily
                                font.pixelSize: TuiTheme.fontSize + 2
                                font.weight: TuiTheme.fontWeight
                                verticalAlignment: TextInput.AlignVCenter
                                onTextChanged: { root.searchQuery = text; root.selectedIndex = 0; }
                                Keys.onPressed: event => root.handleKey(event)

                                Text { anchors.fill: parent; verticalAlignment: Text.AlignVCenter; text: "Search music..."; color: TuiTheme.barMuted; font.family: searchField.font.family; font.pixelSize: searchField.font.pixelSize; font.weight: searchField.font.weight; visible: searchField.text.length === 0 }
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        height: 40
                        spacing: 24

                        Repeater {
                            model: root.sectionTabs

                            Rectangle {
                                required property var modelData
                                required property int index

                                width: Math.max(142, tabText.implicitWidth + 34)
                                height: parent.height
                                color: root.sectionIndex === index ? TuiTheme.dim : "transparent"
                                border.color: root.sectionIndex === index ? TuiTheme.highlight : TuiTheme.caution
                                border.width: 1

                                Text {
                                    id: tabText
                                    anchors.centerIn: parent
                                    text: "[" + (index + 1) + "] " + modelData.label
                                    color: root.sectionIndex === index ? TuiTheme.highlight : TuiTheme.fg
                                    font.family: TuiTheme.fontFamily
                                    font.pixelSize: TuiTheme.fontSize
                                    font.weight: TuiTheme.fontWeight
                                }

                                MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.sectionIndex = index }
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: 286

                        Rectangle { anchors.fill: parent; color: "transparent"; border.color: TuiTheme.dim; border.width: 1 }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: cardList.verticalCenter
                            text: "<"
                            color: TuiTheme.highlight
                            font.family: TuiTheme.fontFamily
                            font.pixelSize: TuiTheme.fontSize + 24
                            font.weight: TuiTheme.fontWeight
                            MouseArea { anchors.fill: parent; anchors.margins: -18; cursorShape: Qt.PointingHandCursor; onClicked: root.moveSelection(-1) }
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 16
                            anchors.verticalCenter: cardList.verticalCenter
                            text: ">"
                            color: TuiTheme.highlight
                            font.family: TuiTheme.fontFamily
                            font.pixelSize: TuiTheme.fontSize + 24
                            font.weight: TuiTheme.fontWeight
                            MouseArea { anchors.fill: parent; anchors.margins: -18; cursorShape: Qt.PointingHandCursor; onClicked: root.moveSelection(1) }
                        }

                        ListView {
                            id: cardList
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 74
                            anchors.rightMargin: 74
                            anchors.verticalCenter: parent.verticalCenter
                            height: 260
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

                                width: selected ? 208 : 158
                                height: selected ? 258 : 210
                                y: selected ? 0 : 24
                                color: selected ? TuiTheme.bg : TuiTheme.dim
                                border.color: selected ? TuiTheme.highlight : TuiTheme.caution
                                border.width: selected ? 2 : 1
                                clip: true

                                Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                Behavior on y { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                                Image { anchors.fill: parent; anchors.margins: 5; source: root.artFor(modelData); fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: true; sourceSize: Qt.size(420, 420); opacity: root.artFor(modelData).length > 0 ? 1.0 : 0.0 }

                                Rectangle {
                                    anchors.fill: parent
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: Qt.rgba(TuiTheme.bg.r, TuiTheme.bg.g, TuiTheme.bg.b, 0.02) }
                                        GradientStop { position: 0.55; color: Qt.rgba(TuiTheme.bg.r, TuiTheme.bg.g, TuiTheme.bg.b, 0.12) }
                                        GradientStop { position: 1.0; color: Qt.rgba(TuiTheme.bg.r, TuiTheme.bg.g, TuiTheme.bg.b, 0.92) }
                                    }
                                }

                                Text { anchors.centerIn: parent; visible: root.artFor(modelData).length === 0; text: "MUSIC"; color: TuiTheme.barMuted; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.fontSize + 6; font.weight: TuiTheme.fontWeight }

                                Column {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.margins: selected ? 16 : 12
                                    spacing: 5

                                    Text { width: parent.width; text: root.titleFor(modelData); color: TuiTheme.fg; font.family: TuiTheme.fontFamily; font.pixelSize: selected ? TuiTheme.fontSize + 2 : TuiTheme.fontSize; font.weight: TuiTheme.fontWeight; elide: Text.ElideRight }
                                    Text { width: parent.width; text: root.subtitleFor(modelData); color: TuiTheme.barMuted; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.fontSize; font.weight: TuiTheme.fontWeight; elide: Text.ElideRight }
                                }

                                MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: root.selectedIndex = index; onClicked: root.playSelected(index) }
                            }
                        }

                        Text { anchors.centerIn: parent; visible: root.currentItems().length === 0; text: root.searchQuery.length > 0 ? "NO MATCHES" : "NO MUSIC"; color: TuiTheme.barMuted; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.fontSize + 2; font.weight: TuiTheme.fontWeight }
                    }

                    Rectangle { width: parent.width; height: 2; color: TuiTheme.dim }

                    Row {
                        width: parent.width
                        height: 160
                        spacing: 22

                        Rectangle {
                            width: 150
                            height: 150
                            color: TuiTheme.dim
                            border.color: TuiTheme.highlight
                            border.width: 1
                            clip: true

                            Image { anchors.fill: parent; anchors.margins: 4; source: root.currentCover(); fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: true; sourceSize: Qt.size(360, 360) }
                            Text { anchors.centerIn: parent; visible: !MusicService.currentTrack; text: "MUSIC"; color: TuiTheme.barMuted; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.fontSize; font.weight: TuiTheme.fontWeight }
                        }

                        Column {
                            width: parent.width - 172
                            height: parent.height
                            spacing: 8

                            Row {
                                width: parent.width
                                height: 22

                                Text { text: MusicService.currentTrack ? "Now Playing" : (root.pendingAutoPlayCollection ? "Loading collection" : "Ready"); color: TuiTheme.barMuted; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.fontSize; font.weight: TuiTheme.fontWeight }
                                Text { anchors.right: parent.right; text: MusicService.ready ? "Navidrome" : "Disconnected"; color: MusicService.ready ? TuiTheme.highlight : TuiTheme.warn; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.fontSize; font.weight: TuiTheme.fontWeight }
                            }

                            Text { width: parent.width; text: MusicService.currentTrack?.title ?? "Nothing playing"; color: TuiTheme.highlight; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.fontSize + 8; font.weight: TuiTheme.fontWeight; elide: Text.ElideRight }
                            Text { width: parent.width; text: MusicService.currentTrack ? [MusicService.currentTrack.artist, MusicService.currentTrack.album].filter(v => v && v.length > 0).join(" - ") : "Choose a playlist, album, artist, song, or favorite"; color: TuiTheme.fg; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.fontSize + 1; font.weight: TuiTheme.fontWeight; elide: Text.ElideRight }

                            Row {
                                width: parent.width
                                height: 18
                                spacing: 14

                                Text { width: 48; text: root.formatTime(MusicService.position); color: TuiTheme.barMuted; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.fontSize; font.weight: TuiTheme.fontWeight }
                                Rectangle {
                                    width: parent.width - 138
                                    height: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: TuiTheme.dim
                                    Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: parent.width * Math.max(0, Math.min(1, MusicService.duration > 0 ? MusicService.position / MusicService.duration : 0)); color: TuiTheme.highlight }
                                }
                                Text { width: 48; text: root.formatTime(MusicService.duration); color: TuiTheme.barMuted; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.fontSize; font.weight: TuiTheme.fontWeight; horizontalAlignment: Text.AlignRight }
                            }

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: 38
                                spacing: 18

                                ControlButton { label: "SHF"; active: MusicService.shuffleEnabled; onClicked: MusicService.toggleShuffle() }
                                ControlButton { label: "<<"; onClicked: MusicService.previous() }
                                ControlButton { label: MusicService.playing ? "II" : ">"; active: true; onClicked: MusicService.togglePause() }
                                ControlButton { label: ">>"; onClicked: MusicService.next() }
                                ControlButton { label: "FAV"; active: MusicService.currentTrackFavorite; onClicked: MusicService.toggleCurrentFavorite() }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 34
                        color: "transparent"
                        border.color: TuiTheme.dim
                        border.width: 1

                        Row { anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter; spacing: 28
                            Text { text: "ctrl+h/l navigate"; color: TuiTheme.fg; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.fontSize; font.weight: TuiTheme.fontWeight }
                            Text { text: "enter play"; color: TuiTheme.fg; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.fontSize; font.weight: TuiTheme.fontWeight }
                            Text { text: "ctrl+space pause"; color: TuiTheme.fg; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.fontSize; font.weight: TuiTheme.fontWeight }
                            Text { text: "esc close"; color: TuiTheme.fg; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.fontSize; font.weight: TuiTheme.fontWeight }
                        }

                        Text { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; text: root.currentItems().length + " ITEMS"; color: TuiTheme.barMuted; font.family: TuiTheme.fontFamily; font.pixelSize: TuiTheme.fontSize; font.weight: TuiTheme.fontWeight }
                    }
                }
            }
        }
    }
}
