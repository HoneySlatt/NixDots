let
  windowRule = spec: { _args = [ spec ]; };
in
{
  wayland.windowManager.hyprland.settings = {
    window_rule = [
      (windowRule {
        name = "xdg-desktop-portal-float";
        match = { class = "^(xdg-desktop-portal)$"; };
        float = true;
      })
      (windowRule {
        name = "pavucontrol-float";
        match = { class = "^(org.pulseaudio.pavucontrol)$"; };
        float = true;
      })
      (windowRule {
        name = "pavucontrol-size";
        match = { class = "^(org.pulseaudio.pavucontrol)$"; };
        size = "1500 750";
      })
      (windowRule {
        name = "mpv-fullscreen";
        match = { class = "^(mpv)$"; };
        fullscreen = true;
      })
      (windowRule {
        name = "prismlauncher-float";
        match = { class = "^(org\\.prismlauncher\\.PrismLauncher)$"; };
        float = true;
      })
    ];
  };
}
