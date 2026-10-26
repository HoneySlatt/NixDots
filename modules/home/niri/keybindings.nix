{ lib, pkgs, ... }:

let
  # The native T3 Code client (release build), with the libraries its shell
  # provides; it connects to the t3code-server user service, with the access
  # token from ~/.config/t3-code-rust/token when that file exists
  t3rust = pkgs.writeShellScript "t3rust" ''
    export LD_LIBRARY_PATH=${lib.makeLibraryPath (with pkgs; [ vulkan-loader libGL wayland libxkbcommon libx11 libxcursor libxi libxrandr dbus ])}
    token="''${XDG_CONFIG_HOME:-$HOME/.config}/t3-code-rust/token"
    if [ -r "$token" ]; then
      set -- --token-file "$token"
    fi
    exec "$HOME/.t3/projects/t3-code-rust/target/release/t3-code-rust" --server http://127.0.0.1:3773 "$@"
  '';
  screenshotSave = pkgs.writeShellScript "niri-screenshot-save" ''
    directory="$HOME/Pictures/Screenshots"
    ${pkgs.coreutils}/bin/mkdir -p "$directory"
    exec ${pkgs.niri}/bin/niri msg action screenshot --path "$directory/Screenshot from $(${pkgs.coreutils}/bin/date '+%Y-%m-%d %H-%M-%S').png"
  '';
  # On-screen display drawn by the amane shell
  osd = args: {
    action.spawn = [
      "amane"
      "ipc"
      "call"
      "osd"
    ]
    ++ args;
    allow-when-locked = true;
  };
  media = command: {
    action.spawn = [
      "playerctl"
      command
    ];
    allow-when-locked = true;
  };
  # Mod+1..9, Mod+0 for workspace 10
  workspaceBinds = lib.mergeAttrsList (
    map (
      i:
      let
        ws = toString i;
        key = toString (lib.mod i 10);
      in
      {
        "Mod+${key}".action.focus-workspace = ws;
        "Mod+Shift+${key}".action.move-window-to-workspace = ws;
      }
    ) (lib.range 1 10)
  );
in
{
  programs.niri.settings.binds = workspaceBinds // {
    # ── App launchers ────────────────────────────────────────────────────
    "Ctrl+Shift+T".action.spawn = "rio";
    "Mod+Q" = {
      action.close-window = { };
      repeat = false;
    };
    "Mod+Shift+E".action.spawn = "cosmic-files";
    "Mod+E".action.spawn = [
      "rio"
      "-e"
      "yazi"
    ];
    "Mod+V".action.toggle-window-floating = { };
    "Mod+Space".action.spawn = "toggle-launcher";
    "Mod+T".action.spawn = "toggle-theme-launcher";
    "Mod+W".action.spawn = "toggle-wallpaper-launcher";
    "Mod+G".action.spawn = "toggle-game-launcher";
    "Mod+P".action.spawn = "toggle-power-launcher";
    "Mod+Tab".action.toggle-overview = { };
    "Mod+B".action.spawn = "brave-origin";
    "Mod+Shift+B".action.spawn = "firefox";
    "Mod+M".action.spawn = "toggle-music-launcher";
    "Mod+Shift+M".action.spawn = "kopuz";
    "Mod+Ctrl+M".action.spawn = "cider-2";
    "Mod+Shift+W".action.spawn = "toggle-bar-position";
    "Mod+Shift+V".action.spawn = "toggle-nym";
    "Mod+Ctrl+V".action.spawn = "toggle-vpn-launcher";
    "Mod+U".action.spawn = "toggle-nsfw";
    "Mod+S".action.screenshot = { };
    "Mod+Shift+S".action.spawn = "${screenshotSave}";
    "Mod+Shift+P".action.spawn = "hyprpicker";
    "Mod+D".action.spawn = "serein";
    "Mod+Shift+D".action.spawn = "element-desktop";
    "Ctrl+Shift+M".action.spawn = [
      "tutanota-desktop"
      "--no-sandbox"
      "%U"
    ];
    "Mod+Ctrl+N".action.spawn = "nuvio";
    "Mod+Shift+G".action.spawn = "slatty-gui";
    # Slatty's development build, in its project's shell
    "Mod+Ctrl+G".action.spawn = [
      "sh"
      "-c"
      "cd ~/Projects/SlattyLauncher && nix develop -c ./target/debug/slatty-gui"
    ];
    "Mod+C".action.spawn = "${t3rust}";
    "Mod+I".action.spawn = "claude-desktop";
    "Mod+Shift+C".action.spawn = "chatgpt";
    "Mod+Ctrl+C".action.spawn = [ "opencode-desktop" ];
    "Mod+O".action.spawn = "obsidian";
    "Mod+N".action.spawn = "zeditor";
    "Mod+Shift+N".action.spawn = [
      "rio"
      "-e"
      "nvim"
    ];
    "Ctrl+Alt+Delete".action.spawn = [
      "rio"
      "-e"
      "btop"
    ];

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
    "XF86AudioRaiseVolume" = osd [
      "volume"
      "up"
    ];
    "XF86AudioLowerVolume" = osd [
      "volume"
      "down"
    ];
    "XF86AudioMute" = osd [
      "volume"
      "mute"
    ];
    "XF86AudioMicMute" = osd [
      "microphone"
      "mute"
    ];
    "XF86MonBrightnessUp" = osd [
      "brightness"
      "up"
    ];
    "XF86MonBrightnessDown" = osd [
      "brightness"
      "down"
    ];

    "XF86AudioNext" = media "next";
    "XF86AudioPause" = media "play-pause";
    "XF86AudioPlay" = media "play-pause";
    "XF86AudioPrev" = media "previous";
  };
}
