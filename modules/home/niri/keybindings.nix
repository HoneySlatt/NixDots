{ ... }:

{
  programs.niri.settings.binds = {
    # ── App launchers ────────────────────────────────────────────────────
    "Ctrl+Shift+T".action.spawn = "rio";
    "Mod+Q" = {
      action.close-window = { };
      repeat = false;
    };
    "Mod+E".action.spawn = [ "rio" "-e" "yazi" ];
    "Mod+Shift+E".action.spawn = "nautilus";
    "Mod+V".action.toggle-window-floating = { };
    "Mod+Space".action.spawn = "toggle-launcher";
    "Mod+T".action.spawn = "toggle-theme-launcher";
    "Mod+W".action.spawn = "toggle-wallpaper-launcher";
    "Mod+G".action.spawn = "toggle-game-launcher";
    "Mod+Alt+M".action.spawn = "toggle-music-launcher";
    "Mod+P".action.spawn = "toggle-power-launcher";
    "Mod+Tab".action.toggle-overview = { };
    "Mod+B".action.spawn = "brave-origin";
    "Mod+Shift+B".action.spawn = "firefox";
    "Mod+M".action.spawn = "cider-2";
    "Mod+Shift+M".action.spawn = "kopuz";
    "Mod+Shift+W".action.spawn = "toggle-bar-position";
    "Mod+Shift+V".action.spawn = "toggle-nym";
    "Mod+Ctrl+V".action.spawn = "toggle-vpn-launcher";
    "Mod+U".action.spawn = "toggle-nsfw";
    "Mod+S".action.screenshot = { };
    "Mod+Shift+P".action.spawn = "hyprpicker";
    "Mod+D".action.spawn = "cinny";
    "Mod+Shift+D".action.spawn = "discord";
    "Ctrl+Shift+M".action.spawn = [ "tutanota-desktop" "--no-sandbox" "%U" ];
    "Mod+Ctrl+N".action.spawn = "jellyfin-desktop";
    "Mod+Shift+G".action.spawn = "heroic";
    "Mod+Ctrl+G".action.spawn = "steam";
    "Mod+C".action.spawn = "claude-desktop";
    "Mod+Shift+C".action.spawn = "chatgpt";
    "Mod+Ctrl+C".action.spawn = [ "opencode-desktop" ];
    "Mod+O".action.spawn = "obsidian";
    "Mod+N".action.spawn = [ "rio" "-e" "nvim" ];
    "Mod+Shift+N".action.spawn = "zeditor";
    "Ctrl+Alt+Delete".action.spawn = [ "rio" "-e" "btop" ];

    # ── Focus / Move ─────────────────────────────────────────────────────
    "Mod+H".action.focus-column-left = { };
    "Mod+L".action.focus-column-right = { };
    "Mod+Ctrl+K".action.focus-window-up = { };
    "Mod+Ctrl+J".action.focus-window-down = { };

    "Mod+Shift+H".action.move-column-left = { };
    "Mod+Shift+L".action.move-column-right = { };
    "Mod+Ctrl+Shift+K".action.move-window-up = { };
    "Mod+Ctrl+Shift+J".action.move-window-down = { };

    # ── Workspaces up / down ─────────────────────────────────────────────
    "Mod+K".action.focus-workspace-up = { };
    "Mod+J".action.focus-workspace-down = { };
    "Mod+Shift+K".action.move-window-to-workspace-up = { };
    "Mod+Shift+J".action.move-window-to-workspace-down = { };
    "Mod+WheelScrollDown" = {
      action.focus-workspace-down = { };
      cooldown-ms = 150;
    };
    "Mod+WheelScrollUp" = {
      action.focus-workspace-up = { };
      cooldown-ms = 150;
    };

    # ── Workspaces 1-10 ──────────────────────────────────────────────────
    "Mod+1".action.focus-workspace = "1";
    "Mod+2".action.focus-workspace = "2";
    "Mod+3".action.focus-workspace = "3";
    "Mod+4".action.focus-workspace = "4";
    "Mod+5".action.focus-workspace = "5";
    "Mod+6".action.focus-workspace = "6";
    "Mod+7".action.focus-workspace = "7";
    "Mod+8".action.focus-workspace = "8";
    "Mod+9".action.focus-workspace = "9";
    "Mod+0".action.focus-workspace = "10";
    "Mod+Shift+1".action.move-window-to-workspace = "1";
    "Mod+Shift+2".action.move-window-to-workspace = "2";
    "Mod+Shift+3".action.move-window-to-workspace = "3";
    "Mod+Shift+4".action.move-window-to-workspace = "4";
    "Mod+Shift+5".action.move-window-to-workspace = "5";
    "Mod+Shift+6".action.move-window-to-workspace = "6";
    "Mod+Shift+7".action.move-window-to-workspace = "7";
    "Mod+Shift+8".action.move-window-to-workspace = "8";
    "Mod+Shift+9".action.move-window-to-workspace = "9";
    "Mod+Shift+0".action.move-window-to-workspace = "10";

    # ── Column / window sizing ───────────────────────────────────────────
    "Mod+F".action.maximize-column = { };
    "Mod+Shift+F".action.fullscreen-window = { };
    "Mod+R".action.switch-preset-column-width = { };
    "Mod+Shift+R".action.switch-preset-column-width-back = { };
    "Mod+Ctrl+Shift+R".action.switch-preset-window-height = { };
    "Mod+Minus".action.set-column-width = "-10%";
    "Mod+Equal".action.set-column-width = "+10%";
    "Mod+Shift+Minus".action.set-window-height = "-10%";
    "Mod+Shift+Equal".action.set-window-height = "+10%";

    # ── Quit / Lock ─────────────────────────────────────────────────────
    "Mod+Escape".action.spawn = "lock-screen";
    "Mod+Shift+Escape" = {
      action.quit = { };
      repeat = false;
    };

    # ── Media / Volume / Brightness ──────────────────────────────────────
    "XF86AudioRaiseVolume" = {
      action.spawn = [ "swayosd-client" "--monitor" "DP-2" "--output-volume" "raise" ];
      allow-when-locked = true;
    };
    "XF86AudioLowerVolume" = {
      action.spawn = [ "swayosd-client" "--monitor" "DP-2" "--output-volume" "lower" ];
      allow-when-locked = true;
    };
    "XF86AudioMute" = {
      action.spawn = [ "swayosd-client" "--monitor" "DP-2" "--output-volume" "mute-toggle" ];
      allow-when-locked = true;
    };
    "XF86AudioMicMute" = {
      action.spawn = [ "swayosd-client" "--monitor" "DP-2" "--input-volume" "mute-toggle" ];
      allow-when-locked = true;
    };
    "XF86MonBrightnessUp" = {
      action.spawn = [ "swayosd-client" "--monitor" "DP-2" "--brightness" "raise" ];
      allow-when-locked = true;
    };
    "XF86MonBrightnessDown" = {
      action.spawn = [ "swayosd-client" "--monitor" "DP-2" "--brightness" "lower" ];
      allow-when-locked = true;
    };

    "XF86AudioNext" = {
      action.spawn = [ "playerctl" "next" ];
      allow-when-locked = true;
    };
    "XF86AudioPause" = {
      action.spawn = [ "playerctl" "play-pause" ];
      allow-when-locked = true;
    };
    "XF86AudioPlay" = {
      action.spawn = [ "playerctl" "play-pause" ];
      allow-when-locked = true;
    };
    "XF86AudioPrev" = {
      action.spawn = [ "playerctl" "previous" ];
      allow-when-locked = true;
    };
  };
}
