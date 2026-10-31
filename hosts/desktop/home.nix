{ config, ... }:

{
  imports = [
    ../../modules/home/base.nix
    ../../modules/home/programs
    ../../modules/home/zed
    ../../modules/home/helix
    ../../modules/home/neovim
    ../../modules/home/umbriel
    ../../modules/home/noctalia
    ../../modules/home/desktop-theme
  ];

  # Shortcut to the NAS drive in the home folder
  home.file."NAS".source = config.lib.file.mkOutOfStoreSymlink "/NAS";
}
