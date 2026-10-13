{
  programs.niri.settings.spawn-at-startup = [
    { argv = [ "awww-daemon" ]; }
    { argv = [ "wallpaper-rotation" ]; }
    # Shell compiled by `amane compile` (modules/home/amane)
    { argv = [ "amane" "run" ]; }
    # Preselected on the login screen next time (modules/home/amane/greeter.nix)
    { argv = [ "remember-session" "Niri" ]; }
    #{ argv = [ "steam" "-silent" ]; }
  ];
}
