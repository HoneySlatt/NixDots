{ config, lib, pkgs, ... }:

{
  home.username = "honey";
  home.homeDirectory = "/home/honey";
  home.stateVersion = "25.11";

  home.pointerCursor = {
    enable = true;
    package = pkgs.phinger-cursors;
    name = "phinger-cursors-dark";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };
    gtk4.theme = null;
  };

  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      sansSerif = [ "Google Sans Flex" "Symbols Nerd Font Mono" ];
      monospace = [ "Google Sans Code" "Symbols Nerd Font Mono" ];
    };
  };
  # Apps asking for the native UI font (-apple-system, Segoe UI, system-ui...)
  # otherwise fall through to Helvetica/Arial clones.
  xdg.configFile."fontconfig/conf.d/60-system-ui-fonts.conf".text =
    let
      alias = font: family: ''
        <alias binding="same"><family>${family}</family><prefer><family>${font}</family></prefer></alias>
      '';
      sans = [ "system-ui" "ui-sans-serif" "-apple-system" "BlinkMacSystemFont" "Segoe UI" "SF Pro Text" "SF Pro Display" ];
      mono = [ "ui-monospace" "SFMono-Regular" "SF Mono" "Menlo" "Consolas" ];
    in
    ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
      <fontconfig>
      ${lib.concatMapStrings (alias "Google Sans Flex") sans}${lib.concatMapStrings (alias "Google Sans Code") mono}</fontconfig>
    '';

  home.packages = with pkgs; [
    (callPackage ./pkgs/google-sans.nix { })
    material-symbols
    nerd-fonts.symbols-only
    nerd-fonts.iosevka-term
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.home-manager.enable = true;
}
