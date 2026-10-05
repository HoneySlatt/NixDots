import QtQuick
import ".."

// Material Symbols Rounded icon, written as its ligature name (e.g. "wifi").
// Centered on its ink so glyphs from fallback fonts stay centered too.
Text {
    id: glyph

    property string icon: ""
    property int size: 20
    property bool filled: false

    text: icon
    color: Theme.textOnSurface
    font.family: Theme.iconFontFamily
    font.pixelSize: size
    font.variableAxes: ({ "FILL": filled ? 1 : 0, "opsz": Math.max(20, Math.min(48, size)), "wght": 400 })
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    TextMetrics {
        id: ink
        font: glyph.font
        text: glyph.icon
    }

    FontMetrics {
        id: metrics
        font: glyph.font
    }

    transform: Translate {
        x: ink.advanceWidth / 2 - (ink.tightBoundingRect.x + ink.tightBoundingRect.width / 2)
        y: (metrics.descent - metrics.ascent) / 2 - ink.tightBoundingRect.y - ink.tightBoundingRect.height / 2
    }

    Behavior on color { ColorEffect {} }
}
