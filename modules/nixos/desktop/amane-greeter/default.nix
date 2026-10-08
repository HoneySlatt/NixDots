{ config, inputs, lib, pkgs, ... }:

# Login screen: greetd runs a bare niri that shows the amane greeter (./src), with the
# theme and wallpaper of the last session (copied by modules/home/amane/greeter.nix)

let
  user = "honey";
  data = "/var/lib/amane-greeter";
  niri = config.programs.niri.package;

  greeter = pkgs.callPackage ./package.nix {
    amane = import ../../../home/amane/package.nix { inherit inputs pkgs; };
  };

  # Same modes and scales as the session
  outputs = lib.concatStrings (
    lib.mapAttrsToList (name: output: ''
      output "${name}" {
          mode "${toString output.mode.width}x${toString output.mode.height}@${builtins.toJSON output.mode.refresh}"
          scale ${builtins.toJSON output.scale}
          position x=${toString output.position.x} y=${toString output.position.y}
      }
    '') config.home-manager.users.${user}.programs.niri.settings.outputs
  );

  start = pkgs.writeShellScript "amane-greeter-start" ''
    # HOME holds the copied theme and wallpaper, which the greeter user can only read
    HOME=${data} XDG_CACHE_HOME="''${XDG_RUNTIME_DIR:-/tmp}/cache" \
      AMANE_GREETER_USER=${user} AMANE_GREETER_OUTPUT=DP-2 \
      AMANE_GREETER_SESSIONS=${config.services.displayManager.sessionData.desktops}/share/wayland-sessions \
      ${greeter}/bin/amane-greeter

    # greetd starts the session once its greeter, this niri, is gone
    ${niri}/bin/niri msg action quit --skip-confirmation
  '';

  niriConfig = pkgs.writeText "amane-greeter-niri.kdl" ''
    ${outputs}
    input {
        keyboard {
            xkb {
                layout "ca"
            }
        }
    }

    cursor {
        xcursor-theme "phinger-cursors-dark"
        xcursor-size 24
    }

    hotkey-overlay {
        skip-at-startup
    }

    spawn-at-startup "${start}"
  '';
in
{
  services.greetd = {
    enable = true;
    settings.default_session.command = "${niri}/bin/niri -c ${niriConfig}";
  };

  # The greeter user has no home profile: its fonts and cursor come from the system
  fonts.packages = [ pkgs.google-sans pkgs.material-symbols ];
  environment.systemPackages = [ pkgs.phinger-cursors ];

  # Logging in with the password also unlocks the GNOME keyring (greetd includes login)
  security.pam.services.login.enableGnomeKeyring = true;

  systemd.tmpfiles.rules =
    let
      accounts = "/var/lib/AccountsService";
    in
    [
      # Written by the user's session, read by the greeter
      "d ${data} 0755 ${user} ${config.users.users.${user}.group} -"

      # Login screen avatar, stored by AccountsService like GNOME Settings would do.
      # Copied from the home folder at every boot, which the greeter cannot read.
      "d ${accounts}/icons 0775 root root -"
      "d ${accounts}/users 0700 root root -"
      "C+ ${accounts}/icons/${user} 0644 root root - ${config.users.users.${user}.home}/Pictures/Others/Honey.png"
      "f ${accounts}/users/${user} 0600 root root - [User]\\nIcon=${accounts}/icons/${user}\\n"
    ];
}
