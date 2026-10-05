pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    // ── Theme switching ──
    property string currentTheme: "pastelglow"
    property int _themeRequestSequence: 0

    readonly property var themes: ({
        "carbonfox": {
            name: "Carbonfox",
            background: "#161616",
            text: "#f2f4f8",
            separator: "#2a2a2a",
            warning: "#ff0000",
            caution: "#525253",
            misc: "#808080",
            process: "#a0a0a0",
            accent: "#3a3a3a",
            highlight: "#c6c6c6"
        },
        "everforest": {
            name: "Everforest Dark",
            background: "#2d353b",
            text: "#d3c6aa",
            separator: "#343f44",
            warning: "#e67e80",
            caution: "#3d484d",
            misc: "#83c092",
            process: "#7fbbb3",
            accent: "#a7c080",
            highlight: "#dbbc7f"
        },
        "rosepine": {
            name: "Ros\u00e9 Pine",
            background: "#191724",
            text: "#e0def4",
            separator: "#26233a",
            warning: "#eb6f92",
            caution: "#403d52",
            misc: "#31748f",
            process: "#9ccfd8",
            accent: "#c4a7e7",
            highlight: "#c4a7e7"
        },
        "pastelglow": {
            name: "Pastel Glow",
            background: "#F8E9EE",
            text: "#3B2730",
            separator: "#E2C2CB",
            warning: "#E0486B",
            caution: "#8B6F79",
            misc: "#63C7C8",
            process: "#6D8CE3",
            accent: "#B86EE6",
            highlight: "#E0486B"
        },
        "gruvbox": {
            name: "Gruvbox Dark",
            background: "#282828",
            text: "#ebdbb2",
            separator: "#3c3836",
            warning: "#fb4934",
            caution: "#504945",
            misc: "#8ec07c",
            process: "#83a598",
            accent: "#d3869b",
            highlight: "#fabd2f"
        },
        "gruvbox-light": {
            name: "Gruvbox Light",
            background: "#fbf1c7",
            text: "#3c3836",
            separator: "#ebdbb2",
            warning: "#cc241d",
            caution: "#d5c4a1",
            misc: "#689d6a",
            process: "#458588",
            accent: "#b16286",
            highlight: "#d79921"
        }
    })

    readonly property var _current: themes[currentTheme] || themes["pastelglow"]

    // ── Colors (reactive) ──
    readonly property color background: _current.background
    readonly property color text: _current.text
    readonly property color separator: _current.separator
    readonly property color warning: _current.warning
    readonly property color caution: _current.caution
    readonly property color misc: _current.misc
    readonly property color process: _current.process
    readonly property color accent: _current.accent
    readonly property color highlight: _current.highlight

    // ── Derived UI tokens ──
    readonly property color panel: Qt.tint(background, Qt.rgba(text.r, text.g, text.b, 0.045))
    readonly property color card: Qt.tint(background, Qt.rgba(text.r, text.g, text.b, 0.075))
    readonly property color cardHover: Qt.tint(background, Qt.rgba(text.r, text.g, text.b, 0.115))
    readonly property color muted: Qt.tint(text, Qt.rgba(background.r, background.g, background.b, 0.42))
    readonly property color subtle: Qt.tint(separator, Qt.rgba(background.r, background.g, background.b, 0.35))
    readonly property color glow: Qt.rgba(accent.r, accent.g, accent.b, 0.35)

    // ── Material 3 color roles, derived from the active theme ──
    readonly property color _black: "#000000"
    readonly property color _white: "#ffffff"

    function _clamp(v) {
        return Math.max(0, Math.min(1, v));
    }

    function mix(a, b, t) {
        return Qt.rgba(_clamp(a.r + (b.r - a.r) * t), _clamp(a.g + (b.g - a.g) * t), _clamp(a.b + (b.b - a.b) * t), 1);
    }

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    function luminance(c) {
        const lin = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
        return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
    }

    function contrast(a, b) {
        const la = luminance(a);
        const lb = luminance(b);
        return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
    }

    // Readable content color on top of any container
    function contentOn(c) {
        const dark = mix(c, _black, 0.74);
        const light = mix(c, _white, 0.94);
        return contrast(dark, c) >= contrast(light, c) ? dark : light;
    }

    function _container(c) {
        return mix(background, c, isDark ? 0.32 : 0.22);
    }

    function _onContainer(c) {
        return isDark ? mix(c, _white, 0.58) : mix(c, _black, 0.6);
    }

    function _desaturate(c) {
        return c.hslHue < 0 ? c : Qt.hsla(c.hslHue, c.hslSaturation * 0.4, c.hslLightness, 1);
    }

    readonly property bool isDark: luminance(background) < 0.4

    readonly property color primary: contrast(accent, background) >= 1.8 ? accent : highlight
    readonly property color textOnPrimary: contentOn(primary)
    readonly property color primaryContainer: _container(primary)
    readonly property color textOnPrimaryContainer: _onContainer(primary)

    readonly property color secondary: _desaturate(primary)
    readonly property color textOnSecondary: contentOn(secondary)
    readonly property color secondaryContainer: _container(secondary)
    readonly property color textOnSecondaryContainer: _onContainer(secondary)

    readonly property color tertiary: contrast(process, background) >= 1.8 ? process : misc
    readonly property color textOnTertiary: contentOn(tertiary)
    readonly property color tertiaryContainer: _container(tertiary)
    readonly property color textOnTertiaryContainer: _onContainer(tertiary)

    readonly property color error: warning
    readonly property color textOnError: contentOn(error)
    readonly property color errorContainer: _container(error)
    readonly property color textOnErrorContainer: _onContainer(error)

    readonly property color surface: background
    readonly property color surfaceContainerLowest: isDark ? mix(background, _black, 0.3) : mix(background, _white, 0.6)
    // Popups share the bar color; raised elements step towards the theme separator
    readonly property color surfaceContainerLow: background
    readonly property color surfaceContainer: background
    readonly property color surfaceContainerHigh: mix(background, separator, 0.65)
    readonly property color surfaceContainerHighest: mix(background, separator, 1.3)
    readonly property color textOnSurface: text
    readonly property color textOnSurfaceVariant: mix(text, background, 0.3)
    readonly property color outline: mix(text, background, 0.52)
    readonly property color outlineVariant: mix(text, background, 0.8)
    readonly property color inverseSurface: text
    readonly property color inverseOnSurface: background
    readonly property color scrim: Qt.rgba(0, 0, 0, 0.4)
    readonly property color shadow: Qt.rgba(0, 0, 0, isDark ? 0.45 : 0.22)

    // State layer opacities
    readonly property real stateHover: 0.08
    readonly property real statePressed: 0.12

    // ── Material 3 shape scale ──
    readonly property int shapeXS: 4
    readonly property int shapeS: 8
    readonly property int shapeM: 12
    readonly property int shapeL: 16
    readonly property int shapeLI: 20
    readonly property int shapeXL: 28
    readonly property int shapeXLI: 32
    readonly property int shapeXXL: 48
    readonly property int popupGap: margin

    // ── Material 3 type scale ──
    readonly property int typeDisplay: 44
    readonly property int typeHeadline: 26
    readonly property int typeTitleL: 20
    readonly property int typeTitle: 15
    readonly property int typeBody: 13
    readonly property int typeLabel: 12
    readonly property int typeLabelS: 11

    // ── Material 3 Expressive motion (spring approximations) ──
    readonly property list<real> springFast: [0.42, 1.67, 0.21, 0.90, 1, 1]
    readonly property list<real> springDefault: [0.38, 1.21, 0.22, 1.00, 1, 1]
    readonly property list<real> springSlow: [0.39, 1.29, 0.35, 0.98, 1, 1]
    readonly property list<real> effects: [0.34, 0.80, 0.34, 1.00, 1, 1]
    readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property int springFastDuration: 350
    readonly property int springDefaultDuration: 500
    readonly property int springSlowDuration: 650
    readonly property int effectsDuration: 200

    readonly property var themeKeys: ["carbonfox", "everforest", "rosepine", "pastelglow", "gruvbox", "gruvbox-light"]

    // ── Wallpaper directories ──
    readonly property var wallpaperDirs: ({
        "pastelglow": "PastelGlow",
        "rosepine": "RosePine",
        "everforest": "Everforest",
        "carbonfox": "Carbonfox",
        "gruvbox": "GruvboxDark",
        "gruvbox-light": "GruvboxLight"
    })
    readonly property string wallpaperDir: "/home/honey/Pictures/Wallpapers/" + (wallpaperDirs[currentTheme] || "PastelGlow")

    // ── Font settings ──
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13
    readonly property int fontWeight: Font.DemiBold

    // ── Dimensions ──
    readonly property int barHeight: 30
    readonly property int margin: 6
    readonly property real barOpacity: 0.9
    readonly property real popupOpacity: 0.955
    readonly property int borderRadius: 12
    readonly property int modulePadding: 8

    // ── Persistence ──
    readonly property string _themeFile: "/home/honey/.config/quickshell/.current-theme"
    readonly property string _nsfwFile: "/home/honey/.config/quickshell/.nsfw-enabled"

    property bool nsfwEnabled: false

    readonly property var _reader: Process {
        command: ["cat", _themeFile]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let key = data.trim();
                if (themes.hasOwnProperty(key)) currentTheme = key;
            }
        }
    }

    readonly property var _nsfwReader: Process {
        command: ["cat", _nsfwFile]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let val = data.trim();
                nsfwEnabled = (val === "true");
            }
        }
    }

    readonly property var _nsfwTimer: Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            _nsfwReader.running = false;
            _nsfwReader.running = true;
        }
    }

    readonly property var _nsfwWriter: Process {
        property bool nsfwValue: false
        command: ["sh", "-c", "echo '" + (nsfwValue ? "true" : "false") + "' > '" + _nsfwFile + "'"]
        running: false
    }

    function toggleNsfw() {
        nsfwEnabled = !nsfwEnabled;
        _nsfwWriter.nsfwValue = nsfwEnabled;
        _nsfwWriter.running = true;
    }

    function setTheme(key) {
        if (themes.hasOwnProperty(key)) {
            currentTheme = key;
            _themeRequestSequence = (_themeRequestSequence + 1) % 100;
            const requestId = Math.floor(Date.now() * 100) + _themeRequestSequence;
            Quickshell.execDetached(["/home/honey/.config/quickshell/themes/switch-theme.sh", key, requestId.toString()]);
        }
    }
}
