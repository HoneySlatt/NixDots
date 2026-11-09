{ inputs, pkgs, ... }:

{
  programs.steam = {
    enable = true;
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
