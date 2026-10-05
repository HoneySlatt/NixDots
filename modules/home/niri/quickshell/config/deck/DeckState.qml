pragma Singleton

import QtQuick
import Quickshell

Singleton {
    property bool quickSettings: false
    property bool drawer: false

    function toggleQuickSettings() {
        drawer = false;
        quickSettings = !quickSettings;
    }

    function toggleDrawer() {
        quickSettings = false;
        drawer = !drawer;
    }

    function closeAll() {
        quickSettings = false;
        drawer = false;
    }

    function niri(args) {
        Quickshell.execDetached(["niri", "msg", "action"].concat(args));
    }
}
