import QtQuick
import ".."

// Rounded polar shape from the M3 Expressive shape library (cookie, flower, circle...).
Canvas {
    id: shape

    property int lobes: 9
    property real depth: 0.08
    property real angle: 0
    property color color: Theme.primary

    renderTarget: Canvas.FramebufferObject

    onLobesChanged: requestPaint()
    onDepthChanged: requestPaint()
    onAngleChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        const cx = width / 2;
        const cy = height / 2;
        const base = Math.min(width, height) / 2 / (1 + depth);
        const steps = 120;

        ctx.fillStyle = color;
        ctx.beginPath();
        for (let i = 0; i <= steps; i++) {
            const t = i / steps * Math.PI * 2;
            const r = base * (1 + depth * Math.cos(lobes * (t + angle)));
            const x = cx + r * Math.cos(t);
            const y = cy + r * Math.sin(t);
            if (i === 0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
        }
        ctx.closePath();
        ctx.fill();
    }
}
