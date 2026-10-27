{ config, inputs, lib, pkgs, ... }:

# Second session beside niri, with mango's own tags and layouts

{
  imports = [
    inputs.mango.hmModules.mango
    ./keybindings.nix
    ./amane.nix
    ./windowrules.nix
  ];

  wayland.windowManager.mango = {
    enable = true;
    # Same build as the session entry (modules/nixos/desktop/mango.nix)
    package = pkgs.mango;

    settings = {
      env = [ "NIXOS_OZONE_WL,1" ];

      monitor_rule = [
        "name:^DP-2$,width:3840,height:2160,refresh:240.016,x:0,y:0,scale:1.5,vrr:1"
        "name:^DP-3$,width:1920,height:1080,refresh:179.999,x:2560,y:0,scale:1,vrr:1"
      ];

      xkb_rules_layout = "ca";
      # Flat
      mouse_accel_profile = 1;

      # Dwindle on every tag, as on Hyprland
      tag_rule = map (tag: "id:${toString tag},layout_name:dwindle") (lib.range 1 9);
      dwindle_preserve_split = 1;

      cursor_theme = config.home.pointerCursor.name;
      cursor_size = config.home.pointerCursor.size;

      # Gaps, rounding, borders, shadows, blur and unfocused windows of niri and the former
      # Hyprland session (git 1a7691a), whose blur was Hyprland's default one
      gap_inner_horizontal = 6;
      gap_inner_vertical = 6;
      gap_outer_horizontal = 6;
      gap_outer_vertical = 6;
      border_radius = 12;
      border_px = 2;
      # On every window; the theme sets their color (theme.conf)
      shadows = 1;
      shadow_only_floating = 0;
      shadows_blur = 30;
      shadows_size = 5;
      shadows_position_y = 5;
      shadows_color = "0x00000070";
      focused_opacity = 1.0;
      unfocused_opacity = 0.95;
      blur = 1;
      # XWayland apps keep their own size instead of a blurry upscale, as on Hyprland
      xwayland_ignore_scale = 1;

      blur_params = {
        radius = 8;
        num_passes = 1;
        noise = 0.0117;
        contrast = 0.8916;
        brightness = 0.8172;
      };
    };

    # Runs after the module has handed the session environment to systemd and D-Bus
    autostart_sh = ''
      awww-daemon &
      wallpaper-rotation &
      # Shell compiled by `amane compile` (modules/home/amane)
      amane run &
      # Preselected on the login screen next time (modules/home/amane/greeter.nix)
      remember-session Mango
    '';
  };
}
