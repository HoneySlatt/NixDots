{
  programs.niri.settings.spawn-at-startup = [
    { argv = [ "awww-daemon" ]; }
    { argv = [ "wallpaper-rotation" ]; }
    { argv = [ "swaync" ]; }
    { argv = [ "swayosd-server" ]; }
    { argv = [ "start-quickshell" ]; }
    { argv = [ "steam" "-silent" ]; }
  ];
}
