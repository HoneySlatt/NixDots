{ config, pkgs, ... }:

{
  imports = [
    ./common.nix
    ./config
    ./zed
    ./neovim
    ./hyprland
    ./hyprland/quickshell
  ];
  home.file."NAS" = {source = config.lib.file.mkOutOfStoreSymlink "/NAS";};
}
