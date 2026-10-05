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
            visible: MusicLauncherState.visible && monitorIsFocused

            readonly property bool monitorIsFocused: Services.NiriData.activeWorkspace !== null && Services.NiriData.activeWorkspace.output === root.screen.name
            onMonitorIsFocusedChanged: if (!monitorIsFocused) MusicLauncherState.close()
            

            property int sectionIndex: 0
            property int selectedIndex: 0
            property string searchQuery: ""
            property bool pendingAutoPlayCollection: false

            readonly property var sectionTabs: [
                { label: "Playlists", icon: "\u{f0cb8}" },
                { label: "Albums", icon: "\u{f0025}" },
                { label: "Artists", icon: "\u{f0803}" },
                { label: "Songs", icon: "\u{f0387}" },
                { label: "Favorites", icon: "\u{f02d1}" }
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
                color: Theme.scrim
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

            M3.Surface {
                id: panel
                anchors.centerIn: parent
                width: Math.min(parent.width - 96, 1360)
                height: Math.min(parent.height - 126, 800)
                radius: Theme.shapeXLI
                growFrom: "center"

                MouseArea { anchors.fill: parent; onClicked: keyLayer.forceActiveFocus() }

                M3.SearchField {
                    id: searchField
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 28
                    width: Math.min(parent.width * 0.5, 640)
                    placeholder: "Search music"
                    onTextChanged: {
                        root.searchQuery = text;
                        root.selectedIndex = 0;
                    }
                }

                Row {
                    id: tabs
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: searchField.bottom
                    anchors.topMargin: 20
                    spacing: 2

                    Repeater {
                        id: tabRepeater
                        model: root.sectionTabs

                        M3.Button {
                            required property var modelData
                            required property int index

                            width: 150
                            size: 48
                            variant: "tonal"
                            toggle: true
                            checked: root.sectionIndex === index
                            grouped: true
                            groupStart: index === 0
                            groupEnd: index === tabRepeater.count - 1
                            icon: modelData.icon
                            text: modelData.label
                            onClicked: root.sectionIndex = index
                        }
                    }
                }

                M3.Label {
                    anchors.left: cardList.left
                    anchors.bottom: cardList.top
                    anchors.bottomMargin: 8
                    text: root.currentItems().length + " items"
                    color: Theme.textOnSurfaceVariant
                    font.pixelSize: Theme.typeLabel
                }

                M3.IconButton {
                    anchors.left: parent.left
                    anchors.leftMargin: 40
                    anchors.verticalCenter: cardList.verticalCenter
                    size: 48
                    variant: "tonal"
                    icon: "\u{f0141}"
                    onClicked: root.moveSelection(-1)
                }

                M3.IconButton {
                    anchors.right: parent.right
                    anchors.rightMargin: 40
                    anchors.verticalCenter: cardList.verticalCenter
                    size: 48
                    variant: "tonal"
                    icon: "\u{f0142}"
                    onClicked: root.moveSelection(1)
                }

                ListView {
                    id: cardList
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: tabs.bottom
                    anchors.leftMargin: 112
                    anchors.rightMargin: 112
                    anchors.topMargin: 48
                    height: 262
                    orientation: ListView.Horizontal
                    spacing: 20
                    clip: true
                    model: root.currentItems()
                    currentIndex: root.selectedIndex
                    highlightMoveDuration: 160

                    delegate: Item {
                        id: card
                        required property var modelData
                        required property int index

                        readonly property bool selected: root.selectedIndex === index
                        readonly property string art: root.artFor(modelData)

                        width: selected ? 236 : 184
                        height: cardList.height

                        Behavior on width { M3.Spring {} }

                        Rectangle {
                            id: cardFrame
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: card.selected ? 258 : 214
                            radius: card.selected ? Theme.shapeXL : Theme.shapeLI
                            color: Theme.surfaceContainerHighest

                            Behavior on height { M3.Spring {} }
                            Behavior on radius { M3.Spring {} }

                            M3.Icon {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: -20
                                visible: cardArt.status !== Image.Ready
                                icon: card.modelData.itemType === "artist" ? "\u{f0803}" : "\u{f0387}"
                                size: 56
                                color: Theme.textOnSurfaceVariant
                            }

                            M3.RoundedImage {
                                id: cardArt
                                anchors.fill: parent
                                radius: cardFrame.radius
                                source: card.art
                                sourceSize: Qt.size(520, 520)
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                gradient: Gradient {
                                    GradientStop { position: 0.45; color: Theme.alpha(Theme.surfaceContainerLowest, 0) }
                                    GradientStop { position: 1.0; color: Theme.alpha(Theme.surfaceContainerLowest, 0.92) }
                                }
                            }

                            M3.StateLayer {
                                hovered: cardMouse.containsMouse
                                pressed: cardMouse.pressed
                            }

                            M3.FocusRing {
                                shown: card.selected
                                border.color: Theme.primary
                            }

                            ColumnLayout {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: card.selected ? 20 : 16
                                spacing: 2

                                M3.Label {
                                    Layout.fillWidth: true
                                    text: root.titleFor(card.modelData)
                                    font.pixelSize: card.selected ? Theme.typeTitleL : Theme.typeBody + 1
                                    font.weight: Font.Bold
                                }

                                M3.Label {
                                    Layout.fillWidth: true
                                    text: root.subtitleFor(card.modelData)
                                    color: Theme.textOnSurfaceVariant
                                    font.pixelSize: Theme.typeLabel
                                }
                            }
                        }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: cardFrame
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.playSelected(card.index)
                        }
                    }
                }

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: cardList.bottom
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 112
                    anchors.rightMargin: 112
                    anchors.topMargin: 36
                    anchors.bottomMargin: 28
                    spacing: 36

                    Rectangle {
                        Layout.preferredWidth: 184
                        Layout.preferredHeight: 184
                        radius: Theme.shapeXL
                        color: Theme.surfaceContainerHighest

                        M3.Icon {
                            anchors.centerIn: parent
                            visible: nowCover.status !== Image.Ready
                            icon: "\u{f075a}"
                            size: 64
                            color: Theme.textOnSurfaceVariant
                        }

                        M3.RoundedImage {
                            id: nowCover
                            anchors.fill: parent
                            radius: parent.radius
                            source: MusicService.currentTrack ? MusicService.coverUrl(MusicService.currentTrack.coverArt ?? MusicService.currentTrack.id) : ""
                            sourceSize: Qt.size(540, 540)
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            M3.Label {
                                Layout.fillWidth: true
                                text: MusicService.currentTrack ? "Now playing" : (root.pendingAutoPlayCollection ? "Loading collection" : "Ready")
                                color: Theme.primary
                                font.pixelSize: Theme.typeLabel
                                font.weight: Font.Bold
                            }

                            M3.Chip {
                                clickable: false
                                selected: MusicService.ready
                                icon: "\u{f0156}"
                                text: MusicService.ready ? "Navidrome" : "Disconnected"
                            }
                        }

                        M3.Label {
                            Layout.fillWidth: true
                            text: MusicService.currentTrack?.title ?? "Nothing playing"
                            font.pixelSize: Theme.typeHeadline + 6
                            font.weight: Font.ExtraBold
                        }

                        M3.Label {
                            Layout.fillWidth: true
                            text: MusicService.currentTrack ? [MusicService.currentTrack.artist, MusicService.currentTrack.album].filter(v => v && v.length > 0).join(" - ") : "Choose a playlist, album, artist, song, or favorite"
                            color: Theme.textOnSurfaceVariant
                            font.pixelSize: Theme.typeTitle
                        }

                        Item { Layout.fillHeight: true }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 16

                            M3.Label {
                                text: root.formatTime(MusicService.position)
                                color: Theme.textOnSurfaceVariant
                                font.pixelSize: Theme.typeLabel
                            }

                            M3.WavyProgress {
                                Layout.fillWidth: true
                                value: MusicService.duration > 0 ? MusicService.position / MusicService.duration : 0
                                playing: MusicService.playing
                            }

                            M3.Label {
                                text: root.formatTime(MusicService.duration)
                                color: Theme.textOnSurfaceVariant
                                font.pixelSize: Theme.typeLabel
                            }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 6
                            spacing: 10

                            M3.IconButton { size: 48; variant: "tonal"; toggle: true; checked: MusicService.shuffleEnabled; icon: "\u{f049d}"; onClicked: MusicService.toggleShuffle() }
                            M3.IconButton { size: 56; variant: "tonal"; icon: "\u{f04ae}"; onClicked: MusicService.previous() }
                            M3.IconButton { size: 72; implicitWidth: 104; variant: "filled"; toggle: true; checked: MusicService.playing; icon: MusicService.playing ? "\u{f03e4}" : "\u{f040a}"; onClicked: MusicService.togglePause() }
                            M3.IconButton { size: 56; variant: "tonal"; icon: "\u{f04ad}"; onClicked: MusicService.next() }
                            M3.IconButton { size: 48; variant: "tonal"; toggle: true; checked: MusicService.currentTrackFavorite; icon: MusicService.currentTrackFavorite ? "\u{f02d1}" : "\u{f02d5}"; onClicked: MusicService.toggleCurrentFavorite() }
                        }
                    }
                }
            }
        }
    }
}
