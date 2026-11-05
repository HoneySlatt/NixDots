{ inputs, pkgs, ... }:

{
  programs.umbriel = {
    enable = true;
    # wlroots killed Amane when it hid a layer surface while a configure was on its way
    package = inputs.umbriel.packages.${pkgs.stdenv.hostPlatform.system}.default.override (prev: {
      wlroots_0_20 = prev.wlroots_0_20.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./umbriel-patches/wlroots-stale-layer-ack.patch ];
      });
    });
  };

  environment.systemPackages = [ pkgs.xwayland ];

  xdg.portal = {
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.umbriel = {
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
    };
  };
}
