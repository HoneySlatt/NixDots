{ lib, pkgs, ... }:

let
  pluto = pkgs.writeShellScript "pluto" ''
    export LD_LIBRARY_PATH=${lib.makeLibraryPath (with pkgs; [ vulkan-loader libGL wayland libxkbcommon libx11 libxcursor libxi libxrandr dbus ])}
    token="''${XDG_CONFIG_HOME:-$HOME/.config}/pluto/token"
    if [ -r "$token" ]; then
      set -- --token-file "$token"
    fi
    exec "$HOME/.t3/projects/t3-code-rust/target/release/pluto" --server http://127.0.0.1:3774 "$@"
  '';
  magnolia = pkgs.writeShellScript "magnolia" ''
    export LD_LIBRARY_PATH=${lib.makeLibraryPath (with pkgs; [ libGL libxkbcommon wayland systemd dbus libx11 libxcursor libxi libxrandr ])}
    exec "$HOME/Projects/Magnolia/target/release/magnolia" "$@"
  '';
  # On-screen display drawn by the amane shell
  osd = args: {
    action = "spawn amane ipc call osd ${args}";
    allow_when_locked = true;
  };
  media = command: {
    action = "spawn playerctl ${command}";
    allow_when_locked = true;
  };
in
{
  programs.umbriel.settings.hot_corners.top_left = {
    enabled = true;
    delay_ms = 0;
    action = "overview-toggle";
  };

  programs.umbriel.settings.keybinds = {
    "Ctrl+Shift+T" = "spawn ghostty +new-window";
    "Mod+Shift+E" = "spawn nautilus";
    "Mod+E" = "spawn ghostty +new-window -e yazi";
    "Mod+Space" = "spawn toggle-launcher";
    "Mod+T" = "spawn toggle-theme-launcher";
    "Mod+W" = "spawn toggle-wallpaper-launcher";
    "Mod+G" = "spawn toggle-game-launcher";
    "Mod+M" = "spawn music-app";
    "Mod+P" = "spawn toggle-power-launcher";
    "Mod+Shift+W" = "spawn toggle-bar-position";
    "Mod+Shift+V" = "spawn toggle-nym";
    "Mod+Ctrl+V" = "spawn toggle-vpn-launcher";
    "Mod+U" = "spawn toggle-nsfw";
    "Mod+S" = "spawn amane ipc call screenshot";
    "Mod+Shift+S" = "spawn amane ipc call screenshot save";
    "Mod+Shift+Escape" = { action = "session-quit"; repeat = false; };
    "Mod+B" = "spawn brave-origin";
    "Mod+Shift+B" = "spawn firefox";
    "Mod+Shift+M" = "spawn kopuz";
    "Mod+Ctrl+M" = "spawn cider-2";
    "Mod+Shift+P" = "spawn hyprpicker";
    "Mod+D" = "spawn serein";
    "Mod+Shift+D" = "spawn element-desktop";
    "Ctrl+Shift+M" = "spawn tutanota-desktop --no-sandbox %U";
    "Mod+Ctrl+N" = "spawn ${magnolia}";
    "Mod+Shift+G" = "spawn slatty-gui";
    "Mod+Ctrl+G" = "spawn sh -c 'cd ~/Projects/SlattyLauncher && nix develop -c ./target/debug/slatty-gui'";
    "Mod+C" = "spawn ${pluto}";
    "Mod+I" = "spawn claude-desktop";
    "Mod+Shift+C" = "spawn chatgpt";
    "Mod+O" = "spawn obsidian";
    "Mod+N" = "spawn ghostty +new-window -e nvim";
    "Mod+Shift+N" = "spawn zeditor";
    "Ctrl+Alt+Delete" = "spawn ghostty +new-window -e btop";

    "Mod+Q" = { action = "window-close"; repeat = false; };
    "Mod+Escape" = { action = "spawn lock-screen"; repeat = false; };
    "Mod+Ctrl+Escape" = { action = "shortcuts-inhibit-toggle"; allow_when_inhibited = true; repeat = false; };

    "XF86AudioRaiseVolume" = osd "volume up";
    "XF86AudioLowerVolume" = osd "volume down";
    "XF86AudioMute" = osd "volume mute";
    "XF86AudioMicMute" = osd "microphone mute";
    "XF86AudioPause" = media "play-pause";
    "XF86AudioPlay" = media "play-pause";
    "XF86AudioNext" = media "next";
    "XF86AudioPrev" = media "previous";
    "XF86MonBrightnessUp" = osd "brightness up";
    "XF86MonBrightnessDown" = osd "brightness down";

    "Mod+Left" = "window-focus-left";
    "Mod+Down" = "window-focus-down";
    "Mod+Up" = "window-focus-up";
    "Mod+Right" = "window-focus-right";
    "Mod+H" = "window-focus-left";
    "Mod+J" = "workspace-next";
    "Mod+Ctrl+J" = "window-focus-down";
    "Mod+K" = "workspace-previous";
    "Mod+Ctrl+K" = "window-focus-up";
    "Mod+L" = "window-focus-right";
    "Mod+F1" = "window-focus-next";
    "Mod+Shift+Left" = "column-move-left";
    "Mod+Shift+Down" = "window-move-down";
    "Mod+Shift+Up" = "window-move-up";
    "Mod+Shift+Right" = "column-move-right";

    "Mod+V" = { action = "window-toggle-floating"; repeat = false; };
    "Mod+Shift+T" = { action = "window-focus-switch-floating"; repeat = false; };
    "Mod+Alt+P" = { action = "window-toggle-pinned"; repeat = false; };
    "Mod+Alt+M" = { action = "window-toggle-maximize-to-edges"; repeat = false; };
    "Mod+F" = { action = "window-toggle-maximize"; repeat = false; };
    "Mod+Shift+F" = { action = "window-toggle-fullscreen"; repeat = false; };
    "Mod+Ctrl+F" = { action = "window-toggle-maximize"; repeat = false; };
    "Mod+R" = "window-cycle-primary-extent";
    "Mod+Shift+R" = "window-cycle-primary-extent-back";
    "Mod+Ctrl+Shift+R" = "window-cycle-secondary-extent";
    "Mod+Minus" = "window-modify-primary-extent -0.1";
    "Mod+Equal" = "window-modify-primary-extent 0.1";
    "Mod+Shift+Minus" = "window-modify-secondary-extent -0.1";
    "Mod+Shift+Equal" = "window-modify-secondary-extent 0.1";
    "Mod+Shift+H" = "column-move-left";
    "Mod+Shift+L" = "column-move-right";
    "Mod+Ctrl+Shift+K" = "window-move-up";
    "Mod+Ctrl+Shift+J" = "window-move-down";
    "Mod+Shift+K" = "window-move-to-workspace-previous";
    "Mod+Shift+J" = "window-move-to-workspace-next";
    "Mod+Comma" = "window-consume-left";
    "Mod+Period" = "window-consume-right";
    "Mod+Ctrl+Comma" = "window-consume-from-left";
    "Mod+Ctrl+Period" = "window-consume-from-right";
    "Mod+Alt+W" = { action = "column-toggle-tabbed"; repeat = false; };
    "Mod+Alt+Right" = "column-focus-tab-next";
    "Mod+Alt+Left" = "column-focus-tab-previous";
    "Mod+WheelUp" = "workspace-previous";
    "Mod+WheelDown" = "workspace-next";
    "Mod+Tab" = { action = "overview-toggle"; repeat = false; };
    "Mod+Ctrl+S" = { action = "workspace-set-layout toggle"; repeat = false; };

    "Mod+1" = "workspace-switch --name 1 --output DP-2";
    "Mod+2" = "workspace-switch --name 2 --output DP-3";
    "Mod+3" = "workspace-switch --name 3 --output DP-2";
    "Mod+4" = "workspace-switch --name 4 --output DP-3";
    "Mod+5" = "workspace-switch --name 5 --output DP-2";
    "Mod+6" = "workspace-switch --name 6 --output DP-3";
    "Mod+7" = "workspace-switch --name 7 --output DP-2";
    "Mod+8" = "workspace-switch --name 8 --output DP-3";
    "Mod+9" = "workspace-switch --name 9 --output DP-2";
    "Mod+Shift+1" = "window-move-to-workspace --name 1 --output DP-2";
    "Mod+Shift+2" = "window-move-to-workspace --name 2 --output DP-3";
    "Mod+Shift+3" = "window-move-to-workspace --name 3 --output DP-2";
    "Mod+Shift+4" = "window-move-to-workspace --name 4 --output DP-3";
    "Mod+Shift+5" = "window-move-to-workspace --name 5 --output DP-2";
    "Mod+Shift+6" = "window-move-to-workspace --name 6 --output DP-3";
    "Mod+Shift+7" = "window-move-to-workspace --name 7 --output DP-2";
    "Mod+Shift+8" = "window-move-to-workspace --name 8 --output DP-3";
    "Mod+Shift+9" = "window-move-to-workspace --name 9 --output DP-2";

    "Mod+0" = "workspace-switch --name 10 --output DP-3";
    "Mod+Shift+0" = "window-move-to-workspace --name 10 --output DP-3";

    "Mod+Shift+Space" = { action = "window-move-to-scratchpad"; repeat = false; };
    "Mod+Ctrl+Space" = { action = "window-restore-from-scratchpad"; repeat = false; };
  };
}
