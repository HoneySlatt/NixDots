{
  programs.niri.settings.window-rules = [
    {
      matches = [ { } ];
      geometry-corner-radius = {
        top-left = 12.0;
        top-right = 12.0;
        bottom-left = 12.0;
        bottom-right = 12.0;
      };
      clip-to-geometry = true;
      opacity = 0.97;
      draw-border-with-background = false;
    }
    {
      matches = [ { is-focused = true; } ];
      opacity = 1.0;
    }
    {
      matches = [ { app-id = "^xdg-desktop-portal$"; } ];
      open-floating = true;
    }
    {
      matches = [ { app-id = "^org.pulseaudio.pavucontrol$"; } ];
      open-floating = true;
      default-column-width = { fixed = 1500; };
      default-window-height = { fixed = 750; };
    }
    {
      matches = [ { app-id = "^mpv$"; } ];
      open-fullscreen = true;
    }
    {
      matches = [ { app-id = "^org\\.prismlauncher\\.PrismLauncher$"; } ];
      open-floating = true;
    }
  ];
}
