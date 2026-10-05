import QtQuick
import ".."

// Glyph icon centered on its ink, not on its advance width:
// Nerd Font glyphs often overflow their advance, which shifts them off-center.
Text {
    id: glyph

    property string icon: ""
    property int size: 20

    text: icon
    color: Theme.textOnSurface
    font.family: Theme.fontFamily
    font.pixelSize: size
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
