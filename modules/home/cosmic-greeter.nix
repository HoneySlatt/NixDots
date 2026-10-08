{ config, pkgs, ... }:

# User settings read by the COSMIC greeter (modules/nixos/desktop/cosmic-greeter.nix).
# The theme comes from themes/apps/cosmic.sh.

let
  # Login screen wallpaper: what awww currently shows on each output
  syncWallpaper = pkgs.writeShellApplication {
    name = "sync-greeter-wallpaper";
    runtimeInputs = [ pkgs.awww pkgs.gnused ];
    text = ''
      state="${config.xdg.stateHome}/cosmic/com.system76.CosmicBackground/v1"
      entries=$(awww query | sed -nE 's/^: ([^:]+): .*currently displaying: image: (.*)$/    ("\1", Path("\2")),/p')
      [ -n "$entries" ] || exit 0
      mkdir -p "$state"
      printf '[\n%s\n]\n' "$entries" > "$state/wallpapers"
    '';
  };
in
{
  xdg.configFile."cosmic/com.system76.CosmicComp/v1/xkb_config".text = ''
    (rules: "", model: "", layout: "ca", variant: "", options: None, repeat_delay: 600, repeat_rate: 25)
  '';

  # awww rewrites its per-output cache whenever a wallpaper is set
  systemd.user.paths.sync-greeter-wallpaper = {
    Unit.Description = "Watch the wallpaper for the login screen";
    Path.PathChanged = "${config.xdg.cacheHome}/awww/${pkgs.awww.version}";
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.sync-greeter-wallpaper = {
    Unit.Description = "Copy the current wallpaper to the login screen";
    Service = {
      Type = "oneshot";
      ExecStart = "${syncWallpaper}/bin/sync-greeter-wallpaper";
    };
  };
}
