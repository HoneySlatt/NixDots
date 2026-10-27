{ config, pkgs, ... }:

# The amane shell on mango (modules/home/amane): the tools of its screenshot module,
# and the theme and bar files it writes; its shortcuts come with niri's (./keybindings.nix)

let
  mangoDir = "${config.xdg.configHome}/mango";
in
{
  # Screenshots and screencasts (src/screenshot.rs)
  home.packages = with pkgs; [
    grim
    wf-recorder
  ];

  wayland.windowManager.mango = {
    # Written by switch-theme.sh and the bar; sourced last so they win, and mango reloads when they change
    bottomPrefixes = [ "source_optional" ];

    settings.source_optional = [
      "${mangoDir}/theme.conf"
      "${mangoDir}/bar-mode.conf"
    ];
  };
}
