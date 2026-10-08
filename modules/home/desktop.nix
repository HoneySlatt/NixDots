{ config, ... }:

{
  imports = [
    ./common.nix
    ./config
    ./zed
    ./helix
    ./neovim
    ./niri
  ];
  home.file."NAS" = {source = config.lib.file.mkOutOfStoreSymlink "/NAS";};
}
