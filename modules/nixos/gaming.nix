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
    eden
    pcsx2
    rpcs3
    slatty
    ppsspp
    shadps4
    melonds
    protonplus
    dolphin-emu
    xivlauncher
    xenia-canary
    prismlauncher
    shadps4-qtlauncher
  ];
}
