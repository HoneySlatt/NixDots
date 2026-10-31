{ pkgs, ... }:

let
  # Noctalia's glyphs are Tabler only, so the Nerd Font symbols are drawn as tintable images.
  glyphs = pkgs.runCommand "noctalia-bar-glyphs" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
    export LC_ALL=C.UTF-8
    mkdir $out
    render() {
      magick -background none -fill white -pointsize 192 \
        -font ${pkgs.nerd-fonts.symbols-only}/share/fonts/truetype/NerdFonts/Symbols/SymbolsNerdFont-Regular.ttf \
        "label:$(printf "\U$2")" -trim +repage -resize 128x128 \
        -gravity center -extent 128x128 $out/$1.png
    }
    render nixos 0000f313
    render cpu 0000f2db
    render gpu 0000f2c8
    render ram 0000efc5
    render power 000023fb
  '';
  image = name: {
    custom_image = "${glyphs}/${name}.png";
    custom_image_colorize = true;
  };

  sysmon = stat: name: image name // {
    type = "sysmon";
    inherit stat;
    visualization = "none";
    actions = {
      left = "panel-toggle control-center system";
      right = "panel-toggle local/desktop:processes";
    };
  };
in
{
  programs.noctalia.settings = {
    shell = {
      font_family = "Geist";
      time_format = "{:%H:%M}";
      launcher = { layout = "simple"; compact = true; };
      panel = {
        launcher_placement = "floating";
        session_placement = "floating";
        session_position = "center";
      };
      session.actions = [
        { action = "shutdown"; shortcut = "s"; }
        { action = "reboot"; shortcut = "r"; }
        { action = "logout"; shortcut = "e"; }
        { action = "lock"; shortcut = "o"; }
      ];
      screenshot = {
        directory = "~/Pictures/Screenshots";
        skip_annotate_on_copy_save = true;
      };
    };

    bar.main = {
      position = "top";
      thickness = 30;
      margin_ends = 6;
      margin_edge = 6;
      padding = 8;
      radius = 12;
      background_opacity = 1.0;
      font_scale = 0.96;
      widget_spacing = 8;
      capsule = false;
      shadow = false;
      start = [ "launcher" "workspaces" "cpu" "gpu" "ram" ];
      center = [ "clock" ];
      end = [ "media" "tray" "volume" "network" "vpn" "notifications" "control-center" ];
    };

    widget = {
      workspaces = {
        style = "regular";
        show_labels = true;
        label_source = "name";
        hide_when_empty = true;
        show_all_outputs = true;
      };
      launcher = image "nixos";
      cpu = sysmon "cpu_usage" "cpu";
      gpu = sysmon "gpu_temp" "gpu";
      ram = sysmon "ram_pct" "ram";
      control-center = image "power";
      media = { hide_when_no_media = true; hide_when_idle = true; };
      tray.drawer = true;
      network.show_label = false;
      clock.format = "{:%I:%M %p - %a %d}";
      vpn.type = "local/desktop:vpn-status";
    };

    theme = {
      source = "custom";
      custom_palette = "carbonfox";
      mode = "dark";
      templates = {
        enable_builtin_templates = false;
        enable_community_templates = false;
      };
    };
    wallpaper = {
      transition = [ "wipe" ];
      transition_duration = 2000;
      automation = {
        enabled = true;
        interval_seconds = 300;
        order = "random";
        pause_on_fullscreen = true;
      };
    };
    notification = { follow_focused_output = true; max_visible = 4; };
    osd.follow_focused_output = true;
    control_center.shortcuts = [
      { type = "wifi"; }
      { type = "bluetooth"; }
      { type = "caffeine"; }
      { type = "nightlight"; }
      { type = "notification"; }
      { type = "local/desktop:vpn-toggle"; }
    ];
    dock.enabled = false;
    idle.behavior = {
      dim = {
        timeout = 150;
        action = "command";
        command = "brightnessctl -s set 10%";
        resume_command = "brightnessctl -r";
      };
      lock.enabled = false;
      screen-off = {
        enabled = true;
        timeout = 300;
        action = "screen_off";
        resume_command = "brightnessctl -r";
      };
    };
    hooks = {
      started = "noctalia-desktop sync";
      colors_changed = "noctalia-desktop theme-changed";
    };
    plugins = {
      auto_update = "none";
      enabled = [ "local/desktop" ];
    };
  };
}
