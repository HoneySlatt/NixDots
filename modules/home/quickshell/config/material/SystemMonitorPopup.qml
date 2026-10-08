import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "services" as Services
import "m3" as M3

Item {
    id: systemMonitorPopup

    component Sparkline: Canvas {
        id: sparkline

        property var values: []
        property int scaleMax: 100
        property color lineColor: Theme.primary
        property color areaColor: Theme.alpha(Theme.primary, 0.16)

        renderTarget: Canvas.FramebufferObject
        onValuesChanged: requestPaint()
        onLineColorChanged: requestPaint()
        onAreaColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            if (values.length < 2 || width <= 0 || height <= 0) return;

            let maxValue = Math.max(1, scaleMax);
            for (let i = 0; i < values.length; i++)
                maxValue = Math.max(maxValue, values[i]);

            function pointX(index) { return 2 + index * (width - 4) / (values.length - 1); }
            function pointY(value) { return height - 3 - Math.max(0, Math.min(1, value / maxValue)) * (height - 7); }

            ctx.beginPath();
            ctx.moveTo(pointX(0), pointY(values[0]));
            for (let i = 1; i < values.length; i++)
                ctx.lineTo(pointX(i), pointY(values[i]));
            ctx.lineTo(width - 2, height);
            ctx.lineTo(2, height);
            ctx.closePath();
            ctx.fillStyle = areaColor;
            ctx.fill();

            ctx.beginPath();
            ctx.moveTo(pointX(0), pointY(values[0]));
            for (let i = 1; i < values.length; i++)
                ctx.lineTo(pointX(i), pointY(values[i]));
            ctx.lineWidth = 3;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            ctx.strokeStyle = lineColor;
            ctx.stroke();
        }
    }

    component MetricCard: M3.ListSegment {
        id: metricCard

        property string icon: ""
        property string label: ""
        property string value: ""
        property var history: []
        property color accentColor: Theme.primary

        interactive: false
        height: 64
        clip: true

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 14

            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: Theme.shapeM
                color: Theme.mix(Theme.surfaceContainerHigh, metricCard.accentColor, 0.28)

                M3.Icon {
                    anchors.centerIn: parent
                    icon: metricCard.icon
                    size: 24
                    color: metricCard.accentColor
                }
            }

            ColumnLayout {
                Layout.preferredWidth: 84
                spacing: 0

                M3.Label {
                    text: metricCard.label
                    color: Theme.textOnSurfaceVariant
                    font.pixelSize: Theme.typeLabel
                    font.weight: Font.Bold
                }

                M3.Label {
                    text: metricCard.value
                    font.pixelSize: Theme.typeTitleL
                    font.weight: Font.Bold
                }
            }

            Sparkline {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                values: metricCard.history
                lineColor: metricCard.accentColor
                areaColor: Theme.alpha(metricCard.accentColor, 0.16)
            }
        }
    }

    component ProcessRow: Rectangle {
        id: processRow

        property var processData

        height: 36
        radius: height / 2
        color: "transparent"

        M3.StateLayer {
            hovered: processMouse.containsMouse
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 4
            spacing: 12

            M3.Label {
                Layout.fillWidth: true
                text: processRow.processData.name
            }

            M3.Label {
                Layout.preferredWidth: 54
                text: processRow.processData.cpu
                horizontalAlignment: Text.AlignRight
            }

            M3.Label {
                Layout.preferredWidth: 54
                text: processRow.processData.mem
                color: Theme.textOnSurfaceVariant
                horizontalAlignment: Text.AlignRight
            }

            M3.IconButton {
                size: 30
                icon: "close"
                opacity: processMouse.containsMouse || hovered ? 1 : 0.45
                onClicked: SystemMonitorState.killProcess(processRow.processData.pid)

                Behavior on opacity { M3.Effect {} }
            }
        }

        MouseArea {
            id: processMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root

            required property var modelData
            screen: modelData
            visible: SystemMonitorPopupState.visible && monitorIsFocused

            readonly property bool monitorIsFocused: Services.Compositor.focusedOutput === root.screen.name
            onMonitorIsFocusedChanged: if (!monitorIsFocused) SystemMonitorPopupState.close()


            color: "transparent"

            WlrLayershell.namespace: "quickshell:systemmonitorpopup"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            anchors { top: true; bottom: true; left: true; right: true }

            Connections {
                target: SystemMonitorPopupState
                function onVisibleChanged() {
                    if (SystemMonitorPopupState.visible) {
                        SystemMonitorState.refresh();
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: SystemMonitorPopupState.close()
            }

            FocusScope {
                anchors.fill: parent
                focus: SystemMonitorPopupState.visible

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        SystemMonitorPopupState.close();
                        event.accepted = true;
                    }
                }

                M3.Surface {
                    id: popup
                    anchors.top: BarState.isTop ? parent.top : undefined
                    anchors.bottom: BarState.isTop ? undefined : parent.bottom
                    anchors.topMargin: Theme.popupGap
                    anchors.left: parent.left
                    anchors.leftMargin: BarState.isTop ? Theme.margin : 0
                    width: Math.min(790, parent.width)
                    height: contentRow.implicitHeight + 32
                    flushBottom: !BarState.isTop
                    growFrom: BarState.isTop ? "top" : "bottom"

                    MouseArea { anchors.fill: parent }

                    RowLayout {
                        id: contentRow
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 16
                        spacing: 16

                        Column {
                            Layout.preferredWidth: 360
                            Layout.alignment: Qt.AlignTop
                            spacing: 2

                            MetricCard {
                                width: parent.width
                                first: true
                                icon: "memory"
                                label: "CPU"
                                value: CpuState.usage + "%"
                                history: CpuState.history
                                accentColor: Theme.primary
                            }

                            MetricCard {
                                width: parent.width
                                icon: "developer_board"
                                label: "GPU"
                                value: GpuState.tempC + "°C"
                                history: GpuState.history
                                accentColor: Theme.tertiary
                            }

                            MetricCard {
                                width: parent.width
                                last: true
                                icon: "memory_alt"
                                label: "RAM"
                                value: RamState.percentage + "%"
                                history: RamState.history
                                accentColor: Theme.misc
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 196
                            Layout.alignment: Qt.AlignTop
                            radius: Theme.shapeLI
                            color: Theme.surfaceContainerHigh

                            Column {
                                anchors.fill: parent
                                anchors.margins: 8
                                anchors.topMargin: 12
                                spacing: 6

                                RowLayout {
                                    width: parent.width
                                    height: 20
                                    spacing: 12

                                    M3.Label { Layout.fillWidth: true; leftPadding: 14; text: "Process"; color: Theme.primary; font.pixelSize: Theme.typeLabel; font.weight: Font.Bold }
                                    M3.Label { Layout.preferredWidth: 54; text: "CPU"; color: Theme.primary; font.pixelSize: Theme.typeLabel; font.weight: Font.Bold; horizontalAlignment: Text.AlignRight }
                                    M3.Label { Layout.preferredWidth: 54; text: "MEM"; color: Theme.primary; font.pixelSize: Theme.typeLabel; font.weight: Font.Bold; horizontalAlignment: Text.AlignRight }
                                    Item { Layout.preferredWidth: 34 }
                                }

                                Flickable {
                                    id: processFlick

                                    width: parent.width
                                    height: parent.height - 26
                                    contentWidth: width
                                    contentHeight: processList.implicitHeight
                                    clip: true
                                    boundsBehavior: Flickable.StopAtBounds

                                    Column {
                                        id: processList

                                        width: processFlick.width - 8
                                        spacing: 0

                                        Repeater {
                                            model: SystemMonitorState.processes
                                            delegate: ProcessRow {
                                                required property var modelData
                                                width: parent.width
                                                processData: modelData
                                            }
                                        }
                                    }

                                    Rectangle {
                                        visible: processFlick.contentHeight > processFlick.height
                                        anchors.right: parent.right
                                        width: 4
                                        height: Math.max(24, processFlick.height * processFlick.height / processFlick.contentHeight)
                                        y: processFlick.contentY * (processFlick.height - height) / Math.max(1, processFlick.contentHeight - processFlick.height)
                                        radius: 2
                                        color: Theme.outlineVariant
                                    }
                                }

                                M3.Label {
                                    visible: SystemMonitorState.processes.length === 0
                                    leftPadding: 14
                                    text: "No process data"
                                    color: Theme.textOnSurfaceVariant
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
