{ pkgs, ... }:

{
  programs.umbriel.enable = true;

  environment.systemPackages = [ pkgs.xwayland ];

  xdg.portal = {
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.umbriel = {
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
    };
  };
}
