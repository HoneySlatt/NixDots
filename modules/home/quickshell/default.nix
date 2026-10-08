{ config, ... }:

{
  imports = [
    ./packages.nix
    ./scripts.nix
  ];

  xdg.configFile."quickshell" = {
    source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/NixOS/modules/home/quickshell/config";
    force = true;
  };

  systemd.user.services.qs-userstyles-server = {
    Unit = {
      Description = "Quickshell UserCSS local server";
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${config.home.profileDirectory}/bin/qs-userstyles-server";
      Restart = "on-failure";
    };

    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.quickshell-theme-background = {
    Unit.Description = "Apply secondary Quickshell theme updates";

    Service = {
      Type = "oneshot";
      ExecStart = "${config.xdg.configHome}/quickshell/themes/switch-theme.sh --background-current";
    };
  };
}
