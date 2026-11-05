{ inputs, ... }:

{
  imports = [
    inputs.umbriel.homeModules.default
    ../hyprlock.nix
    ../swayidle.nix
    ./packages.nix
    ./keybindings.nix
    ./monitors.nix
    ./input.nix
    ./layout.nix
    ./windowrules.nix
    ./appearance.nix
  ];

  programs.umbriel = {
    enable = true;
    settings.environment.NIXOS_OZONE_WL = "1";
    settings.general = {
      autostart = [
        "awww-daemon"
        "wallpaper-rotation"
        # Shell compiled by `amane compile` (modules/home/amane)
        "amane run"
        # Preselected on the login screen next time (modules/home/amane/greeter.nix)
        "remember-session Umbriel"
      ];
      show_cheatsheet = false;
      # Keeps X11 apps sharp on the scaled output, like Hyprland's force_zero_scaling
      xwayland_native_resolution = true;
    };
  };
}
