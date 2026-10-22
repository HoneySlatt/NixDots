{ inputs, pkgs, ... }:

{
  # Provides millennium-steam, Steam with the Millennium theming framework
  nixpkgs.overlays = [ inputs.millennium.overlays.default ];

  programs.steam = {
    enable = true;
    package = pkgs.millennium-steam;
    remotePlay.openFirewall = true;
    protontricks.enable = true;
  };

  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    heroic
    xivlauncher
    protonplus
    prismlauncher
    slatty
  ];
}
