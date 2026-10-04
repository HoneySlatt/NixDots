{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware.nix
      ./packages.nix
      ../../modules/nixos/common.nix
      ../../modules/nixos/nas
      ../../modules/nixos/services
      ../../modules/nixos/greetd.nix
      ../../modules/nixos/audio.nix
      ../../modules/nixos/niri.nix
    ];

  boot = {
    loader = {
      systemd-boot.enable = false;
      timeout = 1;
      efi.canTouchEfiVariables = true;
      limine = {
        enable = true;
        efiSupport = true;
        maxGenerations = 5;
        style = {
          wallpapers = [ ];
          interface = {
            brandingColor = "B4BEFE";
            helpColor = "B4BEFE";
            helpColorBright = "B4BEFE";
          };
          graphicalTerminal = {
            palette = "1E1E2E;F38BA8;A6E3A1;F9E2AF;89B4FA;F5C2E7;94E2D5;CDD6F4";
            brightPalette = "585B70;F38BA8;A6E3A1;F9E2AF;89B4FA;F5C2E7;94E2D5;CDD6F4";
            background = "1E1E2E";
            foreground = "CDD6F4";
            brightBackground = "585B70";
            brightForeground = "CDD6F4";
          };
        };
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];
    initrd.kernelModules = [ "amdgpu" ];
    kernelModules = [ "ntsync" ];
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  networking.hostName = "NixBTW";

  # Run the Claude Code binary downloaded by Claude Desktop.
  programs.nix-ld.enable = true;

  services = {
    xserver.videoDrivers = [ "amdgpu" ];
    libinput.mouse.accelProfile = "flat";
    lact.enable = true;
  };

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        swtpm.enable = true;
      };
    };
    spiceUSBRedirection.enable = true;
  };

  system.stateVersion = "25.11";
}
