{ inputs, pkgs, ... }:

{
  nix = {
    settings.experimental-features = [ "nix-command" "flakes" ];
    # Deduplicate the store on a schedule instead of during every build
    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [ (import ../../pkgs inputs) ];

  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "cf";

  networking.networkmanager.enable = true;

  users.users.honey = {
    isNormalUser = true;
    description = "Honey";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "jackaudio" ];
    shell = pkgs.zsh;
  };

  programs.nano.enable = false;
  programs.zsh.enable = true;
  programs.dconf.enable = true;

  environment.variables = {
    EDITOR = "nvim";
    BROWSER = "brave-origin";
  };
}
