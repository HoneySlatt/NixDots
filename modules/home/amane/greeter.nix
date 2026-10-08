{ config, pkgs, ... }:

# Hands the theme and the wallpaper to the login screen (modules/nixos/desktop/amane-greeter),
# which runs as another user and cannot read the home folder

let
  theme = "${config.xdg.configHome}/amane/.current-theme";

  sync = pkgs.writeShellApplication {
    name = "sync-greeter";
    runtimeInputs = with pkgs; [ awww coreutils gnused ];
    text = ''
      data=/var/lib/amane-greeter
      [ -w "$data" ] || exit 0

      # Copied then renamed, so the greeter never reads half a file
      put() {
        cp "$1" "$data/.incoming"
        chmod 644 "$data/.incoming"
        mv "$data/.incoming" "$2"
      }

      mkdir -p "$data/.config/amane"
      put "${theme}" "$data/.config/amane/.current-theme"

      wallpaper=$(awww query 2>/dev/null | sed -nE '1s/.*currently displaying: image: (.*)$/\1/p')
      if [ -n "$wallpaper" ] && [ "$wallpaper" != "$(cat "$data/wallpaper-source" 2>/dev/null)" ]; then
        put "$wallpaper" "$data/wallpaper"
        printf '%s\n' "$wallpaper" > "$data/wallpaper-source"
      fi
    '';
  };
in
{
  # awww rewrites its per-output cache whenever a wallpaper is set
  systemd.user.paths.sync-greeter = {
    Unit.Description = "Watch the theme and wallpaper for the login screen";
    Path.PathChanged = [ theme "${config.xdg.cacheHome}/awww/${pkgs.awww.version}" ];
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.sync-greeter = {
    Unit.Description = "Copy the theme and wallpaper to the login screen";
    Service = {
      Type = "oneshot";
      ExecStart = "${sync}/bin/sync-greeter";
    };
  };
}
