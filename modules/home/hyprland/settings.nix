{ config, ... }:

let
  mkEnv = name: value: { _args = [ name value ]; };
  mkAnim = leaf: speed: { _args = [{ inherit leaf; enabled = true; bezier = "default"; inherit speed; }]; };
in
{
  wayland.windowManager.hyprland.settings = {
    env = [
      (mkEnv "XCURSOR_THEME" config.home.pointerCursor.name)
      (mkEnv "XCURSOR_SIZE" (toString config.home.pointerCursor.size))
      (mkEnv "DXVK_HDR" "1")
      (mkEnv "ENABLE_HDR_WSI" "1")
      (mkEnv "XDG_DATA_DIRS" "/etc/profiles/per-user/honey/share:/run/current-system/sw/share:/usr/local/share:/usr/share")
    ];

    config = {
      general = {
        gaps_in = 6;
        gaps_out = 6;
        border_size = 2;
        col = {
          active_border = "rgba(3a3a3aff)";
          inactive_border = "rgba(1f1f1fff)";
        };
        layout = "dwindle";
      };

      decoration = {
        rounding = 12;
        active_opacity = 1.0;
        inactive_opacity = 0.9;
        shadow = {
          enabled = true;
          range = 30;
          render_power = 5;
          offset = "0 5";
          color = "rgba(00000070)";
        };
      };

      animations = {
        enabled = true;
      };

      dwindle = {
        preserve_split = true;
      };

      scrolling = {
        column_width = 0.5;
        focus_fit_method = 1;
        follow_focus = true;
        follow_min_visible = 0.4;
        explicit_column_widths = "0.333, 0.5, 0.667, 1.0";
        fullscreen_on_one_column = true;
        direction = "right";
      };

      plugin.scrolloverview = {
        gesture_distance = 300;
        scale = 0.5;
        workspace_gap = 100;
        layout = "vertical";
        wallpaper = 2;
        blur = true;
        input = {
          scroll_event_delay = 150;
          scrolling_mode = 2;
          drag_mode = 0;
          drag_threshold = 10;
        };
        shadow = {
          enabled = true;
          range = 50;
        };
      };

      plugin.hymission = {
        only_active_workspace = 1;
        only_active_monitor = 1;
        workspace_change_keeps_overview = 1;

        layout_engine_onlycurrentworkspace = "natural";
        hover_expand_scale = 1.0;
        overview_focus_follows_mouse = 1;
        show_focus_indicator = 0;
        window_decoration_enabled = 0;

        workspace_strip_anchor = "top";
        workspace_strip_empty_mode = "existing";
        workspace_strip_thickness = 160;
        workspace_strip_gap = 24;
        hide_bar_when_strip = 1;

        backdrop_blur = 1;
        backdrop_color = "rgba(00000000)";
        toggle_switch_mode = 0;
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        vrr = 2;
      };

      render = {
        cm_auto_hdr = 1;
      };

      xwayland = {
        force_zero_scaling = true;
      };
    };

    animation = [
      (mkAnim "windowsIn" 3)
      (mkAnim "windowsOut" 3)
      (mkAnim "workspaces" 5)
      (mkAnim "windowsMove" 4)
      (mkAnim "fade" 3)
      (mkAnim "border" 3)
    ];
  };
}
