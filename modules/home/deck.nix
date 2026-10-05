{ config, pkgs, ... }:

{
  imports = [
    ./common.nix
    ./config/rio.nix
    ./zed
  ];

  home.packages = with pkgs; [
    quickshell
    brightnessctl
  ];

  xdg.configFile."quickshell".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/NixOS/modules/home/niri/quickshell/config";

  programs.niri.settings = {
    outputs."eDP-1" = {
      transform.rotation = 270;
      scale = 1.0;
    };

    input = {
      keyboard.xkb.layout = "ca";
      touch.map-to-output = "eDP-1";
    };

    cursor = {
      theme = "phinger-cursors-dark";
      size = 24;
    };

    layout = {
      gaps = 6;
      default-column-width = { proportion = 1.0; };
      focus-ring.enable = false;
    };

    prefer-no-csd = true;
    hotkey-overlay.skip-at-startup = true;

    spawn-at-startup = [
      { argv = [ "steam" "-silent" ]; }
      { argv = [ "qs" "-p" "${config.xdg.configHome}/quickshell/deck.qml" ]; }
    ];

    binds = {
      "Ctrl+Shift+T".action.spawn = "rio";
      "Mod+Q" = {
        action.close-window = { };
        repeat = false;
      };
      "Mod+H".action.focus-column-left = { };
      "Mod+L".action.focus-column-right = { };
      "Mod+Tab".action.toggle-overview = { };
      "Mod+F".action.maximize-column = { };

      # Back to Gaming Mode
      "Mod+Shift+Escape" = {
        action.quit.skip-confirmation = true;
        repeat = false;
      };

      "XF86AudioRaiseVolume" = {
        action.spawn = [ "wpctl" "set-volume" "-l" "1.0" "@DEFAULT_AUDIO_SINK@" "5%+" ];
        allow-when-locked = true;
      };
      "XF86AudioLowerVolume" = {
        action.spawn = [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-" ];
        allow-when-locked = true;
      };
      "XF86AudioMute" = {
        action.spawn = [ "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle" ];
        allow-when-locked = true;
      };
    };
  };
}
