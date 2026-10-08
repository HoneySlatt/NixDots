{ pkgs, ... }:

{
  # qt5ct/qt6ct and Kvantum, configured at runtime by themes/apps/qt.sh
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
  };

  home.packages = with pkgs; [
    jq
    nodejs
    lessc
    netcat-openbsd
    adw-gtk3
    papirus-icon-theme
    glib
    gsettings-desktop-schemas
  ];
}
