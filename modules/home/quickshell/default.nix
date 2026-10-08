{ config, ... }:

{
  # Themes, theme scripts and shared state live in the amane module
  imports = [
    ./scripts.nix
  ];

  xdg.configFile."quickshell" = {
    source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/NixOS/modules/home/quickshell/config";
    force = true;
  };
}
