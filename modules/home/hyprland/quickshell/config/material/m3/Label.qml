import QtQuick
import ".."

Text {
    color: Theme.textOnSurface
    font.family: Theme.fontFamily
    font.pixelSize: Theme.typeBody
    font.weight: Theme.fontWeight
    elide: Text.ElideRight

    Behavior on color { ColorEffect {} }
}
