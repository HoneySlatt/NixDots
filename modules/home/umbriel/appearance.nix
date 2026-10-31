{ config, pkgs, ... }:

{
  programs.umbriel.settings = {
    include = {
      files = [ "appearance.toml" ];
      optional.files = [
        "${config.xdg.cacheHome}/noctalia/desktop/appearance.toml"
        "${config.xdg.cacheHome}/noctalia/desktop/theme.toml"
      ];
    };
    input.cursor = {
      theme = config.home.pointerCursor.name;
      size = config.home.pointerCursor.size;
    };
  };

  # Mutable presentation values live below the runtime includes, so the compact
  # mode can override them without rewriting Home Manager's config.toml.
  xdg.configFile."umbriel/appearance.toml".source = (pkgs.formats.toml { }).generate "umbriel-appearance.toml" {
    layout.gap = 6;
    appearance = {
      border_width = 2;
      corner_radius = 12;
      shadow = { enabled = true; softness = 30; offset_x = 0; offset_y = 5; };
    };
    window_rule = [
      { match.is_focused = false; opacity = 0.95; }
      { match.is_focused = true; opacity = 1.0; }
    ];
  };
}
