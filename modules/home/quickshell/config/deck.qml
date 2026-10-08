//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import QtQuick
import Quickshell
import Quickshell.Io
import "deck"

ShellRoot {
    TopBar {}
    GestureHandle {}

    LazyLoader {
        active: DeckState.quickSettings
        QuickSettings {}
    }

    LazyLoader {
        active: DeckState.drawer
        AppDrawer {}
    }

    IpcHandler {
        target: "quickSettings"

        function toggle(): void {
            DeckState.toggleQuickSettings();
        }
    }

    IpcHandler {
        target: "drawer"

        function toggle(): void {
            DeckState.toggleDrawer();
        }
    }
}
