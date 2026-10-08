{ config, lib, ... }:

let
  icons = "${config.home.homeDirectory}/Pictures/Icons";

  imageTypes = [ "image/jpeg" "image/png" "image/gif" "image/webp" "image/avif" "image/bmp" "image/tiff" "image/svg+xml" ];
  mediaTypes = [
    "video/mp4" "video/x-matroska" "video/webm" "video/x-msvideo" "video/quicktime" "video/x-flv"
    "audio/mpeg" "audio/flac" "audio/ogg" "audio/x-wav"
  ];
  textTypes = [
    "text/plain" "text/x-shellscript" "text/x-python" "text/x-csrc" "text/x-chdr" "text/x-c++src"
    "text/x-lua" "text/x-rust" "text/x-go" "text/x-java" "text/css" "text/javascript"
    "application/json" "application/x-yaml" "application/x-shellscript"
  ];
  webTypes = [
    "text/html" "x-scheme-handler/http" "x-scheme-handler/https" "x-scheme-handler/ftp"
    "x-scheme-handler/about" "x-scheme-handler/unknown" "application/xhtml+xml"
    "application/x-extension-htm" "application/x-extension-html" "application/x-extension-xhtml"
  ];

  # Hidden overrides of the per-app LibreOffice entries
  libreoffice = lib.mapAttrs (app: { name, categories }: {
    name      = "LibreOffice ${name}";
    exec      = "libreoffice --${app} %U";
    icon      = "libreoffice-${app}";
    noDisplay = true;
    inherit categories;
  }) {
    writer  = { name = "Writer";  categories = [ "Office" "WordProcessor" ]; };
    calc    = { name = "Calc";    categories = [ "Office" "Spreadsheet" ]; };
    impress = { name = "Impress"; categories = [ "Office" "Presentation" ]; };
    draw    = { name = "Draw";    categories = [ "Office" "Graphics" ]; };
    math    = { name = "Math";    categories = [ "Office" ]; };
    base    = { name = "Base";    categories = [ "Office" "Database" ]; };
  };
in
{
  xdg.desktopEntries = libreoffice // {

    # ─── Desktop Apps ────────────────────────────────────────────────────────

    "brave-origin" = {
      name       = "Brave Origin";
      exec       = "brave-origin %U";
      icon       = "brave-origin";
      comment    = "Web browser";
      categories = [ "Network" "WebBrowser" ];
    };

    mpv = {
      name       = "MPV";
      exec       = "mpv --player-operation-mode=pseudo-gui -- %U";
      icon       = "mpv";
      comment    = "Free and open source media player";
      mimeType   = mediaTypes;
      noDisplay  = true;
      categories = [ "AudioVideo" "Video" ];
    };

    "moe.tsuna.tsukimi" = {
      name       = "Tsukimi";
      exec       = "tsukimi";
      icon       = "org.jellyfin.JellyfinDesktop";
      comment    = "Jellyfin client";
      categories = [ "AudioVideo" "Video" ];
    };

    gimp = {
      name       = "GIMP";
      exec       = "gimp %U";
      icon       = "gimp";
      comment    = "GNU Image Manipulation Program";
      mimeType   = [ "image/jpeg" "image/png" "image/gif" "image/webp" "image/bmp" "image/tiff" "image/x-xcf" ];
      categories = [ "Graphics" "2DGraphics" "RasterGraphics" ];
    };

    "tutanota-desktop" = {
      name       = "Tuta Mail";
      exec       = "tutanota-desktop --no-sandbox %U";
      icon       = "${icons}/tuta.png";
      comment    = "Encrypted email client";
      categories = [ "Network" "Email" ];
    };

    startcenter = {
      name       = "LibreOffice";
      exec       = "libreoffice %U";
      icon       = "libreoffice-startcenter";
      comment    = "LibreOffice start center";
    };

    "rqbit-desktop" = {
      name       = "rqbit";
      exec       = "rqbit-desktop";
      icon       = "/home/honey/Pictures/Icons/rqbit.png";
      comment    = "BitTorrent client";
      categories = [ "Network" "FileTransfer" "P2P" ];
    };

    steam = {
      name       = "Steam";
      exec       = "steam %U";
      icon       = "steam";
      comment    = "Steam game client";
      categories = [ "Game" ];
    };

    "com.heroicgameslauncher.hgl" = {
      name       = "Heroic Games Launcher";
      exec       = "heroic %U";
      icon       = "com.heroicgameslauncher.hgl";
      comment    = "Open source launcher for GOG, Epic Games and Amazon Games";
      mimeType   = [ "x-scheme-handler/heroic" ];
      categories = [ "Game" ];
    };

    "org.prismlauncher.PrismLauncher" = {
      name       = "Minecraft";
      exec       = "prismlauncher";
      icon       = "${icons}/minecrafths.png";
      comment    = "Minecraft launcher";
      categories = [ "Game" ];
    };

    xivlauncher = {
      name       = "Final Fantasy XIV Online";
      exec       = "XIVLauncher.Core";
      icon       = "${icons}/ffxiv.png";
      comment    = "Final Fantasy XIV launcher";
      categories = [ "Game" ];
    };

    win11 = {
      name       = "Windows 11";
      exec       = "virsh -c qemu:///system start win11";
      icon       = "${icons}/win11.png";
      comment    = "Windows 11 VM with GPU passthrough";
      categories = [ "Game" "System" ];
    };

    nixos-manual = {
      name       = "NixOS";
      exec       = "nixos-help";
      icon       = "nix-snowflake";
      comment    = "NixOS documentation";
      categories = [ "System" "Documentation" ];
    };

    "com.system76.CosmicFiles" = {
      name       = "Files";
      exec       = "cosmic-files %U";
      icon       = "com.system76.CosmicFiles";
      comment    = "File manager";
      mimeType   = [ "inode/directory" ];
      categories = [ "Utility" "FileManager" ];
    };

    rio = {
      name       = "Rio";
      exec       = "rio";
      icon       = "/home/honey/Pictures/Icons/rio.png";
      comment    = "A terminal emulator";
      categories = [ "System" "TerminalEmulator" ];
    };

    # ─── TUI / CLI Tools ─────────────────────────────────────────────────────

    nvim = {
      name       = "Neovim";
      exec       = "rio -e nvim %F";
      icon       = "nvim";
      comment    = "Hyperextensible Vim-based text editor";
      categories = [ "Utility" "TextEditor" ];
    };

    yazi = {
      name       = "Yazi";
      exec       = "rio -e yazi %F";
      icon       = "${icons}/yazi.png";
      comment    = "Blazing fast terminal file manager";
      noDisplay  = true;
      categories = [ "System" "FileManager" ];
    };

    # ─── Others (hidden overrides) ───────────────────────────────────────────

    "com.system76.CosmicViewer" = {
      name       = "COSMIC Viewer";
      exec       = "cosmic-viewer %F";
      icon       = "com.system76.CosmicViewer";
      comment    = "View and annotate images";
      mimeType   = imageTypes;
      noDisplay  = true;
      categories = [ "Graphics" "Viewer" ];
    };

    btop = {
      name       = "Btop";
      exec       = "rio -e btop";
      icon       = "btop";
      comment    = "Resource monitor";
      noDisplay  = true;
      categories = [ "System" "Monitor" ];
    };

    "virt-manager" = {
      name       = "Virtual Machine Manager";
      exec       = "virt-manager";
      icon       = "virt-manager";
      comment    = "Manage virtual machines";
      noDisplay  = true;
      categories = [ "System" ];
    };

    "com.vysp3r.ProtonPlus" = {
      name       = "ProtonPlus";
      exec       = "protonplus";
      icon       = "com.vysp3r.ProtonPlus";
      comment    = "A modern compatibility tools manager";
      noDisplay  = true;
      categories = [ "Game" "Utility" ];
    };

    protontricks = {
      name       = "Protontricks";
      exec       = "protontricks --no-term --gui";
      icon       = "wine";
      comment    = "Winetricks wrapper for Proton games";
      noDisplay  = true;
      categories = [ "Game" "Utility" ];
    };

    umpv = {
      name       = "umpv";
      exec       = "umpv %U";
      icon       = "mpv";
      noDisplay  = true;
      categories = [ "AudioVideo" "Video" ];
    };

    "io.github.ilya_zlobintsev.LACT" = {
      name       = "LACT";
      exec       = "lact gui";
      icon       = "io.github.ilya_zlobintsev.LACT";
      noDisplay  = true;
      categories = [ "System" "Settings" ];
    };

    kvantummanager = {
      name       = "Kvantum Manager";
      exec       = "kvantummanager";
      icon       = "kvantummanager";
      noDisplay  = true;
      categories = [ "Settings" ];
    };

    qt5ct = {
      name       = "Qt5 Settings";
      exec       = "qt5ct";
      icon       = "preferences-desktop-theme";
      noDisplay  = true;
      categories = [ "Settings" "DesktopSettings" ];
    };

    qt6ct = {
      name       = "Qt6 Settings";
      exec       = "qt6ct";
      icon       = "preferences-desktop-theme";
      noDisplay  = true;
      categories = [ "Settings" "DesktopSettings" ];
    };

    xsltfilter = {
      name       = "LibreOffice XSLT Filter";
      exec       = "libreoffice";
      icon       = "libreoffice-startcenter";
      noDisplay  = true;
      categories = [ "Office" ];
    };
  };

  xdg.configFile."mimeapps.list".force = true;

  xdg.mimeApps = {
    enable = true;
    defaultApplications =
      lib.genAttrs imageTypes (_: "com.system76.CosmicViewer.desktop")
      // lib.genAttrs mediaTypes (_: "mpv.desktop")
      // lib.genAttrs textTypes (_: "nvim.desktop")
      // lib.genAttrs webTypes (_: "brave-origin.desktop")
      // {
        "x-scheme-handler/tuta" = "tutanota-desktop.desktop";
        "inode/directory" = "com.system76.CosmicFiles.desktop";
      };
  };
}
