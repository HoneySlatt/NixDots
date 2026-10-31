{ pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellApplication {
      # Kept for the existing shared application-theme dispatcher.
      name = "amane-compile-userstyle";
      runtimeInputs = [ pkgs.nodejs pkgs.lessc ];
      text = ''
        LESS_MODULE_PATH="${pkgs.lessc}/lib/lessc/packages/less" node "$HOME/.config/amane/themes/compile-userstyle.js" "$@"
      '';
    })
    (pkgs.writeShellApplication {
      name = "desktop-userstyles-server";
      runtimeInputs = [ pkgs.python3 ];
      text = ''
        exec python3 -c '
        import functools, http.server, sys
        class Handler(http.server.SimpleHTTPRequestHandler):
            def log_request(self, *args):
                pass
        http.server.ThreadingHTTPServer(("127.0.0.1", 48531), functools.partial(Handler, directory=sys.argv[1])).serve_forever()
        ' "$HOME/.config/amane/themes"
      '';
    })
    (pkgs.writeShellApplication {
      name = "switch-tuta-theme";
      runtimeInputs = [ pkgs.jq ];
      text = builtins.readFile ../amane/bin/switch-tuta-theme.sh;
    })
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
  ];
}
