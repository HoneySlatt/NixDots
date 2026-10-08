import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "services" as Services
import "m3" as M3

Item {
    id: launcherScope

    property var wallpapers: []
    property string lastTheme: ""
    property bool lastNsfw: false
    property bool wallpaperThumbnailsReady: false
    readonly property string thumbnailDir: Quickshell.env("HOME") + "/.cache/amane/wallpaper-launcher/" + Theme.currentTheme

    function filenameFromPath(fullPath) {
        return fullPath.split("/").pop();
    }

    function thumbnailPath(fullPath) {
        return "file://" + thumbnailDir + "/" + filenameFromPath(fullPath) + ".jpg";
    }

    function doScan() {
        if (wallpapers.length > 0 && Theme.currentTheme === lastTheme && Theme.nsfwEnabled === lastNsfw) return;
        lastTheme = Theme.currentTheme;
        lastNsfw = Theme.nsfwEnabled;
        wallpaperThumbnailsReady = false;
        const dir = Theme.wallpaperDir;
        findProc.command = ["find", dir, "-type", "f",
            "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", "-o", "-iname", "*.webp", ")"];
        findProc.running = true;
    }

    function forceRescan() {
        wallpapers = [];
        lastTheme = "";
        lastNsfw = false;
        wallpaperThumbnailsReady = false;
        doScan();
    }

    function applyWallpaper(path) {
        applyProc.command = ["awww", "img", path, "--transition-type", "wave", "--transition-duration", "2"];
        applyProc.running = true;
    }

    Process {
        id: findProc
        running: false
        property string buffer: ""
        command: ["true"]
        stdout: SplitParser {
            onRead: data => findProc.buffer += data + "\n"
        }
        onExited: {
            let lines = findProc.buffer.trim().split("\n").filter(l => l.length > 0);
            findProc.buffer = "";
            if (Theme.nsfwEnabled) {
                lines = lines.filter(l => l.includes("[NSFW]"));
            } else {
                lines = lines.filter(l => !l.includes("[NSFW]"));
            }
            launcherScope.wallpapers = lines;
            thumbProc.running = true;
        }
    }

    Process {
        id: thumbProc
        command: ["bash", "-c",
            "src=$1; cache=$2; nsfw=$3; mkdir -p \"$cache\" 2>/dev/null; find \"$src\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) -print0 | while IFS= read -r -d '' f; do base=${f##*/}; if [ \"$nsfw\" = true ]; then case \"$base\" in *[[]NSFW[]]*) ;; *) continue;; esac; else case \"$base\" in *[[]NSFW[]]*) continue;; esac; fi; out=\"$cache/$base.jpg\"; [ -s \"$out\" ] && continue; magick \"$f\" -auto-orient -thumbnail '1280x720^' -gravity center -extent 1280x720 -quality 90 \"$out\" 2>/dev/null; done",
            "thumbgen", Theme.wallpaperDir, launcherScope.thumbnailDir, Theme.nsfwEnabled ? "true" : "false"
        ]
        running: false
        onExited: launcherScope.wallpaperThumbnailsReady = true
    }

    Process {
        id: applyProc
        running: false
        command: []
        onExited: WallpaperLauncherState.close()
    }

    Connections {
        target: Theme
        function onCurrentThemeChanged() {
            if (WallpaperLauncherState.visible) launcherScope.forceRescan();
        }
        function onNsfwEnabledChanged() {
            if (WallpaperLauncherState.visible) launcherScope.forceRescan();
        }
    }


    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root

            required property var modelData
            screen: modelData
            visible: WallpaperLauncherState.visible && monitorIsFocused

            readonly property bool monitorIsFocused: Services.Compositor.focusedOutput === root.screen.name
            onMonitorIsFocusedChanged: if (!monitorIsFocused) WallpaperLauncherState.close()
            

            color: "transparent"

            WlrLayershell.namespace: "quickshell:wallpaperlauncher"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore

            anchors { top: true; bottom: true; left: true; right: true }

            property int selectedIndex: 0
            function currentWallpaper() {
                if (launcherScope.wallpapers.length === 0) return "";
                return launcherScope.wallpapers[selectedIndex];
            }

            function centerThumbnails() {
                if (launcherScope.wallpapers.length > 0)
                    thumbList.positionViewAtIndex(selectedIndex, ListView.Center);
            }

            function selectMiddle() {
                if (launcherScope.wallpapers.length > 0) {
                    selectedIndex = Math.floor(launcherScope.wallpapers.length / 2);
                    Qt.callLater(centerThumbnails);
                } else {
                    selectedIndex = 0;
                }
            }

            function shuffleSelection() {
                if (launcherScope.wallpapers.length === 0) return;
                selectedIndex = Math.floor(Math.random() * launcherScope.wallpapers.length);
                centerThumbnails();
            }

            onVisibleChanged: {
                if (visible) {
                    launcherScope.doScan();
                    selectMiddle();
                    focusTimer.start();
                }
            }

            onSelectedIndexChanged: centerThumbnails()

            Connections {
                target: launcherScope
                function onWallpapersChanged() {
                    if (WallpaperLauncherState.visible) root.selectMiddle();
                }
            }

            Timer {
                id: focusTimer
                interval: 80
                repeat: false
                onTriggered: panel.forceActiveFocus()
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.scrim
            }

            MouseArea {
                anchors.fill: parent
                onClicked: WallpaperLauncherState.close()
            }

            M3.Surface {
                id: panel
                anchors.centerIn: parent
                width: Math.min(parent.width - 80, 1180)
                height: Math.min(parent.height - 72, 790)
                radius: Theme.shapeXLI
                growFrom: "center"
                focus: WallpaperLauncherState.visible

                MouseArea { anchors.fill: parent; onClicked: panel.forceActiveFocus() }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        WallpaperLauncherState.close();
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (root.currentWallpaper() !== "") launcherScope.applyWallpaper(root.currentWallpaper());
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_H || event.key === Qt.Key_Left) {
                        if (root.selectedIndex > 0) root.selectedIndex--;
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_L || event.key === Qt.Key_Right) {
                        if (root.selectedIndex < launcherScope.wallpapers.length - 1) root.selectedIndex++;
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_S) {
                        root.shuffleSelection();
                        event.accepted = true;
                    }
                }

                Rectangle {
                    id: previewFrame
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 16
                    height: Math.max(260, parent.height - 16 - 24 - 96 - 16 - 56 - 20)
                    radius: Theme.shapeXL
                    color: Theme.surfaceContainerHighest

                    M3.RoundedImage {
                        anchors.fill: parent
                        radius: parent.radius
                        source: root.currentWallpaper() !== "" && launcherScope.wallpaperThumbnailsReady
                            ? launcherScope.thumbnailPath(root.currentWallpaper())
                            : ""
                        cache: true
                        sourceSize: Qt.size(1280, 720)
                    }

                    M3.Label {
                        anchors.centerIn: parent
                        visible: launcherScope.wallpapers.length === 0
                        text: "No wallpapers found"
                        color: Theme.textOnSurfaceVariant
                        font.pixelSize: Theme.typeTitle
                    }
                }

                Row {
                    id: thumbnailStrip
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: previewFrame.bottom
                    anchors.topMargin: 24
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    height: 96
                    spacing: 12

                    M3.IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 48
                        variant: "tonal"
                        icon: "chevron_left"
                        onClicked: if (root.selectedIndex > 0) root.selectedIndex--
                    }

                    ListView {
                        id: thumbList
                        width: parent.width - 2 * 48 - 2 * parent.spacing
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter
                        orientation: ListView.Horizontal
                        model: launcherScope.wallpapers
                        currentIndex: root.selectedIndex
                        spacing: 10
                        clip: true
                        highlight: Item {}
                        highlightFollowsCurrentItem: true
                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Center)

                        delegate: Item {
                            id: thumbCard

                            required property string modelData
                            required property int index

                            width: 156
                            height: 96
                            property bool isSelected: index === root.selectedIndex

                            Rectangle {
                                id: thumbFrame
                                anchors.centerIn: parent
                                width: thumbCard.isSelected ? 156 : 148
                                height: thumbCard.isSelected ? 92 : 84
                                radius: thumbCard.isSelected ? Theme.shapeXL : Theme.shapeM
                                color: Theme.surfaceContainerHighest

                                Behavior on radius { M3.Spring {} }
                                Behavior on width { M3.Spring {} }
                                Behavior on height { M3.Spring {} }

                                M3.RoundedImage {
                                    anchors.fill: parent
                                    radius: thumbFrame.radius
                                    source: launcherScope.wallpaperThumbnailsReady
                                        ? launcherScope.thumbnailPath(thumbCard.modelData)
                                        : "file://" + thumbCard.modelData
                                    cache: true
                                    sourceSize: Qt.size(360, 240)
                                }

                                M3.StateLayer {
                                    hovered: thumbMouse.containsMouse
                                    pressed: thumbMouse.pressed
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: "transparent"
                                    border.width: thumbCard.isSelected ? 3 : 0
                                    border.color: Theme.primary
                                }

                                Rectangle {
                                    visible: thumbCard.isSelected
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 8
                                    width: 26
                                    height: 26
                                    radius: 13
                                    color: Theme.primary

                                    M3.Icon {
                                        anchors.centerIn: parent
                                        icon: "check"
                                        size: 16
                                        color: Theme.textOnPrimary
                                    }
                                }
                            }

                            MouseArea {
                                id: thumbMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (thumbCard.isSelected) launcherScope.applyWallpaper(thumbCard.modelData);
                                    else root.selectedIndex = thumbCard.index;
                                }
                            }
                        }
                    }

                    M3.IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 48
                        variant: "tonal"
                        icon: "chevron_right"
                        onClicked: if (root.selectedIndex < launcherScope.wallpapers.length - 1) root.selectedIndex++
                    }
                }

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 28
                    anchors.rightMargin: 20
                    anchors.bottomMargin: 20
                    height: 56
                    spacing: 8

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        M3.Label {
                            Layout.fillWidth: true
                            text: "Wallpapers"
                            font.pixelSize: Theme.typeTitle
                            font.weight: Font.Bold
                        }

                        M3.Label {
                            text: launcherScope.wallpapers.length > 0 ? (root.selectedIndex + 1) + " / " + launcherScope.wallpapers.length + "  •  " + Theme.themes[Theme.currentTheme].name : Theme.themes[Theme.currentTheme].name
                            color: Theme.textOnSurfaceVariant
                            font.pixelSize: Theme.typeLabel
                        }
                    }

                    M3.Button {
                        size: 56
                        variant: "tonal"
                        icon: "shuffle"
                        text: "Shuffle"
                        onClicked: root.shuffleSelection()
                    }

                    M3.Button {
                        size: 56
                        variant: "filled"
                        icon: "check"
                        text: "Apply"
                        onClicked: if (root.currentWallpaper() !== "") launcherScope.applyWallpaper(root.currentWallpaper())
                    }
                }
            }
        }
    }
}
