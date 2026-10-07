import QtQuick
import ".."

// M3 Expressive wavy linear progress: the wave flattens when not playing.
Canvas {
    id: progress

    property real value: 0
    property bool playing: false
    property color activeColor: Theme.primary
    property color trackColor: Theme.secondaryContainer
    property real amplitude: 3
    property real wavelength: 32
    property real strokeWidth: 4
    property real phase: 0
    property real waveAmount: playing ? 1 : 0

    implicitHeight: strokeWidth + amplitude * 2 + 4
    renderTarget: Canvas.FramebufferObject

    Behavior on waveAmount { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }

    NumberAnimation on phase {
        running: progress.playing && progress.visible
        from: 0
        to: Math.PI * 2
        duration: 1400
        loops: Animation.Infinite
    }

    onValueChanged: requestPaint()
    onPhaseChanged: requestPaint()
    onWaveAmountChanged: requestPaint()
    onActiveColorChanged: requestPaint()
    onTrackColorChanged: requestPaint()
    onWidthChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        if (width <= 0) return;

        const half = strokeWidth / 2;
        const cy = height / 2;
        const v = Math.max(0, Math.min(1, value));
        const end = half + v * (width - strokeWidth);
        const amp = amplitude * waveAmount * Math.min(1, v * 12);
        const gap = strokeWidth + 4;

        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        ctx.lineWidth = strokeWidth;

        if (end > half + 0.5) {
            ctx.strokeStyle = activeColor;
            ctx.beginPath();
            for (let x = half; x <= end; x += 1) {
                const y = cy + amp * Math.sin((x / wavelength) * Math.PI * 2 - phase);
                if (x === half) ctx.moveTo(x, y);
                else ctx.lineTo(x, y);
            }
            ctx.stroke();
        }

        const trackStart = v > 0 ? end + gap : half;
        if (trackStart < width - half) {
            ctx.strokeStyle = trackColor;
            ctx.beginPath();
            ctx.moveTo(trackStart, cy);
            ctx.lineTo(width - half, cy);
            ctx.stroke();

            ctx.fillStyle = activeColor;
            ctx.beginPath();
            ctx.arc(width - half, cy, half * 0.5, 0, Math.PI * 2);
            ctx.fill();
        }
    }
}
