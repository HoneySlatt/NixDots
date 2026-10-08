{ config, inputs, pkgs, ... }:

{
  home.packages = [ inputs.amane.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  xdg.configFile."amane" = {
    source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/NixOS/modules/home/amane/config";
    force = true;
  };
}
