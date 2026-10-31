{ inputs, ... }:

{
  imports = [
    inputs.umbriel.homeModules.default
    ./keybindings.nix
    ./monitors.nix
    ./input.nix
    ./layout.nix
    ./windowrules.nix
    ./appearance.nix
  ];

  programs.umbriel = {
    enable = true;
    settings.general = {
      autostart = [ "noctalia" ];
      show_cheatsheet = false;
    };
  };
}
