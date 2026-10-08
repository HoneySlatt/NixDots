{ pkgs, ... }:

{
  # qt5ct/qt6ct and Kvantum, configured at runtime by themes/apps/qt.sh
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
  };

  # Stock theme recolored by qt.sh, at a fixed path instead of searching the store
  xdg.dataFile."Kvantum/KvAdaptaDark".source =
    "${pkgs.qt6Packages.qtstyleplugin-kvantum}/share/Kvantum/KvAdaptaDark";

  home.packages = with pkgs; [
    jq
    nodejs
    lessc
    netcat-openbsd
    adw-gtk3
    kora-icon-theme
    glib
    gsettings-desktop-schemas
  ];
}
