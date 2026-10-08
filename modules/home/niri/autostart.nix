{
  programs.niri.settings.spawn-at-startup = [
    { argv = [ "awww-daemon" ]; }
    { argv = [ "wallpaper-rotation" ]; }
    { argv = [ "swaync" ]; }
    { argv = [ "swayosd-server" ]; }
    # Shell compiled by `amane compile` (modules/home/amane)
    { argv = [ "amane" "run" ]; }
    #{ argv = [ "steam" "-silent" ]; }
  ];
}
