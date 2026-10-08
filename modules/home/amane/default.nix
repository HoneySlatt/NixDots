{ config, inputs, pkgs, ... }:

let
  amane = inputs.amane.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
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
  });
in
{
  # Themes, theme scripts and shared state; Quickshell reads them from here too
  imports = [
    ./packages.nix
    ./scripts.nix
  ];

  home.packages = [ amane ];

  xdg.configFile."amane" = {
    source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/NixOS/modules/home/amane/config";
    force = true;
  };

  systemd.user.services.qs-userstyles-server = {
    Unit = {
      Description = "UserCSS local server for the themes";
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${config.home.profileDirectory}/bin/qs-userstyles-server";
      Restart = "on-failure";
    };

    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.quickshell-theme-background = {
    Unit.Description = "Apply secondary theme updates";

    Service = {
      Type = "oneshot";
      ExecStart = "${config.xdg.configHome}/amane/themes/switch-theme.sh --background-current";
    };
  };
}
