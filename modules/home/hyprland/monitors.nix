{ lib, ... }:

let
  workspaceRule = ws: monitor: { _args = [{ workspace = toString ws; inherit monitor; }]; };
in
{
  wayland.windowManager.hyprland.settings = {
    monitor = [
      { _args = [{ output = "DP-2"; mode = "3840x2160@240.02"; position = "0x0"; scale = 1.5; bitdepth = 10; }]; }
      { _args = [{ output = "DP-3"; mode = "1920x1080@180.00"; position = "2560x0"; scale = 1; }]; }
    ];

    workspace_rule = lib.genList (i:
      let ws = i + 1; monitor = if lib.mod ws 2 == 0 then "DP-3" else "DP-2";
      in workspaceRule ws monitor
    ) 10;
  };
}
