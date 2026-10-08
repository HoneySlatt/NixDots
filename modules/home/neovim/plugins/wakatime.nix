{ pkgs, ... }:

{
  programs.nixvim = {
    plugins.wakatime.enable = true;
    extraPackages = [ pkgs.wakatime-cli ];
  };
}
