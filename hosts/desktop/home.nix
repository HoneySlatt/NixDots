{ config, ... }:

{
  imports = [
    ../../modules/home/base.nix
    ../../modules/home/programs
    ../../modules/home/zed
    ../../modules/home/neovim
    ../../modules/home/niri
    ../../modules/home/amane
    ../../modules/home/cosmic-greeter.nix
  ];

  # Shortcut to the NAS drive in the home folder
  home.file."NAS".source = config.lib.file.mkOutOfStoreSymlink "/NAS";
}
