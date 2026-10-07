import QtQuick
import ".."

ColorAnimation {
    duration: Theme.effectsDuration
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Theme.effects
}
