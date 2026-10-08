{ config, ... }:

{
  # Theme, wallpaper and keyboard layout come from the user's COSMIC config,
  # written by modules/home/cosmic-greeter.nix and the theme switch
  services.displayManager.cosmic-greeter.enable = true;

  # Logging in with the password also unlocks the GNOME keyring (greetd includes login)
  security.pam.services.login.enableGnomeKeyring = true;

  # Login screen avatar, stored by AccountsService like GNOME Settings would do.
  # Copied from the home folder at every boot, which the greeter cannot read.
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
