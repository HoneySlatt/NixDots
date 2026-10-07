import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "modules" as Modules
import "services" as Services

// Googlebook-style status bar: transparent, clock on the left, status icons on the right
PanelWindow {
    id: bar

    readonly property bool isFocused: Services.NiriData.activeWorkspace !== null && Services.NiriData.activeWorkspace.output === bar.screen.name
    visible: !(SteamLauncherState.visible && isFocused)

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: Theme.barHeight

    // Keeps the status text readable on bright wallpapers
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.6) }
            GradientStop { position: 1.0; color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.0) }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 6
        spacing: 0

        Modules.Clock {
            format: "h:mmAP MMM d"
        }

        Item { Layout.fillWidth: true }

        Modules.SystemTray { rootWindow: bar }
        Modules.Volume {}
        Modules.NetworkInfo {}
        Modules.Notifications {}
        Modules.PowerButton {}
    }
}
