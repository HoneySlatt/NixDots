{ config, inputs, ... }:

{
  imports = [
    inputs.umbriel.homeModules.default
    inputs.noctalia.homeModules.default
    ../../modules/home/base.nix
    ../../modules/home/programs
    ../../modules/home/zed
    ../../modules/home/helix
    ../../modules/home/neovim
    ../../modules/home/niri
    ../../modules/home/amane
    ../../modules/home/amane/greeter.nix
  ];

  programs.umbriel.enable = true;
  programs.noctalia.enable = true;

  # Shortcut to the NAS drive in the home folder
  home.file."NAS".source = config.lib.file.mkOutOfStoreSymlink "/NAS";
}
