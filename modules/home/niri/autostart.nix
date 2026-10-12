{
  programs.niri.settings.spawn-at-startup = [
    { argv = [ "awww-daemon" ]; }
    { argv = [ "wallpaper-rotation" ]; }
    # Shell compiled by `amane compile` (modules/home/amane)
    { argv = [ "amane" "run" ]; }
    #{ argv = [ "steam" "-silent" ]; }
  ];
}
