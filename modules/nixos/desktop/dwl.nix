{ pkgs, ... }:

{
  # Session entry, its systemd target and portals; dwl is built with its configuration in
  # modules/home/dwl, so the session runs the user's build
  programs.dwl = {
    enable = true;
    package = pkgs.writeShellScriptBin "dwl" ''exec /etc/profiles/per-user/"$USER"/bin/dwl "$@"'';
  };
}
