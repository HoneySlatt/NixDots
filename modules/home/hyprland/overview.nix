{ config, pkgs, ... }:

{
  home.packages = [
    pkgs.waycorner
    (pkgs.writeShellApplication {
      name = "toggle-overview";
      runtimeInputs = [ pkgs.hyprland pkgs.jq ];
      text = ''
        active_layout="$(hyprctl -j activeworkspace 2>/dev/null | jq -r '.tiledLayout // empty' 2>/dev/null || true)"
        if [[ -z "$active_layout" && -f "$HOME/.config/hypr/layout-mode" ]]; then
          active_layout="$(tr -d '[:space:]' < "$HOME/.config/hypr/layout-mode")"
        fi

        if [[ "$active_layout" == "scrolling" ]]; then
          hyprctl eval 'hl.dispatch(hl.plugin.scrolloverview.overview("toggle all"))'
        else
          hyprctl eval 'hl.plugin.hymission.toggle("onlycurrentworkspace")'
        fi
      '';
    })
  ];

  xdg.configFile."waycorner/config.toml".text = ''
    [scrolling-overview]
    enter_command = ["toggle-overview"]
    locations = ["top_left"]
    size = 2
    timeout_ms = 0
  '';

  systemd.user.services.waycorner = {
    Unit = {
      Description = "Wayland hot corners";
      After = [ "hyprland-session.target" ];
      PartOf = [ "hyprland-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.waycorner}/bin/waycorner";
      Environment = [ "PATH=${config.home.profileDirectory}/bin" ];
      Restart = "always";
      RestartSec = 1;
    };

    Install.WantedBy = [ "hyprland-session.target" ];
  };

  wayland.windowManager.hyprland.extraLuaFiles."scrolloverview".content = ''
    local lastWorkspaceScrollBind

    local function table_value(value, ...)
      if value == nil then
        return nil
      end

      for _, key in ipairs({ ... }) do
        local ok, item = pcall(function()
          return value[key]
        end)

        if ok and item ~= nil then
          return item
        end
      end

      return nil
    end

    local function last_workspace_state()
      local monitor = hl.get_monitor_at_cursor() or hl.get_active_monitor()
      if not monitor then
        return false, nil
      end

      local activeWorkspace = table_value(monitor, "active_workspace")
      local activeWorkspaceId = table_value(activeWorkspace, "id")
      if type(activeWorkspaceId) ~= "number" or activeWorkspaceId <= 0 then
        return false, nil
      end

      local activeWorkspaceWindows = table_value(activeWorkspace, "windows")
      if type(activeWorkspaceWindows) ~= "number" or activeWorkspaceWindows == 0 then
        return false, nil
      end

      local lastWorkspaceId
      for _, workspace in ipairs(hl.get_workspaces()) do
        local id = table_value(workspace, "id")

        if type(id) == "number"
          and id > 0
          and table_value(workspace, "special") ~= true
          and table_value(workspace, "monitor") == monitor then
          lastWorkspaceId = math.max(lastWorkspaceId or id, id)
        end
      end

      return activeWorkspaceId == lastWorkspaceId, monitor
    end

    local function create_workspace_at_end()
      local isLastWorkspace, monitor = last_workspace_state()
      if not isLastWorkspace or not monitor then
        return false
      end

      hl.dispatch(hl.dsp.focus({ monitor = table_value(monitor, "name") }))
      hl.dispatch(hl.dsp.focus({ workspace = "emptynm" }))
      return true
    end

    local function navigate_down()
      if not create_workspace_at_end() then
        hl.plugin.scrolloverview.navigate("down")
      end
    end

    local function update_last_workspace_scroll_bind()
      if not lastWorkspaceScrollBind then
        return
      end

      local enabled = false
      if hl.get_current_submap() == "scrolloverview" then
        enabled = last_workspace_state()
      end

      lastWorkspaceScrollBind:set_enabled(enabled)
    end

    hl.define_submap("scrolloverview", function()
      hl.bind("SUPER + H", hl.plugin.scrolloverview.navigate("left"))
      hl.bind("SUPER + L", hl.plugin.scrolloverview.navigate("right"))
      hl.bind("SUPER + K", hl.plugin.scrolloverview.navigate("up"))
      hl.bind("SUPER + J", navigate_down)
      hl.bind("return", hl.plugin.scrolloverview.overview("select"))
      hl.bind("escape", hl.plugin.scrolloverview.overview("off all"))
      hl.bind("SUPER + TAB", hl.plugin.scrolloverview.overview("off all"))
      hl.bind("mouse:272", function()
        hl.plugin.scrolloverview.overview("select")
        hl.plugin.scrolloverview.window("select")
        hl.plugin.scrolloverview.overview("off all")
      end, { mouse = true })
      hl.bind("mouse:274", hl.plugin.scrolloverview.window("close"), { mouse = true })

      lastWorkspaceScrollBind = hl.bind("mouse_down", create_workspace_at_end)
      lastWorkspaceScrollBind:set_enabled(false)
    end)

    hl.on("workspace.active", update_last_workspace_scroll_bind)
    hl.on("workspace.created", update_last_workspace_scroll_bind)
    hl.on("workspace.removed", update_last_workspace_scroll_bind)
    hl.on("workspace.move_to_monitor", update_last_workspace_scroll_bind)
    hl.on("window.open", update_last_workspace_scroll_bind)
    hl.on("window.close", update_last_workspace_scroll_bind)
    hl.on("window.move_to_workspace", update_last_workspace_scroll_bind)
    hl.on("monitor.focused", update_last_workspace_scroll_bind)
    hl.on("keybinds.submap", update_last_workspace_scroll_bind)

    local lastWorkspaceScrollTimer = hl.timer(update_last_workspace_scroll_bind, {
      timeout = 50,
      type = "repeat",
    })

    update_last_workspace_scroll_bind()
  '';
}
