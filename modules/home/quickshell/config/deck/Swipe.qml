import QtQuick

// Emits one swipe per press once the finger travels past the threshold, or a tap otherwise.
MouseArea {
    property int threshold: 40
    signal swiped(string direction)
    signal tapped()

    property point _start
    property bool _fired: false

    onPressed: mouse => {
        _start = Qt.point(mouse.x, mouse.y);
        _fired = false;
    }

    onPositionChanged: mouse => {
        if (_fired)
            return;
        const dx = mouse.x - _start.x;
        const dy = mouse.y - _start.y;
        if (Math.max(Math.abs(dx), Math.abs(dy)) < threshold)
            return;
        _fired = true;
        if (Math.abs(dx) > Math.abs(dy))
            swiped(dx > 0 ? "right" : "left");
        else
            swiped(dy > 0 ? "down" : "up");
    }

    onReleased: if (!_fired) tapped()
}
