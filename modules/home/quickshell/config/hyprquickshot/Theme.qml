pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    property string currentTheme: "pastelglow"

    readonly property var themes: ({
        "pastelglow": {
            background: "#F8E9EE", text: "#3B2730", separator: "#E2C2CB",
            warning: "#E0486B", caution: "#8B6F79", misc: "#63C7C8",
            process: "#6D8CE3", accent: "#B86EE6", highlight: "#E0486B"
        },
        "rosepine": {
            background: "#191724", text: "#e0def4", separator: "#26233a",
            warning: "#eb6f92", caution: "#403d52", misc: "#31748f",
            process: "#9ccfd8", accent: "#c4a7e7", highlight: "#c4a7e7"
        },
        "gruvbox": {
            background: "#282828", text: "#ebdbb2", separator: "#3c3836",
            warning: "#fb4934", caution: "#504945", misc: "#8ec07c",
            process: "#83a598", accent: "#d3869b", highlight: "#fabd2f"
        },
        "everforest": {
            background: "#2d353b", text: "#d3c6aa", separator: "#343f44",
            warning: "#e67e80", caution: "#3d484d", misc: "#83c092",
            process: "#7fbbb3", accent: "#a7c080", highlight: "#dbbc7f"
        },
        "carbonfox": {
            background: "#161616", text: "#f2f4f8", separator: "#2a2a2a",
            warning: "#ff0000", caution: "#525253", misc: "#808080",
            process: "#a0a0a0", accent: "#3a3a3a", highlight: "#c6c6c6"
        },
        "gruvbox-light": {
            background: "#fbf1c7", text: "#3c3836", separator: "#ebdbb2",
            warning: "#cc241d", caution: "#d5c4a1", misc: "#689d6a",
            process: "#458588", accent: "#b16286", highlight: "#d79921"
        }
    })

    readonly property var _current: themes[currentTheme] || themes["pastelglow"]

    readonly property color background: _current.background
    readonly property color text: _current.text
    readonly property color separator: _current.separator
    readonly property color warning: _current.warning
    readonly property color caution: _current.caution
    readonly property color accent: _current.accent
    readonly property color process: _current.process

    readonly property string fontFamily: "Google Sans Flex"
    readonly property int fontSize: 12
    readonly property int fontWeight: Font.DemiBold

    readonly property string _themeFile: Quickshell.env("HOME") + "/.config/quickshell/.current-theme"

    readonly property var _reader: Process {
        command: ["cat", _themeFile]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const key = data.trim()
                if (themes.hasOwnProperty(key)) currentTheme = key
            }
        }
    }
}
