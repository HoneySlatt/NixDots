{ config, pkgs, ... }:

{
  imports = [
    ./common.nix
    ./config
    ./zed
    ./helix
    ./neovim
    ./niri
    ./niri/quickshell
  ];
  home.file."NAS" = {source = config.lib.file.mkOutOfStoreSymlink "/NAS";};
}
