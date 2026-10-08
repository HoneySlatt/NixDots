{ config, lib, ... }:

{
  programs.niri.settings = {
    environment.NIXOS_OZONE_WL = "1";

    # Also exports XCURSOR_THEME and XCURSOR_SIZE to spawned apps
    cursor = {
      theme = config.home.pointerCursor.name;
      inherit (config.home.pointerCursor) size;
    };

    layout = {
      gaps = 6;
      center-focused-column = "never";

      preset-column-widths = [
        { proportion = 0.33333; }
        { proportion = 0.5; }
        { proportion = 0.66667; }
        { proportion = 1.0; }
      ];

      default-column-width = { proportion = 0.5; };

      preset-window-heights = [
        { proportion = 0.33333; }
        { proportion = 0.5; }
        { proportion = 0.66667; }
      ];

      focus-ring = {
        enable = false;
      };

      border = {
        enable = true;
        width = 2;
        active.color = "#3a3a3a";
        inactive.color = "#1f1f1f";
      };

      shadow = {
        enable = true;
        softness = 30;
        spread = 5;
        offset = {
          x = 0;
          y = 5;
        };
        color = "#00000070";
      };
    };

    # Workspaces 1-10: odd ones on the main screen, even ones on the side screen.
    # Keys are zero-padded so niri keeps them in numeric order.
    workspaces = lib.listToAttrs (map (ws: {
      name = lib.fixedWidthNumber 2 ws;
      value = {
        name = toString ws;
        open-on-output = if lib.mod ws 2 == 0 then "DP-3" else "DP-2";
      };
    }) (lib.range 1 10));

    prefer-no-csd = true;

    hotkey-overlay.skip-at-startup = true;

    screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
  };
}
