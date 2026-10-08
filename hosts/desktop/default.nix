{
  imports = [
    ./hardware.nix
    ./boot.nix
    ./packages.nix
    ../../modules/nixos/base
    ../../modules/nixos/desktop/brave.nix
    ../../modules/nixos/services
    ../../modules/nixos/desktop/gdm.nix
    ../../modules/nixos/desktop/audio.nix
    ../../modules/nixos/desktop/niri.nix
    ../../modules/nixos/virtualisation
    ../../modules/nixos/gaming.nix
  ];

  networking.hostName = "NixBTW";

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
