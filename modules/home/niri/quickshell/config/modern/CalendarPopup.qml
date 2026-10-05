import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "services" as Services
import Quickshell.Io
import Quickshell.Services.Mpris
import "m3" as M3

Item {
    id: calendarPopup

    property date now: new Date()
    property color coverAccentColor: Theme.primary
    property var cavaValues: []
    property var wallpaperList: []
    property int wallpaperPage: 0
    readonly property string wallpaperThumbnailDir: "/home/honey/.cache/quickshell/wallpapers/" + Theme.currentTheme
    readonly property int wallpapersPerPage: 12
    readonly property int wallpaperTotalPages: Math.max(1, Math.ceil(wallpaperList.length / wallpapersPerPage))
    property string selectedWallpaper: ""
    property bool wallpaperThumbnailsReady: false
    property string uptimeText: ""
    property string hostname: "System"
    property real currentPosition: player ? player.position : 0

    Process {
        id: hostnameProc
        command: ["hostname"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const h = this.text.trim();
                if (h.length > 0) calendarPopup.hostname = h;
            }
        }
    }

    Component.onCompleted: hostnameProc.running = true

    readonly property MprisPlayer player: {
        const players = Mpris.players.values;
        if (players.length === 0) return null;
        const playing = players.find(p => p.playbackState === MprisPlaybackState.Playing);
        return playing ?? players[0];
    }

    readonly property real trackLength: {
        if (!player) return 0;
        const length = player.length;
        if (isNaN(length) || length < 0) return 0;
        return length > 86400 ? length / 1000000 : length;
    }

    readonly property var tabItems: [
        { label: "Media", icon: "\u{f075a}", idx: 1 },
        { label: "Walls", icon: "\u{f0e09}", idx: 2 },
        { label: "Themes", icon: "\u{f03d8}", idx: 3 }
    ]

    function formatTime(seconds) {
        if (isNaN(seconds) || seconds < 0 || seconds > 86400) return "--:--";
        const minutes = Math.floor(seconds / 60);
        const remaining = Math.floor(seconds % 60);
        return minutes + ":" + (remaining < 10 ? "0" : "") + remaining;
    }

    function resetWallpaperScan() {
        wallpaperList = [];
        wallpaperPage = 0;
        selectedWallpaper = "";
        wallpaperThumbnailsReady = false;
        if (CalendarPopupState.visible && CalendarPopupState.activeTab === 2)
            wallpaperScanProc.running = true;
    }

    function wallpaperThumbnailPath(filename) {
        return wallpaperThumbnailDir + "/" + filename + ".jpg";
    }

    function applyWallpaper(filename) {
        selectedWallpaper = filename;
        wallpaperApplyProc.wallpaperPath = Theme.wallpaperDir + "/" + filename;
        wallpaperApplyProc.running = true;
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: calendarPopup.now = new Date()
    }

    Process {
        id: wallpaperScanProc
        command: ["find", Theme.wallpaperDir, "-type", "f", "(", "-iname", "*.jpg", "-o", "-iname", "*.png", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.webp", ")", "-printf", "%f\n"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let files = this.text.trim().split("\n").filter(f => f.length > 0);
                files = Theme.nsfwEnabled ? files.filter(f => f.includes("[NSFW]")) : files.filter(f => !f.includes("[NSFW]"));
                files.sort();
                calendarPopup.wallpaperList = files;
                calendarPopup.wallpaperThumbnailsReady = false;
                wallpaperThumbProc.running = true;
            }
        }
    }

    Process {
        id: wallpaperThumbProc
        command: [
            "bash", "-c",
            "src=$1; cache=$2; nsfw=$3; mkdir -p \"$cache\" || exit 0; find \"$src\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) -print0 | while IFS= read -r -d '' f; do base=${f##*/}; if [ \"$nsfw\" = true ]; then case \"$base\" in *[[]NSFW[]]*) ;; *) continue;; esac; else case \"$base\" in *[[]NSFW[]]*) continue;; esac; fi; out=\"$cache/$base.jpg\"; [ -s \"$out\" ] && continue; magick \"$f\" -auto-orient -thumbnail '360x240^' -gravity center -extent 360x240 -quality 82 \"$out\" 2>/dev/null; done",
            "thumbgen", Theme.wallpaperDir, calendarPopup.wallpaperThumbnailDir, Theme.nsfwEnabled ? "true" : "false"
        ]
        running: false
        onExited: calendarPopup.wallpaperThumbnailsReady = true
    }

    Process {
        id: wallpaperApplyProc
        property string wallpaperPath: ""
        command: ["awww", "img", wallpaperPath, "--transition-type", "wave", "--transition-duration", "2"]
        running: false
    }

    Process {
        id: uptimeProc
        command: ["/bin/sh", "-c", "awk '{s=int($1); printf \"%dh %dm\\n\", s/3600, (s%3600)/60}' /proc/uptime"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = this.text.trim();
                if (raw.length > 0) calendarPopup.uptimeText = raw;
            }
        }
    }

    Timer {
        interval: 60000
        running: CalendarPopupState.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: uptimeProc.running = true
    }

    Timer {
        interval: 1000
        running: CalendarPopupState.visible && calendarPopup.player !== null && calendarPopup.player.playbackState === MprisPlaybackState.Playing
        repeat: true
        onTriggered: {
            if (calendarPopup.player) calendarPopup.currentPosition = calendarPopup.player.position;
        }
    }

    Process {
        command: ["bash", "-c", "cava -p <(printf '[general]\\nbars = 32\\nframerate = 30\\n\\n[output]\\nmethod = raw\\nraw_target = /dev/stdout\\ndata_format = ascii\\nascii_max_range = 20\\n')"]
        running: CalendarPopupState.visible && CalendarPopupState.activeTab === 1
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                const trimmed = data.trim();
                if (trimmed.length > 0) calendarPopup.cavaValues = trimmed.split(";").map(v => parseInt(v) || 0);
            }
        }
        onRunningChanged: {
            if (!running) calendarPopup.cavaValues = [];
        }
    }

    Connections {
        target: Theme
        function onCurrentThemeChanged() { calendarPopup.resetWallpaperScan(); }
        function onNsfwEnabledChanged() { calendarPopup.resetWallpaperScan(); }
    }

    Connections {
        target: CalendarPopupState
        function onVisibleChanged() {
            if (CalendarPopupState.visible && calendarPopup.wallpaperList.length === 0)
                wallpaperScanProc.running = true;
        }
        function onActiveTabChanged() {
            if (CalendarPopupState.visible && CalendarPopupState.activeTab === 2 && calendarPopup.wallpaperList.length === 0)
                wallpaperScanProc.running = true;
        }
    }

    component Card: Rectangle {
        radius: Theme.shapeXL
        color: Theme.surfaceContainerHigh

        Behavior on color { M3.ColorEffect {} }
    }

    component RoundImage: Item {
        id: roundImage

        property string source: ""
        property string fallbackIcon: "\u{f075a}"
        property color backgroundColor: Theme.surfaceContainerHighest

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: roundImage.backgroundColor
        }

        M3.RoundedImage {
            anchors.fill: parent
            radius: width / 2
            source: roundImage.source
            sourceSize: Qt.size(width * 2, height * 2)
        }

        M3.Icon {
            anchors.centerIn: parent
            visible: roundImage.source === ""
            icon: roundImage.fallbackIcon
            size: Math.min(parent.width, parent.height) * 0.4
            color: Theme.textOnSurfaceVariant
        }
    }

    component StatBar: Column {
        id: statBar

        property string icon: ""
        property string label: ""
        property real value: 0
        property color accentColor: Theme.primary

        width: 36
        spacing: 10

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 16
            height: 200
            radius: 8
            color: Theme.alpha(Theme.secondary, 0.22)

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: Math.max(parent.width, parent.height * Math.max(0, Math.min(1, statBar.value)))
                radius: parent.radius
                color: statBar.accentColor

                Behavior on height { M3.Spring {} }
                Behavior on color { M3.ColorEffect {} }
            }
        }

        M3.Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            icon: statBar.icon
            size: 18
            color: Theme.textOnSurfaceVariant
        }

        M3.Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: statBar.label
            font.pixelSize: Theme.typeLabel
            font.weight: Font.Bold
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root

            required property var modelData
            screen: modelData
            visible: CalendarPopupState.visible && monitorIsFocused

            readonly property bool monitorIsFocused: Services.NiriData.activeWorkspace !== null && Services.NiriData.activeWorkspace.output === root.screen.name
            onMonitorIsFocusedChanged: if (!monitorIsFocused) CalendarPopupState.close()


            color: "transparent"
            WlrLayershell.namespace: "quickshell:calendarpopup"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            anchors { top: true; bottom: true; left: true; right: true }

            MouseArea {
                anchors.fill: parent
                onClicked: CalendarPopupState.close()
            }

            FocusScope {
                anchors.fill: parent
                focus: CalendarPopupState.visible
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        CalendarPopupState.close();
                        event.accepted = true;
                    }
                }

                M3.Surface {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: BarState.isTop ? parent.top : undefined
                    anchors.bottom: BarState.isTop ? undefined : parent.bottom
                    anchors.topMargin: Theme.popupGap
                    width: Math.min(920, parent.width - 48)
                    height: Math.min(540, parent.height - 72)
                    radius: Theme.shapeXLI
                    flushBottom: !BarState.isTop
                    growFrom: BarState.isTop ? "top" : "bottom"

                    MouseArea { anchors.fill: parent }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 16
                        anchors.leftMargin: 8
                        spacing: 12

                        Column {
                            id: rail
                            width: 96
                            height: parent.height
                            topPadding: 4
                            spacing: 14

                            Item {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 80
                                height: 156

                                readonly property bool active: CalendarPopupState.activeTab === 0

                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.active ? Theme.shapeXL : 40
                                    color: parent.active ? Theme.primary : "transparent"

                                    Behavior on radius { M3.Spring {} }
                                    Behavior on color { M3.ColorEffect {} }

                                    M3.StateLayer {
                                        tint: parent.parent.active ? Theme.textOnPrimary : Theme.textOnSurface
                                        hovered: clockMouse.containsMouse
                                        pressed: clockMouse.pressed
                                    }
                                }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: -6

                                    M3.Label {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: Qt.formatDateTime(calendarPopup.now, "HH")
                                        color: parent.parent.active ? Theme.textOnPrimary : Theme.primary
                                        font.pixelSize: Theme.typeDisplay
                                        font.weight: Font.ExtraBold
                                    }

                                    M3.Label {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: Qt.formatDateTime(calendarPopup.now, "mm")
                                        color: parent.parent.active ? Theme.textOnPrimary : Theme.primary
                                        font.pixelSize: Theme.typeDisplay
                                        font.weight: Font.ExtraBold
                                    }

                                    Item { width: 1; height: 10 }

                                    M3.Label {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: Qt.formatDateTime(calendarPopup.now, "ddd dd")
                                        color: parent.parent.active ? Theme.textOnPrimary : Theme.textOnSurfaceVariant
                                        font.pixelSize: Theme.typeLabel
                                        font.weight: Font.Bold
                                    }
                                }

                                MouseArea {
                                    id: clockMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: CalendarPopupState.activeTab = 0
                                }
                            }

                            Item { width: 1; height: 6 }

                            Repeater {
                                model: calendarPopup.tabItems
                                delegate: M3.NavItem {
                                    required property var modelData
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    icon: modelData.icon
                                    label: modelData.label
                                    active: CalendarPopupState.activeTab === modelData.idx
                                    onClicked: CalendarPopupState.activeTab = modelData.idx
                                }
                            }
                        }

                        Column {
                            width: parent.width - rail.width - parent.spacing
                            height: parent.height
                            spacing: 12

                            RowLayout {
                                visible: CalendarPopupState.activeTab === 0
                                width: parent.width
                                height: visible ? 88 : 0
                                spacing: 12

                                Card {
                                    Layout.preferredWidth: 270
                                    Layout.fillHeight: true

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 20
                                        spacing: 14

                                        M3.PolarShape {
                                            Layout.preferredWidth: 56
                                            Layout.preferredHeight: 56
                                            lobes: 9
                                            depth: 0.07
                                            color: Theme.tertiaryContainer

                                            M3.Icon {
                                                anchors.centerIn: parent
                                                icon: WeatherState.icon
                                                size: 26
                                                color: Theme.textOnTertiaryContainer
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 0

                                            M3.Label {
                                                text: WeatherState.temperature
                                                font.pixelSize: Theme.typeHeadline
                                                font.weight: Font.Bold
                                            }

                                            M3.Label {
                                                Layout.fillWidth: true
                                                text: WeatherState.description
                                                color: Theme.textOnSurfaceVariant
                                                font.pixelSize: Theme.typeLabel
                                            }
                                        }
                                    }
                                }

                                Card {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 16
                                        spacing: 14

                                        RoundImage {
                                            Layout.preferredWidth: 56
                                            Layout.preferredHeight: 56
                                            source: "file:///home/honey/Pictures/Others/Honey.png"
                                            fallbackIcon: "\u{f0004}"
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 0

                                            M3.Label {
                                                text: "Honey"
                                                font.pixelSize: Theme.typeTitleL
                                                font.weight: Font.Bold
                                            }

                                            M3.Label {
                                                Layout.fillWidth: true
                                                text: DistroState.icon + " on " + DistroState.wmName + "  •  up " + calendarPopup.uptimeText
                                                color: Theme.textOnSurfaceVariant
                                                font.pixelSize: Theme.typeLabel
                                            }
                                        }

                                        Row {
                                            spacing: 4

                                            M3.IconButton {
                                                anchors.verticalCenter: parent.verticalCenter
                                                icon: "\u{f04ae}"
                                                onClicked: if (calendarPopup.player) calendarPopup.player.previous()
                                            }

                                            M3.IconButton {
                                                anchors.verticalCenter: parent.verticalCenter
                                                size: 48
                                                variant: "filled"
                                                toggle: true
                                                checked: calendarPopup.player !== null && calendarPopup.player.playbackState === MprisPlaybackState.Playing
                                                icon: checked ? "\u{f03e4}" : "\u{f040a}"
                                                onClicked: if (calendarPopup.player) calendarPopup.player.togglePlaying()
                                            }

                                            M3.IconButton {
                                                anchors.verticalCenter: parent.verticalCenter
                                                icon: "\u{f04ad}"
                                                onClicked: if (calendarPopup.player) calendarPopup.player.next()
                                            }
                                        }
                                    }
                                }
                            }

                            Item {
                                width: parent.width
                                height: parent.height - (CalendarPopupState.activeTab === 0 ? 100 : 0)

                                Loader { active: CalendarPopupState.activeTab === 0; anchors.fill: parent; sourceComponent: dashboardPage }
                                Loader { active: CalendarPopupState.activeTab === 1; anchors.fill: parent; sourceComponent: mediaPage }
                                Loader {
                                    active: CalendarPopupState.visible
                                    visible: CalendarPopupState.activeTab === 2
                                    anchors.fill: parent
                                    sourceComponent: wallpapersPage
                                }
                                Loader { active: CalendarPopupState.activeTab === 3; anchors.fill: parent; sourceComponent: themesPage }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: dashboardPage

        RowLayout {
            spacing: 12

            Card {
                id: calendarCard
                Layout.fillWidth: true
                Layout.fillHeight: true

                property int displayMonth: calendarPopup.now.getMonth()
                property int displayYear: calendarPopup.now.getFullYear()
                readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

                function prevMonth() {
                    if (displayMonth === 0) {
                        displayMonth = 11;
                        displayYear--;
                    } else {
                        displayMonth--;
                    }
                }

                function nextMonth() {
                    if (displayMonth === 11) {
                        displayMonth = 0;
                        displayYear++;
                    } else {
                        displayMonth++;
                    }
                }

                function calendarDays() {
                    const days = [];
                    const first = new Date(displayYear, displayMonth, 1);
                    const startDay = first.getDay();
                    const daysInMonth = new Date(displayYear, displayMonth + 1, 0).getDate();
                    const prevMonthDays = new Date(displayYear, displayMonth, 0).getDate();
                    for (let i = startDay - 1; i >= 0; i--) days.push({ day: prevMonthDays - i, current: false });
                    for (let day = 1; day <= daysInMonth; day++) days.push({ day: day, current: true });
                    const rowsNeeded = Math.max(5, Math.ceil(days.length / 7));
                    for (let next = 1; days.length < rowsNeeded * 7; next++) days.push({ day: next, current: false });
                    return days;
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 18
                    anchors.topMargin: 14
                    spacing: 8

                    RowLayout {
                        width: parent.width
                        height: 40

                        M3.Label {
                            Layout.fillWidth: true
                            leftPadding: 6
                            text: calendarCard.monthNames[calendarCard.displayMonth] + " " + calendarCard.displayYear
                            font.pixelSize: Theme.typeTitleL
                            font.weight: Font.Bold
                        }

                        M3.IconButton {
                            icon: "\u{f0141}"
                            onClicked: calendarCard.prevMonth()
                        }

                        M3.IconButton {
                            icon: "\u{f0142}"
                            onClicked: calendarCard.nextMonth()
                        }
                    }

                    Row {
                        width: parent.width
                        height: 22
                        Repeater {
                            model: ["S", "M", "T", "W", "T", "F", "S"]
                            M3.Label {
                                required property string modelData
                                width: parent.width / 7
                                text: modelData
                                horizontalAlignment: Text.AlignHCenter
                                color: Theme.textOnSurfaceVariant
                                font.pixelSize: Theme.typeLabel
                                font.weight: Font.Bold
                            }
                        }
                    }

                    Grid {
                        id: dayGrid
                        width: parent.width
                        height: parent.height - 78
                        columns: 7
                        spacing: 0
                        readonly property var calDays: calendarCard.calendarDays()
                        readonly property int rowsCount: Math.ceil(calDays.length / 7)
                        readonly property int todayDay: calendarPopup.now.getDate()
                        readonly property int todayMonth: calendarPopup.now.getMonth()
                        readonly property int todayYear: calendarPopup.now.getFullYear()

                        Repeater {
                            model: dayGrid.calDays
                            delegate: Item {
                                required property var modelData
                                width: dayGrid.width / 7
                                height: dayGrid.height / dayGrid.rowsCount
                                readonly property bool isToday: modelData.current && modelData.day === dayGrid.todayDay && calendarCard.displayMonth === dayGrid.todayMonth && calendarCard.displayYear === dayGrid.todayYear

                                M3.PolarShape {
                                    visible: isToday
                                    anchors.centerIn: parent
                                    width: 42
                                    height: 42
                                    lobes: 9
                                    depth: 0.07
                                    color: Theme.primary
                                }

                                Rectangle {
                                    visible: !isToday && modelData.current
                                    anchors.centerIn: parent
                                    width: 38
                                    height: 38
                                    radius: 19
                                    color: Theme.textOnSurface
                                    opacity: dayMouse.containsMouse ? Theme.stateHover : 0

                                    Behavior on opacity { M3.Effect {} }
                                }

                                M3.Label {
                                    anchors.centerIn: parent
                                    text: modelData.day
                                    color: isToday ? Theme.textOnPrimary : modelData.current ? Theme.textOnSurface : Theme.outline
                                    opacity: modelData.current ? 1.0 : 0.6
                                    font.pixelSize: Theme.typeBody + 1
                                    font.weight: isToday ? Font.ExtraBold : Theme.fontWeight
                                }

                                MouseArea {
                                    id: dayMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                }
                            }
                        }
                    }
                }
            }

            Card {
                Layout.preferredWidth: 170
                Layout.fillHeight: true

                Column {
                    anchors.centerIn: parent
                    width: parent.width - 24
                    spacing: 18

                    M3.Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(implicitWidth, parent.width)
                        text: calendarPopup.hostname
                        font.pixelSize: Theme.typeTitle
                        font.weight: Font.Bold
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 10
                        StatBar { icon: "\u{f0ee0}"; label: Math.round(CpuState.usage) + "%"; value: CpuState.usage / 100; accentColor: CpuState.usage >= 90 ? Theme.error : Theme.primary }
                        StatBar { icon: "\u{f050f}"; label: GpuState.tempC + "°"; value: Math.min(GpuState.tempC / 100, 1); accentColor: GpuState.tempC >= 80 ? Theme.error : Theme.tertiary }
                        StatBar { icon: "\u{f035b}"; label: Math.round(RamState.percentage) + "%"; value: RamState.percentage / 100; accentColor: RamState.percentage >= 90 ? Theme.error : Theme.misc }
                    }
                }
            }
        }
    }

    Component {
        id: mediaPage

        Card {
            RowLayout {
                anchors.fill: parent
                anchors.margins: 26
                spacing: 34

                Item {
                    Layout.preferredWidth: 260
                    Layout.preferredHeight: 260
                    Layout.alignment: Qt.AlignVCenter

                    Canvas {
                        width: 8
                        height: 8
                        visible: false
                        property string artUrl: calendarPopup.player ? calendarPopup.player.trackArtUrl : ""
                        onArtUrlChanged: {
                            if (artUrl) {
                                loadImage(artUrl);
                                requestPaint();
                            } else {
                                calendarPopup.coverAccentColor = Theme.primary;
                            }
                        }
                        onImageLoaded: requestPaint()
                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();
                            if (!artUrl || !isImageLoaded(artUrl)) return;
                            ctx.drawImage(artUrl, 0, 0, 8, 8);
                            try {
                                const data = ctx.getImageData(0, 0, 8, 8).data;
                                let r = 0, g = 0, b = 0, n = data.length / 4;
                                for (let i = 0; i < data.length; i += 4) {
                                    r += data[i]; g += data[i + 1]; b += data[i + 2];
                                }
                                calendarPopup.coverAccentColor = Qt.rgba(r / n / 255, g / n / 255, b / n / 255, 1.0);
                            } catch(e) {
                                calendarPopup.coverAccentColor = Theme.primary;
                            }
                        }
                    }

                    Canvas {
                        anchors.fill: parent
                        property var values: calendarPopup.cavaValues
                        property color themeColor: calendarPopup.coverAccentColor
                        onValuesChanged: requestPaint()
                        onThemeColorChanged: requestPaint()
                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();
                            if (!values || values.length === 0) return;
                            const cx = width / 2;
                            const cy = height / 2;
                            const innerR = 96;
                            const n = values.length;
                            const step = 2 * Math.PI / n;
                            ctx.lineCap = "round";
                            ctx.lineWidth = 5;
                            ctx.strokeStyle = themeColor;
                            for (let i = 0; i < n; i++) {
                                const value = Math.min(values[i] / 20.0, 1.0);
                                const barH = value * 30;
                                const angle = (i / n) * 2 * Math.PI - Math.PI / 2;
                                ctx.beginPath();
                                ctx.moveTo(cx + innerR * Math.cos(angle), cy + innerR * Math.sin(angle));
                                ctx.lineTo(cx + (innerR + barH) * Math.cos(angle), cy + (innerR + barH) * Math.sin(angle));
                                ctx.stroke();
                            }
                        }
                    }

                    RoundImage {
                        anchors.centerIn: parent
                        width: 176
                        height: 176
                        source: calendarPopup.player ? calendarPopup.player.trackArtUrl : ""
                    }
                }

                Column {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 16

                    Column {
                        width: parent.width
                        spacing: 4

                        M3.Label {
                            width: parent.width
                            text: calendarPopup.player ? calendarPopup.player.trackTitle : "No media playing"
                            font.pixelSize: Theme.typeHeadline
                            font.weight: Font.Bold
                        }

                        M3.Label {
                            width: parent.width
                            text: calendarPopup.player ? calendarPopup.player.trackArtist : "Start playback in any MPRIS player"
                            color: Theme.textOnSurfaceVariant
                            font.pixelSize: Theme.typeTitle
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 6

                        M3.WavyProgress {
                            width: parent.width
                            value: !calendarPopup.player || calendarPopup.trackLength <= 0 ? 0 : calendarPopup.currentPosition / calendarPopup.trackLength
                            playing: calendarPopup.player !== null && calendarPopup.player.playbackState === MprisPlaybackState.Playing

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => {
                                    if (calendarPopup.player && calendarPopup.player.canSeek)
                                        calendarPopup.player.position = Math.max(0, Math.min(1, (mouse.x - 6) / parent.width)) * calendarPopup.trackLength;
                                }
                            }
                        }

                        RowLayout {
                            width: parent.width
                            M3.Label { text: calendarPopup.formatTime(calendarPopup.currentPosition); color: Theme.textOnSurfaceVariant; font.pixelSize: Theme.typeLabel }
                            Item { Layout.fillWidth: true }
                            M3.Label { text: calendarPopup.formatTime(calendarPopup.trackLength); color: Theme.textOnSurfaceVariant; font.pixelSize: Theme.typeLabel }
                        }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 12

                        M3.IconButton {
                            anchors.verticalCenter: parent.verticalCenter
                            size: 56
                            variant: "tonal"
                            icon: "\u{f04ae}"
                            onClicked: if (calendarPopup.player) calendarPopup.player.previous()
                        }

                        M3.IconButton {
                            anchors.verticalCenter: parent.verticalCenter
                            size: 80
                            implicitWidth: 112
                            variant: "filled"
                            toggle: true
                            checked: calendarPopup.player !== null && calendarPopup.player.playbackState === MprisPlaybackState.Playing
                            icon: checked ? "\u{f03e4}" : "\u{f040a}"
                            onClicked: if (calendarPopup.player) calendarPopup.player.togglePlaying()
                        }

                        M3.IconButton {
                            anchors.verticalCenter: parent.verticalCenter
                            size: 56
                            variant: "tonal"
                            icon: "\u{f04ad}"
                            onClicked: if (calendarPopup.player) calendarPopup.player.next()
                        }
                    }
                }
            }
        }
    }

    Component {
        id: wallpapersPage

        Card {
            Component.onCompleted: {
                if (calendarPopup.wallpaperList.length === 0) wallpaperScanProc.running = true;
            }

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Grid {
                    id: wallpaperGrid
                    columns: 4
                    rows: 3
                    spacing: 8
                    width: parent.width
                    height: parent.height - wallpaperFooter.height - parent.spacing
                    readonly property real cellWidth: (width - (columns - 1) * spacing) / columns
                    readonly property real cellHeight: (height - (rows - 1) * spacing) / rows

                    Repeater {
                        model: {
                            const start = calendarPopup.wallpaperPage * calendarPopup.wallpapersPerPage;
                            const end = Math.min(start + calendarPopup.wallpapersPerPage, calendarPopup.wallpaperList.length);
                            const items = [];
                            for (let i = start; i < end; i++) items.push(calendarPopup.wallpaperList[i]);
                            return items;
                        }

                        delegate: Item {
                            id: wallpaperCell
                            required property string modelData
                            readonly property bool selected: calendarPopup.selectedWallpaper === modelData
                            width: wallpaperGrid.cellWidth
                            height: wallpaperGrid.cellHeight

                            Rectangle {
                                id: wallpaperFrame
                                anchors.fill: parent
                                radius: wallpaperCell.selected ? Theme.shapeXL : wallpaperMouse.containsMouse ? Theme.shapeLI : Theme.shapeM
                                color: Theme.surfaceContainerHighest

                                Behavior on radius { M3.Spring {} }

                                M3.RoundedImage {
                                    anchors.fill: parent
                                    radius: wallpaperFrame.radius
                                    source: calendarPopup.wallpaperThumbnailsReady
                                        ? Qt.resolvedUrl("file://" + calendarPopup.wallpaperThumbnailPath(wallpaperCell.modelData))
                                        : Qt.resolvedUrl("file://" + Theme.wallpaperDir + "/" + wallpaperCell.modelData)
                                    sourceSize: Qt.size(Math.min(wallpaperGrid.cellWidth, 240), Math.min(wallpaperGrid.cellHeight, 160))
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: "transparent"
                                    border.width: wallpaperCell.selected ? 3 : 0
                                    border.color: Theme.primary
                                }
                            }

                            Rectangle {
                                visible: wallpaperCell.selected
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 8
                                width: 28
                                height: 28
                                radius: 14
                                color: Theme.primary

                                M3.Icon {
                                    anchors.centerIn: parent
                                    icon: "\u{f012c}"
                                    size: 16
                                    color: Theme.textOnPrimary
                                }
                            }

                            MouseArea {
                                id: wallpaperMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: calendarPopup.applyWallpaper(wallpaperCell.modelData)
                            }
                        }
                    }
                }

                RowLayout {
                    id: wallpaperFooter
                    width: parent.width
                    height: 40
                    spacing: 8

                    M3.Chip {
                        text: "NSFW"
                        icon: "\u{f0209}"
                        selected: Theme.nsfwEnabled
                        onClicked: Theme.toggleNsfw()
                    }

                    Item { Layout.fillWidth: true }

                    M3.Label {
                        text: calendarPopup.wallpaperList.length + " wallpapers  •  " + (calendarPopup.wallpaperPage + 1) + " / " + calendarPopup.wallpaperTotalPages
                        color: Theme.textOnSurfaceVariant
                        Layout.rightMargin: 4
                    }

                    M3.IconButton {
                        size: 36
                        variant: "tonal"
                        icon: "\u{f0141}"
                        opacity: calendarPopup.wallpaperPage > 0 ? 1 : 0.38
                        onClicked: calendarPopup.wallpaperPage = Math.max(0, calendarPopup.wallpaperPage - 1)
                    }

                    M3.IconButton {
                        size: 36
                        variant: "tonal"
                        icon: "\u{f0142}"
                        opacity: calendarPopup.wallpaperPage < calendarPopup.wallpaperTotalPages - 1 ? 1 : 0.38
                        onClicked: calendarPopup.wallpaperPage = Math.min(calendarPopup.wallpaperTotalPages - 1, calendarPopup.wallpaperPage + 1)
                    }
                }
            }
        }
    }

    Component {
        id: themesPage

        Card {
            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                RowLayout {
                    width: parent.width
                    height: 32
                    M3.Label { leftPadding: 4; text: "Color themes"; font.pixelSize: Theme.typeTitleL; font.weight: Font.Bold }
                    Item { Layout.fillWidth: true }
                    M3.Badge { text: Theme.themes[Theme.currentTheme].name }
                }

                Flickable {
                    id: themeFlick
                    width: parent.width
                    height: parent.height - 46
                    contentWidth: width
                    contentHeight: themeGrid.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Grid {
                        id: themeGrid
                        width: themeFlick.width
                        height: Math.ceil(Theme.themeKeys.length / columns) * cellHeight + Math.max(0, Math.ceil(Theme.themeKeys.length / columns) - 1) * spacing
                        columns: 2
                        spacing: 10
                        readonly property real cellWidth: (width - spacing) / columns
                        readonly property real cellHeight: (themeFlick.height - spacing * 2) / 3

                        Repeater {
                            model: Theme.themeKeys
                            delegate: Rectangle {
                                id: themeCell
                                required property string modelData
                                readonly property var palette: Theme.themes[modelData]
                                readonly property bool active: Theme.currentTheme === modelData
                                width: themeGrid.cellWidth
                                height: themeGrid.cellHeight
                                radius: active ? Theme.shapeXL : Theme.shapeLI
                                color: palette.background
                                border.width: active ? 3 : 0
                                border.color: Theme.primary

                                Behavior on radius { M3.Spring {} }

                                M3.StateLayer {
                                    tint: themeCell.palette.text
                                    hovered: themeMouse.containsMouse
                                    pressed: themeMouse.pressed
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 18
                                    anchors.rightMargin: 18
                                    spacing: 14

                                    M3.PaletteSwatch {
                                        Layout.preferredWidth: 52
                                        Layout.preferredHeight: 52
                                        topColor: themeCell.palette.accent
                                        leftColor: themeCell.palette.process
                                        rightColor: themeCell.palette.misc
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 4

                                        M3.Label {
                                            Layout.fillWidth: true
                                            text: themeCell.palette.name
                                            color: themeCell.palette.text
                                            font.pixelSize: Theme.typeTitle
                                            font.weight: Font.Bold
                                        }

                                        Row {
                                            spacing: 4
                                            Repeater {
                                                model: [themeCell.palette.separator, themeCell.palette.text, themeCell.palette.warning, themeCell.palette.highlight]
                                                delegate: Rectangle { required property var modelData; width: 14; height: 14; radius: 7; color: modelData }
                                            }
                                        }
                                    }

                                    M3.Icon {
                                        visible: themeCell.active
                                        icon: "\u{f05e0}"
                                        size: 24
                                        color: themeCell.palette.accent
                                    }
                                }

                                MouseArea { id: themeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Theme.setTheme(themeCell.modelData) }
                            }
                        }
                    }
                }
            }
        }
    }
}
