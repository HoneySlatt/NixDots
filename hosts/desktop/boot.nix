{ pkgs, ... }:

{
  boot = {
    loader = {
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = true;
      timeout = 1;

      # Catppuccin Mocha colors
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
    # Unlock every AMD GPU tuning knob (used by LACT)
    kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];
    initrd.kernelModules = [ "amdgpu" ];
    # NT synchronization primitives for Wine/Proton
    kernelModules = [ "ntsync" ];
  };
}
