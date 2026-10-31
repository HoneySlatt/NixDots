{ config, pkgs, ... }:

{
  imports = [ ./packages.nix ./scripts.nix ];

  # This legacy asset/state directory is also consumed by the Steam Deck shell
  # and installed application themes. It no longer installs the Amane shell.
  xdg.configFile."amane" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/NixOS/modules/home/amane/config";
    force = true;
  };

  systemd.user.services.desktop-userstyles-server = {
    Unit = {
      Description = "Local userstyles for the shared desktop themes";
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${config.home.profileDirectory}/bin/desktop-userstyles-server";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.desktop-theme-background = {
    Unit.Description = "Apply secondary desktop theme updates";
    Service = {
      Type = "oneshot";
      ExecStart = "${config.xdg.configHome}/amane/themes/switch-theme.sh --background-current";
    };
  };
}
