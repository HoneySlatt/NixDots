{ config, pkgs, ... }:

{
  imports = [
    ./common.nix
    ./config
    ./zed
    ./neovim
    ./niri
    ./niri/quickshell
  ];
  home.file."NAS" = {source = config.lib.file.mkOutOfStoreSymlink "/NAS";};
}
