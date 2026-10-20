{
  imports = [
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
    ../../modules/nixos/desktop/hyprland.nix
    ../../modules/nixos/desktop/plasma.nix
    ../../modules/nixos/virtualisation
    ../../modules/nixos/gaming.nix
  ];

  networking.hostName = "NixBTW";

  nix.settings = {
    substituters = [ "https://kopuz.cachix.org" ];
    trusted-public-keys = [
      "kopuz.cachix.org-1:J2X3AnAYhKTJW5S3aCLoA1ckonQXVNZMQvhZA0YAufw="
    ];
  };

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
