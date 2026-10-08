{ lib, pkgs, ... }:

let
  # Script name -> IpcHandler target in material/shell.qml
  ipcToggles = {
    toggle-bar-position = "togglePosition";
    toggle-launcher = "toggleLauncher";
    toggle-theme-launcher = "toggleThemeLauncher";
    toggle-wallpaper-launcher = "toggleWallpaperLauncher";
    toggle-game-launcher = "toggleSteamLauncher";
    toggle-music-launcher = "toggleMusicLauncher";
    toggle-vpn-launcher = "toggleVpnLauncher";
    toggle-power-launcher = "togglePowerMenu";
  };

  # Script whose body lives in ./bin/<name>.sh
  fromFile = name: args: pkgs.writeShellApplication ({
    inherit name;
    text = builtins.readFile ./bin/${name}.sh;
  } // args);
in
{
  home.packages =
    lib.mapAttrsToList (name: target: pkgs.writeShellApplication {
      inherit name;
      text = "quickshell ipc -c material call ${target} call";
    }) ipcToggles
    ++ [
      # Installed Steam and Heroic games, for the game launcher
      (fromFile "steam-games" { runtimeInputs = with pkgs; [ jq coreutils ]; })

      # Theming of apps outside the shell
      (pkgs.writeShellApplication {
        name = "qs-compile-userstyle";
        runtimeInputs = [ pkgs.nodejs pkgs.lessc ];
        text = ''
          LESS_MODULE_PATH="${pkgs.lessc}/lib/lessc/packages/less" node "$HOME/.config/quickshell/themes/compile-userstyle.js" "$@"
        '';
      })
      (pkgs.writeShellApplication {
        name = "qs-userstyles-server";
        runtimeInputs = [ pkgs.python3 ];
        text = ''
          # Skip per-request logs (Cinny polls every 2s); errors are still logged
          exec python3 -c '
          import functools, http.server, sys
          class Handler(http.server.SimpleHTTPRequestHandler):
              def log_request(self, *args):
                  pass
          http.server.ThreadingHTTPServer(("127.0.0.1", 48531), functools.partial(Handler, directory=sys.argv[1])).serve_forever()
          ' "$HOME/.config/quickshell/themes"
        '';
      })
      (fromFile "switch-tuta-theme" { runtimeInputs = [ pkgs.jq ]; })
      (fromFile "switch-kopuz-theme" { runtimeInputs = with pkgs; [ jq gawk coreutils ]; })

      # NymVPN
      (pkgs.writeShellApplication {
        name = "toggle-nym";
        text = ''
          ${pkgs.bash}/bin/bash "$HOME/.config/quickshell/scripts/nym-vpn.sh" "$@"
        '';
      })
      (pkgs.writeShellApplication {
        name = "nym-countries";
        runtimeInputs = [ pkgs.jq ];
        text = ''
          NYM_ISO_3166="${pkgs.isocodes}/share/iso-codes/json/iso_3166-1.json" \
            ${pkgs.bash}/bin/bash "$HOME/.config/quickshell/scripts/nym-countries.sh"
        '';
      })

      # Session
      (fromFile "toggle-nsfw" { })
      (fromFile "wallpaper-rotation" {
        runtimeInputs = [ pkgs.jq ];
        # C is read by the sourced switch_wallpaper
        excludeShellChecks = [ "SC2034" ];
      })
      (fromFile "lock-screen" { })
      (fromFile "start-quickshell" { })
    ];
}
