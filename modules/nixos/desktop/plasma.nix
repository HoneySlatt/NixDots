{ lib, pkgs, ... }:

{
  services.desktopManager.plasma6 = {
    enable = true;
    enableQt5Integration = false;
  };

  programs.kde-pim.enable = false;
  services.orca.enable = false;

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    # Use the applications already installed for the other sessions
    ark
    dolphin
    dolphin-plugins
    baloo-widgets
    elisa
    ffmpegthumbs
    gwenview
    kate
    ktexteditor
    khelpcenter
    konsole
    okular
    spectacle

    # Optional Plasma extras
    aurorae
    discover
    krdp
    kwin-x11
    plasma-browser-integration
    plasma-workspace-wallpapers
    plasma-keyboard
    qtvirtualkeyboard
    qrca
    qtsensors
    union
  ];

  # The shared Qt theme (qt6ct + Kvantum, see modules/home/amane/packages.nix) leaks into
  # Plasma: Kirigami looks for a "kvantum" QML style, which does not exist, so plasmashell
  # cannot load its wallpaper and desktop and the session stays black. Read by startplasma.
  environment.etc."xdg/plasma-workspace/env/qt-style.sh".text = ''
    export QT_QPA_PLATFORMTHEME=kde
    export QT_STYLE_OVERRIDE=breeze
    export QT_QUICK_CONTROLS_STYLE=org.kde.desktop
  '';

  # Use gnome-keyring (shared with the niri and hyprland sessions) as the only secret store:
  # keep kwallet out of the login and lock screen PAM stacks, and send the Secret portal to it
  security.pam.services.login.kwallet.enable = lib.mkForce false;
  security.pam.services.kde.kwallet.enable = lib.mkForce false;
  xdg.portal.config.kde."org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];

  # Plasma also adds browser integration independently of excludePackages
  programs.chromium.enablePlasmaBrowserIntegration = lib.mkForce false;
  programs.firefox.nativeMessagingHosts.packages = lib.mkForce [ ];
}
