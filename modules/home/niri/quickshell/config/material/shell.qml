//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import QtQuick
import Quickshell
import Quickshell.Io
import "modules" as Modules

ShellRoot {
    ClickOutside {}

    Loader {
        active: LauncherState.visible
        source: "AppLauncher.qml"
    }
    Loader {
        active: PowerMenuState.visible
        source: "PowerMenu.qml"
    }
    Loader {
        active: PowerLauncherState.visible
        source: "PowerLauncher.qml"
    }
    Loader {
        active: SmallLauncherState.visible
        source: "SmallLauncher.qml"
    }
    Loader {
        active: VolumePopupState.visible
        source: "VolumePopup.qml"
    }
    Loader {
        active: NetworkPopupState.visible
        source: "NetworkPopup.qml"
    }
    Loader {
        active: SystemMonitorPopupState.visible
        source: "SystemMonitorPopup.qml"
    }
    Loader {
        active: CalendarPopupState.visible
        source: "CalendarPopup.qml"
    }
    Loader {
        active: SteamLauncherState.visible
        source: "SteamLauncher.qml"
    }
    Loader {
        active: ThemeLauncherState.visible
        source: "ThemeLauncher.qml"
    }
    Loader {
        active: WallpaperLauncherState.visible
        source: "WallpaperLauncher.qml"
    }
    Loader {
        active: MusicLauncherState.visible
        source: "MusicLauncher.qml"
    }
    Loader {
        active: VpnLauncherState.visible
        source: "VpnLauncher.qml"
    }


    Variants {
        id: shellVariants
        model: Quickshell.screens

        Bar {
            required property var modelData
            screen: modelData
        }
    }

    IpcHandler {
        target: "toggleLauncher"

        function call() {
            SmallLauncherState.toggle();
        }
    }

    IpcHandler {
        target: "togglePosition"

        function call() {
            BarState.togglePosition();
        }
    }

    IpcHandler {
        target: "togglePowerMenu"

        function call() {
            PowerMenuState.toggle();
        }
    }

    IpcHandler {
        target: "toggleSteamLauncher"

        function call() {
            SteamLauncherState.toggle();
        }
    }

    IpcHandler {
        target: "toggleThemeLauncher"

        function call() {
            ThemeLauncherState.toggle();
        }
    }

    IpcHandler {
        target: "toggleWallpaperLauncher"

        function call() {
            WallpaperLauncherState.toggle();
        }
    }

    IpcHandler {
        target: "toggleMusicLauncher"

        function call() {
            MusicLauncherState.toggle();
        }
    }

    IpcHandler {
        target: "toggleVpnLauncher"

        function call() {
            VpnLauncherState.toggle();
        }
    }


    IpcHandler {
        target: "toggleVisibility"

        function call() {
            for (let i = 0; i < shellVariants.instances.length; i++) {
                let bar = shellVariants.instances[i];
                if (bar.isFocused) {
                    bar.visible = !bar.visible;
                }
            }
        }
    }
}
