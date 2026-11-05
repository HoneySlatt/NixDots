{
  programs.umbriel.settings.window_rule = [
    {
      match.is_alone = true;
      # A real extent, not a maximize, so that Mod+R cycles from 100%
      default_scrolling_extent = 1.0;
    }
    { match.app_id = "^xdg-desktop-portal$"; default_floating = true; }
    {
      match.app_id = "^org.pulseaudio.pavucontrol$";
      default_floating = true;
      default_floating_size_px = { width = 1500; height = 750; };
    }
    { match.app_id = "^mpv$"; default_fullscreen = true; }
    { match.app_id = "^org\\.prismlauncher\\.PrismLauncher$"; default_floating = true; }
  ];
}
