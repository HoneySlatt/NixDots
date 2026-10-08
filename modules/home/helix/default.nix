{ pkgs, ... }:

let
  helixWrapped = pkgs.symlinkJoin {
    name = "helix-wrapped";
    paths = [
      (pkgs.writeShellScriptBin "hx" ''
        if [ $# -eq 0 ]; then
          (sleep 0.2 && ${pkgs.wtype}/bin/wtype -k space -k f) &
        fi
        exec ${pkgs.helix}/bin/hx "$@"
      '')
      pkgs.helix
    ];
  };
in
{
  imports = [
    ./settings.nix
    ./languages.nix
    ./themes.nix
    ./activation.nix
  ];

  programs.helix = {
    enable = true;
    package = helixWrapped;
    settings.theme = "gruvbox_dark";
  };

  xdg.configFile."helix/config.toml".force = true;
}
