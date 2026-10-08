import QtQuick
import ".."

// Expressive effects motion (opacity, size without overshoot).
NumberAnimation {
    duration: Theme.effectsDuration
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Theme.effects
}
