# amane CLI with the library patches; shared by the shell and the login screen
{ inputs, pkgs }:

inputs.amane.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [
    # Variable fonts: Google Sans Flex outlines, weight and other axes (wdth, FILL...)
    ./patches/variable-font-axes.patch
    # Ctrl shortcuts and the Delete key reach on_key
    ./patches/keyboard-shortcuts.patch
    # Who called a D-Bus method, for the system tray watcher
    ./patches/dbus-method-sender.patch
    # Hidden windows give their GPU memory back
    ./patches/release-hidden-windows.patch
  ];
})
