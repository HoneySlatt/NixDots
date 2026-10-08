{ pkgs, ... }:

{
  users.users.honey = {
    isNormalUser = true;
    description = "Honey";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "jackaudio" ];
    shell = pkgs.zsh;
  };

  programs = {
    zsh.enable = true;
    dconf.enable = true;
    nano.enable = false;
  };

  environment.variables = {
    EDITOR = "nvim";
    BROWSER = "brave-origin";
  };
}
