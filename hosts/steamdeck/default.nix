{ inputs, ... }:

{
  imports = [
    ./hardware.nix
    ./packages.nix
    ../../modules/nixos/common.nix
    ../../modules/nixos/hardening.nix
    ../../modules/nixos/brave.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/niri.nix
    inputs.jovian.nixosModules.default
  ];

  networking.hostName = "NixDeck";

  jovian = {
    devices.steamdeck.enable = true;
    steamos.useSteamOSConfig = true;

    steam = {
      enable = true;
      user = "honey";
      autoStart = true;
      desktopSession = "niri";
    };

    decky-loader = {
      enable = true;
      user = "honey";
    };
  };

  programs.gamemode.enable = true;

  services.upower.enable = true;

  boot = {
    loader = {
      systemd-boot.enable = true;
      timeout = 0;
      efi.canTouchEfiVariables = true;
    };
    kernelParams = [ "quiet" "splash" ];
    consoleLogLevel = 0;
    initrd.verbose = false;
  };

  system.stateVersion = "25.11";
}
