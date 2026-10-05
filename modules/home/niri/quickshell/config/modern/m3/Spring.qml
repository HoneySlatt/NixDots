import QtQuick
import ".."

// Expressive spatial motion: "fast", "default" or "slow" spring.
NumberAnimation {
    property string speed: "fast"

    duration: speed === "slow" ? Theme.springSlowDuration : speed === "default" ? Theme.springDefaultDuration : Theme.springFastDuration
    easing.type: Easing.BezierSpline
    easing.bezierCurve: speed === "slow" ? Theme.springSlow : speed === "default" ? Theme.springDefault : Theme.springFast
}
