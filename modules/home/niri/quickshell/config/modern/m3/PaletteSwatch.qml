import QtQuick
import ".."

// Android-style palette swatch: one color on top, two below.
Canvas {
    id: swatch

    property color topColor: Theme.primary
    property color leftColor: Theme.secondary
    property color rightColor: Theme.tertiary

    renderTarget: Canvas.FramebufferObject
    onTopColorChanged: requestPaint()
    onLeftColorChanged: requestPaint()
    onRightColorChanged: requestPaint()
    onWidthChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        const c = width / 2;
        const slices = [[Math.PI, 2 * Math.PI, topColor], [0, Math.PI / 2, rightColor], [Math.PI / 2, Math.PI, leftColor]];
        for (const [from, to, color] of slices) {
            ctx.beginPath();
            ctx.moveTo(c, c);
            ctx.arc(c, c, c, from, to);
            ctx.closePath();
            ctx.fillStyle = color;
            ctx.fill();
        }
    }
}
