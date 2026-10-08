pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Compositor-specific state, so the shell runs unchanged on niri and Hyprland.
Singleton {
    readonly property bool isHyprland: !!Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")

    readonly property string focusedOutput: isHyprland ? (Hyprland.focusedMonitor?.name ?? "") : NiriData.focusedOutput

    readonly property string logoutCommand: isHyprland ? "hyprctl dispatch 'hl.dsp.exit()'" : "niri msg action quit"
}
