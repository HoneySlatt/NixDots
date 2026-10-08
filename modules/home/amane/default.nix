{ config, inputs, pkgs, ... }:

let
  amane = import ./package.nix { inherit inputs pkgs; };
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
