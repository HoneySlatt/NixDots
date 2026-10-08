import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "modules" as Modules
import "services" as Services

PanelWindow {
    id: bar

    readonly property bool isTop: BarState.isTop
    readonly property bool isFocused: Services.Compositor.focusedOutput === bar.screen.name

    property bool powerMenuOnThisScreen: PowerMenuState.visible && isFocused
    property bool steamLauncherOnThisScreen: SteamLauncherState.visible && isFocused
    visible: !steamLauncherOnThisScreen


    anchors {
        top: isTop
        bottom: !isTop
        left: true
        right: true
    }

    margins {
        top: isTop ? Theme.margin : 0
        bottom: 0
        left: isTop ? Theme.margin : 0
        right: isTop ? Theme.margin : 0
    }

    implicitHeight: Theme.barHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: isTop ? Theme.barHeight + Theme.margin : Theme.barHeight - 1

    Rectangle {
        id: barBackground
        anchors.fill: parent
        color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, isTop && !bar.isFocused ? Theme.barOpacity : 1.0)
        radius: isTop ? Theme.borderRadius : 0
        clip: true

        Behavior on color { ColorAnimation { duration: 200 } }

        Modules.Clock {
            anchors.centerIn: parent
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // === LEFT SECTION ===
            RowLayout {
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                spacing: 0

                Modules.DistroIcon {}
                Modules.Workspaces {}
                Item { implicitWidth: 8 }
                Modules.CpuUsage {}
                Modules.GpuUsage {}
                Modules.RamUsage {}
                Text {
                    visible: HdrState.enabled
                    text: "HDR"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.variableAxes: ({ "wdth": Theme.barFontWidth })
                    scale: Theme.barTextScale
                    font.pixelSize: Theme.fontSize
                    font.weight: Theme.fontWeight
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 8
                    Layout.rightMargin: 4
                }
            }

            Item { Layout.fillWidth: true }

            // === RIGHT SECTION ===
            RowLayout {
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                spacing: 0

                Modules.SystemTray { rootWindow: bar }
                Modules.Volume {}
                Modules.NetworkInfo {}
                Text {
                    text: "|"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.variableAxes: ({ "wdth": Theme.barFontWidth })
                    scale: Theme.barTextScale
                    font.pixelSize: Theme.fontSize
                    font.weight: Theme.fontWeight
                    Layout.alignment: Qt.AlignVCenter
                }
                Modules.Notifications {}
                Modules.PowerButton {}
            }
        }
    }
}
