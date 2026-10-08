import QtQuick
import QtQuick.Layouts
import "../services" as Services

Loader {
    Layout.alignment: Qt.AlignVCenter
    source: Qt.resolvedUrl(Services.Compositor.isHyprland ? "WorkspacesHyprland.qml" : "WorkspacesNiri.qml")
}
