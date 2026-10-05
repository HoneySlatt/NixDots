{ pkgs, ... }:

{
xdg.desktopEntries = {

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
      mimeType   = [ "video/mp4" "video/mkv" "video/x-matroska" "video/webm" "video/avi" "video/x-msvideo" "video/quicktime" "video/x-flv" "audio/mpeg" "audio/flac" "audio/ogg" "audio/x-wav" ];
      noDisplay = true;
      categories = [ "AudioVideo" "Video" ];
    };

    "org.jellyfin.JellyfinDesktop" = {
      name       = "Jellyfin";
      exec       = "jellyfin-desktop";
      icon       = "org.jellyfin.JellyfinDesktop";
      comment    = "Jellyfin desktop client";
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
      icon       = "/home/honey/Pictures/Icons/tuta.png";
      comment    = "Encrypted email client";
      categories = [ "Network" "Email" ];
    };

    startcenter = {
      name       = "LibreOffice";
      exec       = "libreoffice %U";
      icon       = "libreoffice-startcenter";
      comment    = "LibreOffice start center";
    };

    "org.qbittorrent.qBittorrent" = {
      name       = "qBittorrent";
      exec       = "qbittorrent %U";
      icon       = "org.qbittorrent.qBittorrent";
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
      icon       = "/home/honey/Pictures/Icons/minecrafths.png";
      comment    = "Minecraft launcher";
      categories = [ "Game" ];
    };

    xivlauncher = {
      name       = "Final Fantasy XIV Online";
      exec       = "XIVLauncher.Core";
      icon       = "/home/honey/Pictures/Icons/ffxiv.png";
      comment    = "Final Fantasy XIV launcher";
      categories = [ "Game" ];
    };

    nixos-manual = {
      name       = "NixOS";
      exec       = "nixos-help";
      icon       = "nix-snowflake";
      comment    = "NixOS documentation";
      categories = [ "System" "Documentation" ];
    };

    "com.mitchellh.ghostty" = {
      name       = "Ghostty";
      exec       = "ghostty +new-window";
      icon       = "com.mitchellh.ghostty";
      comment    = "A terminal emulator";
      categories = [ "System" "TerminalEmulator" ];
    };

    # ─── TUI / CLI Tools ─────────────────────────────────────────────────────

    nvim = {
      name       = "Neovim";
      exec       = "ghostty +new-window -e nvim %F";
      icon       = "nvim";
      comment    = "Hyperextensible Vim-based text editor";
      categories = [ "Utility" "TextEditor" ];
    };

    yazi = {
      name       = "Yazi";
      exec       = "ghostty +new-window -e yazi %F";
      icon       = "/home/honey/Pictures/Icons/yazi.png";
      comment    = "Blazing fast terminal file manager";
      noDisplay  = true;
      categories = [ "System" "FileManager" ];
    };

    # ─── Others (hidden overrides) ───────────────────────────────────────────

    "org.gnome.Nautilus" = {
      name       = "Files";
      exec       = "nautilus --new-window %U";
      icon       = "org.gnome.Nautilus";
      comment    = "Access and organize files";
      noDisplay  = true;
      categories = [ "GNOME" "GTK" "Utility" "Core" "FileManager" ];
    };

    "steam-metadata-editor" = {
      name       = "Steam Metadata Editor";
      exec       = "steam-metadata-editor";
      icon       = "steam-metadata-editor";
      comment    = "Edit metadata of your Steam apps";
      noDisplay  = true;
      categories = [ "Utility" "Game" ];
    };

    btop = {
      name      = "Btop";
      exec      = "ghostty +new-window -e btop";
      icon      = "btop";
      comment   = "Resource monitor";
      noDisplay = true;
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
      name      = "umpv";
      noDisplay = true;
      exec      = "umpv %U";
      icon      = "mpv";
      categories = [ "AudioVideo" "Video" ];
    };

    jellyfin-mpv-shim = {
      name      = "Jellyfin MPV Shim";
      exec      = "jellyfin-mpv-shim";
      icon      = "jellyfin-mpv-shim";
      terminal  = true;
      noDisplay = true;
      comment   = "Cast media from Jellyfin to mpv";
      categories = [ "AudioVideo" "Video" ];
    };

    imv = {
      name      = "imv";
      exec      = "imv %F";
      icon      = "imv";
      noDisplay = true;
      mimeType  = [ "image/jpeg" "image/png" "image/gif" "image/webp" "image/avif" "image/bmp" "image/tiff" "image/svg+xml" ];
      categories = [ "Graphics" "Viewer" ];
    };

    imv-dir = {
      name      = "imv";
      noDisplay = true;
      exec      = "imv %F";
      icon      = "imv";
      categories = [ "Graphics" "Viewer" ];
    };

    "io.github.ilya_zlobintsev.LACT" = {
      name      = "LACT";
      exec      = "lact gui";
      icon      = "io.github.ilya_zlobintsev.LACT";
      noDisplay = true;
      categories = [ "System" "Settings" ];
    };

    kvantummanager = {
      name      = "Kvantum Manager";
      exec      = "kvantummanager";
      icon      = "kvantummanager";
      noDisplay = true;
      categories = [ "Settings" ];
    };

    qt5ct = {
      name      = "Qt5 Settings";
      exec      = "qt5ct";
      icon      = "preferences-desktop-theme";
      noDisplay = true;
      categories = [ "Settings" "DesktopSettings" ];
    };

    qt6ct = {
      name      = "Qt6 Settings";
      exec      = "qt6ct";
      icon      = "preferences-desktop-theme";
      noDisplay = true;
      categories = [ "Settings" "DesktopSettings" ];
    };

    writer = {
      name      = "LibreOffice Writer";
      exec      = "libreoffice --writer %U";
      icon      = "libreoffice-writer";
      noDisplay = true;
      categories = [ "Office" "WordProcessor" ];
    };

    calc = {
      name      = "LibreOffice Calc";
      exec      = "libreoffice --calc %U";
      icon      = "libreoffice-calc";
      noDisplay = true;
      categories = [ "Office" "Spreadsheet" ];
    };

    impress = {
      name      = "LibreOffice Impress";
      exec      = "libreoffice --impress %U";
      icon      = "libreoffice-impress";
      noDisplay = true;
      categories = [ "Office" "Presentation" ];
    };

    draw = {
      name      = "LibreOffice Draw";
      exec      = "libreoffice --draw %U";
      icon      = "libreoffice-draw";
      noDisplay = true;
      categories = [ "Office" "Graphics" ];
    };

    math = {
      name      = "LibreOffice Math";
      exec      = "libreoffice --math %U";
      icon      = "libreoffice-math";
      noDisplay = true;
      categories = [ "Office" ];
    };

    base = {
      name      = "LibreOffice Base";
      exec      = "libreoffice --base %U";
      icon      = "libreoffice-base";
      noDisplay = true;
      categories = [ "Office" "Database" ];
    };

    xsltfilter = {
      name      = "LibreOffice XSLT Filter";
      exec      = "libreoffice";
      icon      = "libreoffice-startcenter";
      noDisplay = true;
      categories = [ "Office" ];
    };
  };

  xdg.configFile."mimeapps.list".force = true;

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Images → imv
      "image/jpeg"    = "imv.desktop";
      "image/png"     = "imv.desktop";
      "image/gif"     = "imv.desktop";
      "image/webp"    = "imv.desktop";
      "image/avif"    = "imv.desktop";
      "image/bmp"     = "imv.desktop";
      "image/tiff"    = "imv.desktop";
      "image/svg+xml" = "imv.desktop";

      # Videos → mpv
      "video/mp4"        = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "video/webm"       = "mpv.desktop";
      "video/x-msvideo"  = "mpv.desktop";
      "video/quicktime"  = "mpv.desktop";
      "video/x-flv"      = "mpv.desktop";
      "audio/mpeg"       = "mpv.desktop";
      "audio/flac"       = "mpv.desktop";
      "audio/ogg"        = "mpv.desktop";
      "audio/x-wav"      = "mpv.desktop";

      # Text / code → neovim
      "text/plain"                = "nvim.desktop";
      "text/x-shellscript"        = "nvim.desktop";
      "text/x-python"             = "nvim.desktop";
      "text/x-csrc"               = "nvim.desktop";
      "text/x-chdr"               = "nvim.desktop";
      "text/x-c++src"             = "nvim.desktop";
      "text/x-lua"                = "nvim.desktop";
      "text/x-rust"               = "nvim.desktop";
      "text/x-go"                 = "nvim.desktop";
      "text/x-java"               = "nvim.desktop";
      "text/html"                  = "brave-origin.desktop";
      "x-scheme-handler/http"      = "brave-origin.desktop";
      "x-scheme-handler/https"     = "brave-origin.desktop";
      "x-scheme-handler/ftp"       = "brave-origin.desktop";
      "x-scheme-handler/about"     = "brave-origin.desktop";
      "x-scheme-handler/unknown"   = "brave-origin.desktop";
      "x-scheme-handler/tuta"      = "tutanota-desktop.desktop";
      "application/xhtml+xml"      = "brave-origin.desktop";
      "application/x-extension-htm"   = "brave-origin.desktop";
      "application/x-extension-html"  = "brave-origin.desktop";
      "application/x-extension-xhtml" = "brave-origin.desktop";
      "text/css"                  = "nvim.desktop";
      "text/javascript"           = "nvim.desktop";
      "application/json"          = "nvim.desktop";
      "application/x-yaml"        = "nvim.desktop";
      "application/x-shellscript" = "nvim.desktop";
    };
  };
}
