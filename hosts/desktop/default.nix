{ inputs, ... }:

{
  imports = [
    inputs.umbriel.nixosModules.default
    ./hardware.nix
    ./boot.nix
    ./packages.nix
    ../../modules/nixos/base
    ../../modules/nixos/desktop/brave.nix
    ../../modules/nixos/services
    ../../modules/nixos/services/sunshine.nix
    ../../modules/nixos/desktop/amane-greeter
    ../../modules/nixos/desktop/audio.nix
    ../../modules/nixos/desktop/niri.nix
    ../../modules/nixos/desktop/plasma.nix
    ../../modules/nixos/virtualisation
    ../../modules/nixos/gaming.nix
  ];

  networking.hostName = "NixBTW";

  # Reachable from the phone on the home network (Wi-Fi only): the Pluto
  # server, and Music Connect (its port, and mDNS for the devices to find
  # each other)
  networking.firewall.interfaces.wlo1 = {
    allowedTCPPorts = [ 3774 47820 ];
    allowedUDPPorts = [ 5353 ];
  };

  nix.settings = {
    substituters = [
      "https://kopuz.cachix.org"
      "https://umbriel.cachix.org"
      "https://noctalia.cachix.org"
    ];
    trusted-public-keys = [
      "kopuz.cachix.org-1:J2X3AnAYhKTJW5S3aCLoA1ckonQXVNZMQvhZA0YAufw="
      "umbriel.cachix.org-1:JfNq/2yg2S6D6z4Z2dVSZrZlDPQTKtexB6GAVLD98nw="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  programs.umbriel.enable = true;

  # AMD GPU, tuned with LACT
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  services.xserver.videoDrivers = [ "amdgpu" ];
  services.lact.enable = true;

  powerManagement.cpuFreqGovernor = "performance";
  # Compressed swap in RAM
  zramSwap.enable = true;

  services.libinput.mouse.accelProfile = "flat";

  # Run the Claude Code binary downloaded by Claude Desktop
  programs.nix-ld.enable = true;

  system.stateVersion = "25.11";
}
