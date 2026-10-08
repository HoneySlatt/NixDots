{ config, pkgs, ... }:

{
  services.displayManager = {
    gdm = {
      enable = true;
      # The desktop also serves the NAS: never suspend while waiting at the login screen
      autoSuspend = false;
    };
    defaultSession = "niri";
  };

  # Login screen keyboard, same layout as the niri session
  services.xserver.xkb.layout = "ca";

  # NixOS logo at the bottom of the login screen
  programs.dconf.profiles.gdm.databases = [
    {
      settings."org/gnome/login-screen".logo =
        "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake-white.svg";
    }
  ];

  # Logging in with the password also unlocks the GNOME keyring
  security.pam.services.login.enableGnomeKeyring = true;

  # Login screen avatar, stored by AccountsService like GNOME Settings would do.
  # Copied from the home folder at every boot, which the gdm user cannot read.
  systemd.tmpfiles.rules =
    let
      accounts = "/var/lib/AccountsService";
    in
    [
      "d ${accounts}/icons 0775 root root -"
      "d ${accounts}/users 0700 root root -"
      "C+ ${accounts}/icons/honey 0644 root root - ${config.users.users.honey.home}/Pictures/Others/Honey.png"
      "f ${accounts}/users/honey 0600 root root - [User]\\nIcon=${accounts}/icons/honey\\n"
    ];
}
