{ config, inputs, pkgs, ... }:

{
  imports = [ inputs.noctalia-greeter.nixosModules.default ];

  services.displayManager.noctalia-greeter = {
    enable = true;
    settings = {
      session.default = "umbriel";
      user.default = "honey";
      appearance = {
        font_family = "Geist";
        theme_mode = "dark";
        password_style = "default";
      };
      clock.time_format = "{:%H:%M}";
      keyboard.layout = "ca";
      cursor = {
        theme = "phinger-cursors-dark";
        size = 24;
        path = "${pkgs.phinger-cursors}/share/icons";
      };
      output = {
        name = "DP-2";
        layout = "DP-2:0,0; DP-3:2560,0";
        scales = "DP-2:1.5; DP-3:1";
        refresh_rate = "DP-2:240; DP-3:180";
      };
    };
  };

  fonts.packages = [ pkgs.geist-font ];
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.noctalia = { };

  # Keep the account avatar used by the old greeter.
  systemd.tmpfiles.rules = [
    "d /var/lib/AccountsService/icons 0775 root root -"
    "d /var/lib/AccountsService/users 0700 root root -"
    "C+ /var/lib/AccountsService/icons/honey 0644 root root - ${config.users.users.honey.home}/Pictures/Others/Honey.png"
    "f /var/lib/AccountsService/users/honey 0600 root root - [User]\\nIcon=/var/lib/AccountsService/icons/honey\\n"
  ];

  environment.systemPackages = [ pkgs.xwayland ];
  xdg.portal = {
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.umbriel = {
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
    };
  };
}
