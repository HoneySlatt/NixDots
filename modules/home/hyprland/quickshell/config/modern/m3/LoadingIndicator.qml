import QtQuick
import ".."

// M3 Expressive loading indicator: a rotating shape that morphs between forms.
Item {
    id: indicator

    property bool contained: true
    property color color: contained ? Theme.textOnPrimaryContainer : Theme.primary
    property real cycle: 0

    readonly property var lobeSequence: [9, 4, 6, 5, 8, 3]
    readonly property real morph: Math.sin(Math.PI * (cycle - Math.floor(cycle)))

    implicitWidth: 48
    implicitHeight: 48

    NumberAnimation on cycle {
        running: indicator.visible
        from: 0
        to: indicator.lobeSequence.length
        duration: indicator.lobeSequence.length * 700
        loops: Animation.Infinite
    }

    Rectangle {
        visible: indicator.contained
        anchors.fill: parent
        radius: width / 2
        color: Theme.primaryContainer
    }

    PolarShape {
        anchors.centerIn: parent
        width: parent.width * (indicator.contained ? 0.7 : 1)
        height: width
        color: indicator.color
        lobes: indicator.lobeSequence[Math.floor(indicator.cycle) % indicator.lobeSequence.length]
        depth: 0.05 + 0.13 * indicator.morph
        rotation: indicator.cycle * 140
    }
}
