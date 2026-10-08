import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../material"
import "../material/m3" as M3

PanelWindow {
    id: root

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.namespace: "quickshell:deck-drawer"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    property string query: ""

    readonly property var apps: DesktopEntries.applications.values
        .filter(app => !app.noDisplay && app.name.toLowerCase().includes(query))
        .sort((a, b) => a.name.localeCompare(b.name))

    function launch(app) {
        app.execute();
        DeckState.closeAll();
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.scrim

        MouseArea {
            anchors.fill: parent
            onClicked: DeckState.closeAll()
        }
    }

    M3.Surface {
        anchors.fill: parent
        anchors.margins: 12
        growFrom: "bottom"

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                M3.SearchField {
                    Layout.fillWidth: true
                    placeholder: "Search apps"
                    onTextChanged: root.query = text.toLowerCase()
                    Keys.onEscapePressed: DeckState.closeAll()
                    Keys.onReturnPressed: if (root.apps.length > 0) root.launch(root.apps[0])
                }

                M3.IconButton {
                    size: 48
                    variant: "tonal"
                    icon: "keyboard"
                    onClicked: DeckState.toggleKeyboard()
                }

                M3.IconButton {
                    size: 48
                    variant: "tonal"
                    icon: "close"
                    onClicked: DeckState.closeAll()
                }
            }

            GridView {
                id: grid

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: width / Math.max(1, Math.floor(width / 140))
                cellHeight: 128
                model: ScriptModel { values: root.apps }

                delegate: Item {
                    id: cell

                    required property var modelData
                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: Theme.shapeL
                        color: Theme.textOnSurface
                        opacity: tap.pressed ? Theme.statePressed : 0
                    }

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 16
                        spacing: 10

                        IconImage {
                            anchors.horizontalCenter: parent.horizontalCenter
                            implicitSize: 56
                            source: Quickshell.iconPath(cell.modelData.icon, "application-x-executable")
                        }

                        M3.Label {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: cell.modelData.name
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                        }
                    }

                    MouseArea {
                        id: tap
                        anchors.fill: parent
                        onClicked: root.launch(cell.modelData)
                    }
                }
            }
        }
    }
}
