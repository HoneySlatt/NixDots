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
in
{
  programs.umbriel.settings.keybinds = {
    "Ctrl+Shift+T" = "spawn ghostty +new-window";
    "Mod+Shift+E" = "spawn nautilus";
    "Mod+E" = "spawn ghostty +new-window -e yazi";
    "Mod+Space" = "spawn noctalia msg panel-toggle launcher";
    "Mod+T" = "spawn noctalia msg panel-toggle local/desktop:themes";
    "Mod+W" = "spawn noctalia msg panel-toggle wallpaper";
    "Mod+G" = "spawn noctalia msg panel-toggle local/desktop:games";
    "Mod+M" = "spawn noctalia msg panel-toggle local/desktop:music";
    "Mod+P" = "spawn noctalia msg panel-toggle session";
    "Mod+Shift+W" = "spawn noctalia-desktop bar";
    "Mod+Shift+V" = "spawn toggle-nym";
    "Mod+Ctrl+V" = "spawn noctalia msg panel-toggle local/desktop:vpn";
    "Mod+U" = "spawn noctalia-desktop nsfw";
    "Mod+S" = "spawn noctalia msg screenshot-region --copy-to-clipboard --no-save-to-file";
    "Mod+Shift+S" = "spawn noctalia msg screenshot-region --save-to-file --no-copy-to-clipboard";
    "Mod+Shift+Escape" = { action = "session-quit"; repeat = false; };
    "Mod+B" = "spawn brave-origin";
    "Mod+Shift+B" = "spawn firefox";
    "Mod+Shift+M" = "spawn kopuz";
    "Mod+Ctrl+M" = "spawn cider-2";
    "Mod+Shift+P" = "spawn hyprpicker";
    "Mod+D" = "spawn serein";
    "Mod+Shift+D" = "spawn element-desktop";
    "Ctrl+Shift+M" = "spawn tutanota-desktop --no-sandbox %U";
    "Mod+Ctrl+N" = "spawn nuvio";
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
    "Mod+Escape" = { action = "spawn noctalia msg session lock"; repeat = false; };
    "Mod+Ctrl+Escape" = { action = "shortcuts-inhibit-toggle"; allow_when_inhibited = true; repeat = false; };

    "XF86AudioRaiseVolume" = { action = "spawn noctalia msg volume-up"; allow_when_locked = true; };
    "XF86AudioLowerVolume" = { action = "spawn noctalia msg volume-down"; allow_when_locked = true; };
    "XF86AudioMute" = { action = "spawn noctalia msg volume-mute"; allow_when_locked = true; repeat = false; };
    "XF86AudioMicMute" = { action = "spawn noctalia msg mic-mute"; allow_when_locked = true; repeat = false; };
    "XF86AudioPause" = { action = "spawn noctalia msg media toggle"; allow_when_locked = true; repeat = false; };
    "XF86AudioPlay" = { action = "spawn noctalia msg media toggle"; allow_when_locked = true; repeat = false; };
    "XF86AudioNext" = { action = "spawn noctalia msg media next"; allow_when_locked = true; };
    "XF86AudioPrev" = { action = "spawn noctalia msg media previous"; allow_when_locked = true; };
    "XF86MonBrightnessUp" = { action = "spawn noctalia msg brightness-up"; allow_when_locked = true; };
    "XF86MonBrightnessDown" = { action = "spawn noctalia msg brightness-down"; allow_when_locked = true; };

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
