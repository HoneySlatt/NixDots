{
  programs.umbriel.settings.window_rule = [
    {
      match.is_alone = true;
      default_maximize = true;
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
