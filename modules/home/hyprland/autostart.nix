{ lib, ... }:

let
  inherit (lib.generators) mkLuaInline;
in
{
  wayland.windowManager.hyprland.settings = {
    on = {
      _args = [
        "hyprland.start"
        (mkLuaInline ''
          function()
            hl.exec_cmd("systemctl --user start hyprpolkitagent")
            hl.exec_cmd("swaync")
            hl.exec_cmd("swayosd-server")
            hl.exec_cmd("start-quickshell")
            hl.exec_cmd("awww-daemon")
            hl.exec_cmd("wallpaper-rotation")
            hl.exec_cmd("steam -silent")
            hl.exec_cmd("mode=$(cat ~/.config/hypr/layout-mode 2>/dev/null); if [ \"$mode\" = scrolling ]; then hyprctl eval 'hl.config({ general = { layout = \"scrolling\" } }); hl.animation({ leaf = \"workspaces\", enabled = true, speed = 5, bezier = \"default\", style = \"slidevert\" })'; fi")
          end
        '')
      ];
    };
  };
}
