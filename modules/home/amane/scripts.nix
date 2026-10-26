{ pkgs, ... }:

let
  ipcToggles = [
    "toggle-bar-position"
    "toggle-launcher"
    "toggle-theme-launcher"
    "toggle-wallpaper-launcher"
    "toggle-game-launcher"
    "toggle-vpn-launcher"
    "toggle-music-launcher"
    "toggle-power-launcher"
  ];

  # Script whose body lives in ./bin/<name>.sh
  fromFile = name: args: pkgs.writeShellApplication ({
    inherit name;
    text = builtins.readFile ./bin/${name}.sh;
  } // args);
in
{
  home.packages = map (name: pkgs.writeShellApplication {
    inherit name;
    text = ''
      exec amane ipc call ${name}
    '';
  }) ipcToggles ++ [
    # Installed Steam and Heroic games, for the game launcher
    (fromFile "steam-games" { runtimeInputs = with pkgs; [ jq coreutils ]; })

    # Theming of apps outside the shell
    (pkgs.writeShellApplication {
      name = "amane-compile-userstyle";
      runtimeInputs = [ pkgs.nodejs pkgs.lessc ];
      text = ''
        LESS_MODULE_PATH="${pkgs.lessc}/lib/lessc/packages/less" node "$HOME/.config/amane/themes/compile-userstyle.js" "$@"
      '';
    })
    (pkgs.writeShellApplication {
      name = "amane-userstyles-server";
      runtimeInputs = [ pkgs.python3 ];
      text = ''
        # Skip per-request logs; errors are still logged
        exec python3 -c '
        import functools, http.server, sys
        class Handler(http.server.SimpleHTTPRequestHandler):
            def log_request(self, *args):
                pass
        http.server.ThreadingHTTPServer(("127.0.0.1", 48531), functools.partial(Handler, directory=sys.argv[1])).serve_forever()
        ' "$HOME/.config/amane/themes"
      '';
    })
    (fromFile "switch-tuta-theme" { runtimeInputs = [ pkgs.jq ]; })

    # NymVPN
    (pkgs.writeShellApplication {
      name = "toggle-nym";
      text = ''
        ${pkgs.bash}/bin/bash "$HOME/.config/amane/scripts/nym-vpn.sh" "$@"
      '';
    })
    (pkgs.writeShellApplication {
      name = "nym-countries";
      runtimeInputs = [ pkgs.jq ];
      text = ''
        NYM_ISO_3166="${pkgs.isocodes}/share/iso-codes/json/iso_3166-1.json" \
          ${pkgs.bash}/bin/bash "$HOME/.config/amane/scripts/nym-countries.sh"
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
  ];
}
