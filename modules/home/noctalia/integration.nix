{ pkgs, ... }:

let
  palettes = pkgs.runCommand "amane-noctalia-palettes" {
    nativeBuildInputs = [ pkgs.python3 pkgs.bash ];
  } ''
    python ${./palettes.py} ${../amane/config/themes/themes.conf} ${../amane/config/themes/themes.json} $out
  '';
in
{
  xdg.configFile."noctalia/palettes".source = palettes;
  xdg.dataFile."noctalia/plugins/desktop".source = ./plugin;

  home.packages = [
    (pkgs.writeShellApplication {
      name = "noctalia-desktop";
      runtimeInputs = [ pkgs.python3 pkgs.bash pkgs.jq pkgs.grpcurl pkgs.coreutils ];
      text = ''
        exec python3 ${./desktop.py} "$@"
      '';
    })
    (pkgs.writeShellApplication {
      name = "noctalia-desktop-library";
      runtimeInputs = [ pkgs.python3 pkgs.grpcurl pkgs.curl ];
      text = ''
        exec python3 ${./library.py} "$@"
      '';
    })
  ];
}
