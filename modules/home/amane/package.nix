# amane CLI with the library patches; shared by the shell and the login screen
{ inputs, pkgs }:

inputs.amane.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [
    # Variable fonts: weight and other axes (FILL, opsz...)
    ./patches/variable-font-axes.patch
    # Ctrl shortcuts and the Delete key reach on_key
    ./patches/keyboard-shortcuts.patch
    # Who called a D-Bus method, for the system tray watcher
    ./patches/dbus-method-sender.patch
    # Hidden windows give their GPU memory back
    ./patches/release-hidden-windows.patch
    # Media follows a player with a track, not a stopped one with nothing loaded
    ./patches/media-active-player.patch
    # The Wi-Fi network list is only asked for while a window shows it
    ./patches/network-on-demand.patch
    # Workspace clicks reach a Hyprland with a Lua config (upstream 4d051ae)
    ./patches/hyprland-lua-dispatch.patch
  ];
})
