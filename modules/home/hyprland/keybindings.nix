{ lib, ... }:

let
  inherit (lib.generators) mkLuaInline;

  luaString = builtins.toJSON;
  bind = key: action: { _args = [ key action ]; };
  bindWith = key: action: options: { _args = [ key action options ]; };

  luaAction = code: mkLuaInline ''
    function()
      ${code}
    end
  '';
  luaActionExpr = code: ''
    function()
      ${code}
    end
  '';

  execExpr = command: "hl.dsp.exec_cmd(${luaString command})";
  exec = command: mkLuaInline "hl.dsp.exec_cmd(${luaString command})";
  noOpExpr = "hl.dsp.no_op()";
  focusExpr = direction: "hl.dsp.focus({ direction = ${luaString direction} })";
  moveWindowExpr = direction: "hl.dsp.window.move({ direction = ${luaString direction} })";
  workspaceRefExpr = reference: "hl.dsp.focus({ workspace = ${luaString reference} })";
  moveToWorkspaceRefExpr = reference: "hl.dsp.window.move({ workspace = ${luaString reference} })";
  monitorWorkspaceExpr = action: offset: luaActionExpr ''
    local active = hl.get_active_workspace()
    if active then
      local target = active.id + ${toString offset}
      if target > 0 then
        hl.dispatch(${action})
      end
    end
  '';
  monitorWorkspacePrev = action: monitorWorkspaceExpr action (-2);
  monitorWorkspaceNext = action: monitorWorkspaceExpr action 2;
  layoutExpr = message: "hl.dsp.layout(${luaString message})";
  layoutAware = scrollingAction: dwindleAction: luaAction ''
    local workspace = hl.get_active_workspace()
    if workspace and workspace.tiled_layout == "scrolling" then
      hl.animation({
        leaf = "workspaces",
        enabled = true,
        speed = 5,
        bezier = "default",
        style = "slidevert",
      })
      hl.dispatch(${scrollingAction})
    else
      hl.animation({
        leaf = "workspaces",
        enabled = true,
        speed = 5,
        bezier = "default",
        style = "slide",
      })
      hl.dispatch(${dwindleAction})
    end
  '';
  toggleLayout = luaAction ''
    local active = hl.get_active_workspace()
    local target = "scrolling"
    if active and active.tiled_layout == "scrolling" then
      target = "dwindle"
    end
    local animation = "slide"
    if target == "scrolling" then
      animation = "slidevert"
    end

    hl.exec_cmd("printf '%s' " .. target .. " > ~/.config/hypr/layout-mode")

    hl.config({ general = { layout = target } })
    hl.animation({
      leaf = "workspaces",
      enabled = true,
      speed = 5,
      bezier = "default",
      style = animation,
    })

    for i = 1, 10 do
      local monitor = "DP-2"
      if i % 2 == 0 then
        monitor = "DP-3"
      end

      hl.workspace_rule({
        workspace = tostring(i),
        monitor = monitor,
        layout = target,
        animation = animation,
      })
    end

    hl.notification.create({
      text = "Layout: " .. target,
      timeout = 1500,
    })
  '';
  toggleOverview = luaAction ''
    local workspace = hl.get_active_workspace()
    if workspace and workspace.tiled_layout == "scrolling" then
      hl.plugin.scrolloverview.overview("toggle all")
    else
      hl.plugin.hymission.toggle("onlycurrentworkspace")
    end
  '';
  workspace = number: mkLuaInline "hl.dsp.focus({ workspace = ${toString number} })";
  moveToWorkspace = number: mkLuaInline "hl.dsp.window.move({ workspace = ${toString number} })";
in
{
  wayland.windowManager.hyprland.settings = {
    bind = [
      # App launchers
      (bind "CTRL + SHIFT + T" (exec "ghostty +new-window"))
      (bind "SUPER + Q" (mkLuaInline "hl.dsp.window.close()"))
      (bind "SUPER + E" (exec "ghostty +new-window -e yazi"))
      (bind "SUPER + SHIFT + E" (exec "nautilus"))
      (bind "SUPER + V" (mkLuaInline "hl.dsp.window.float({ action = 'toggle' })"))
      (bind "SUPER + SPACE" (exec "toggle-launcher"))
      (bind "SUPER + T" (exec "toggle-theme-launcher"))
      (bind "SUPER + W" (exec "toggle-wallpaper-launcher"))
      (bind "SUPER + G" (exec "toggle-game-launcher"))
      (bind "SUPER + ALT + M" (exec "toggle-music-launcher"))
      (bind "SUPER + P" (exec "toggle-power-launcher"))
      (bind "SUPER + R" (layoutAware (layoutExpr "colresize +conf") (execExpr "toggle-power-launcher")))
      (bind "SUPER + SHIFT + R" (layoutAware (layoutExpr "colresize -conf") noOpExpr))
      (bind "SUPER + CTRL + SHIFT + R" (layoutAware (layoutExpr "fit active") noOpExpr))
      (bind "SUPER + TAB" toggleOverview)
      (bind "SUPER + B" (exec "brave-origin"))
      (bind "SUPER + SHIFT + B" (exec "firefox"))
      (bind "SUPER + M" (exec "cider-2"))
      (bind "SUPER + SHIFT + M" (exec "kopuz"))
      (bind "SUPER + SHIFT + T" (exec "toggle-quickshell"))
      (bind "SUPER + SHIFT + Q" (exec "toggle-quickshell"))
      (bind "SUPER + SHIFT + W" (exec "toggle-bar-position"))
      (bind "SUPER + SHIFT + V" (exec "toggle-nym"))
      (bind "SUPER + CTRL + V" (exec "toggle-vpn-launcher"))
      (bind "SUPER + U" (exec "toggle-nsfw"))
      (bind "SUPER + S" (exec "hyprquickshot-toggle"))
      (bind "SUPER + SHIFT + S" toggleLayout)
      (bind "SUPER + SHIFT + P" (exec "hyprpicker"))
      (bind "SUPER + D" (exec "discord"))
      (bind "SUPER + SHIFT + D" (exec "element-desktop"))
      (bind "CTRL + SHIFT + M" (exec "tutanota-desktop --no-sandbox %U"))
      (bind "SUPER + CTRL + N" (exec "jellyfin-desktop"))
      (bind "SUPER + SHIFT +G" (exec "heroic"))
      (bind "SUPER + CTRL +G" (exec "steam"))
      (bind "SUPER + F" (layoutAware (layoutExpr "fit active") "hl.dsp.window.fullscreen({ mode = 'maximized', action = 'toggle' })"))
      (bind "SUPER + C" (exec "claude-desktop"))
      (bind "SUPER + SHIFT + C" (exec "chatgpt"))
      (bind "SUPER + CTRL + C" (exec "ghostty +new-window -e claude"))
      (bind "SUPER + CTRL + SHIFT + C" (exec "ghostty +new-window -e codex"))
      (bind "SUPER + O" (exec "obsidian"))
      (bind "SUPER + N" (exec "ghostty +new-window -e nvim"))
      (bind "SUPER + SHIFT + N" (exec "zeditor"))
      (bind "CTRL + ALT + DELETE" (exec "ghostty +new-window -e btop"))
      (bind "SUPER + Escape" (exec "lock-screen"))
      (bind "SUPER + SHIFT + Escape" (mkLuaInline "hl.dsp.exit()"))

      # Move focus/workspaces with HJKL
      (bind "SUPER + H" (layoutAware (layoutExpr "focus l") (focusExpr "left")))
      (bind "SUPER + L" (layoutAware (layoutExpr "focus r") (focusExpr "right")))
      (bind "SUPER + K" (layoutAware (monitorWorkspacePrev "hl.dsp.focus({ workspace = target, on_current_monitor = true })") (focusExpr "up")))
      (bind "SUPER + J" (layoutAware (monitorWorkspaceNext "hl.dsp.focus({ workspace = target, on_current_monitor = true })") (focusExpr "down")))
      (bind "SUPER + CTRL + K" (layoutAware (layoutExpr "focus u") (workspaceRefExpr "e-1")))
      (bind "SUPER + CTRL + J" (layoutAware (layoutExpr "focus d") (workspaceRefExpr "e+1")))

      # Move windows with Shift + HJKL
      (bind "SUPER + SHIFT + H" (layoutAware (layoutExpr "swapcol l") (moveWindowExpr "left")))
      (bind "SUPER + SHIFT + L" (layoutAware (layoutExpr "swapcol r") (moveWindowExpr "right")))
      (bind "SUPER + SHIFT + K" (layoutAware (monitorWorkspacePrev "hl.dsp.window.move({ workspace = target })") (moveWindowExpr "up")))
      (bind "SUPER + SHIFT + J" (layoutAware (monitorWorkspaceNext "hl.dsp.window.move({ workspace = target })") (moveWindowExpr "down")))
      (bind "SUPER + CTRL + SHIFT + K" (layoutAware (moveWindowExpr "up") noOpExpr))
      (bind "SUPER + CTRL + SHIFT + J" (layoutAware (moveWindowExpr "down") noOpExpr))
      (bind "SUPER + minus" (layoutAware (layoutExpr "colresize -0.1") noOpExpr))
      (bind "SUPER + equal" (layoutAware (layoutExpr "colresize +0.1") noOpExpr))
      (bind "SUPER + SHIFT + minus" (layoutAware (layoutExpr "colresize -0.1") noOpExpr))
      (bind "SUPER + SHIFT + equal" (layoutAware (layoutExpr "colresize +0.1") noOpExpr))

      # Focus workspace
      (bind "SUPER + 1" (workspace 1))
      (bind "SUPER + 2" (workspace 2))
      (bind "SUPER + 3" (workspace 3))
      (bind "SUPER + 4" (workspace 4))
      (bind "SUPER + 5" (workspace 5))
      (bind "SUPER + 6" (workspace 6))
      (bind "SUPER + 7" (workspace 7))
      (bind "SUPER + 8" (workspace 8))
      (bind "SUPER + 9" (workspace 9))
      (bind "SUPER + 0" (workspace 10))

      # Move window to workspace
      (bind "SUPER + SHIFT + 1" (moveToWorkspace 1))
      (bind "SUPER + SHIFT + 2" (moveToWorkspace 2))
      (bind "SUPER + SHIFT + 3" (moveToWorkspace 3))
      (bind "SUPER + SHIFT + 4" (moveToWorkspace 4))
      (bind "SUPER + SHIFT + 5" (moveToWorkspace 5))
      (bind "SUPER + SHIFT + 6" (moveToWorkspace 6))
      (bind "SUPER + SHIFT + 7" (moveToWorkspace 7))
      (bind "SUPER + SHIFT + 8" (moveToWorkspace 8))
      (bind "SUPER + SHIFT + 9" (moveToWorkspace 9))
      (bind "SUPER + SHIFT + 0" (moveToWorkspace 10))

      # Scroll workspaces up/down
      (bind "SUPER + mouse_down" (mkLuaInline "hl.dsp.focus({ workspace = 'e+1' })"))
      (bind "SUPER + mouse_up" (mkLuaInline "hl.dsp.focus({ workspace = 'e-1' })"))

      # Move/resize windows with mouse
      (bindWith "SUPER + mouse:272" (mkLuaInline "hl.dsp.window.drag()") { mouse = true; })
      (bindWith "SUPER + mouse:273" (mkLuaInline "hl.dsp.window.resize()") { mouse = true; })

      # Volume and brightness (repeat on hold, work when locked)
      (bindWith "XF86AudioRaiseVolume" (exec "swayosd-client --monitor DP-2 --output-volume raise") { locked = true; repeating = true; })
      (bindWith "XF86AudioLowerVolume" (exec "swayosd-client --monitor DP-2 --output-volume lower") { locked = true; repeating = true; })
      (bindWith "XF86AudioMute" (exec "swayosd-client --monitor DP-2 --output-volume mute-toggle") { locked = true; repeating = true; })
      (bindWith "XF86AudioMicMute" (exec "swayosd-client --monitor DP-2 --input-volume mute-toggle") { locked = true; repeating = true; })
      (bindWith "XF86MonBrightnessUp" (exec "swayosd-client --monitor DP-2 --brightness raise") { locked = true; repeating = true; })
      (bindWith "XF86MonBrightnessDown" (exec "swayosd-client --monitor DP-2 --brightness lower") { locked = true; repeating = true; })

      # Media keys (work even when locked)
      (bindWith "XF86AudioNext" (exec "playerctl next") { locked = true; })
      (bindWith "XF86AudioPause" (exec "playerctl play-pause") { locked = true; })
      (bindWith "XF86AudioPlay" (exec "playerctl play-pause") { locked = true; })
      (bindWith "XF86AudioPrev" (exec "playerctl previous") { locked = true; })
    ];
  };
}
