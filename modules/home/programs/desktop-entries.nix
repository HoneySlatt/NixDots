{ config, lib, ... }:

let
  icons = "${config.home.homeDirectory}/Pictures/Icons";

  imageTypes = [ "image/jpeg" "image/png" "image/gif" "image/webp" "image/avif" "image/bmp" "image/tiff" "image/svg+xml" ];
  fontTypes = [
    "application/x-font-ttf" "application/x-font-type1" "application/x-font-otf"
    "application/x-font-pcf" "application/x-font-bdf" "application/vnd.kde.fontspackage"
    "font/otf" "font/ttf" "font/collection"
  ];
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
      icon       = "/home/honey/Pictures/Icons/brave.png";
      comment    = "Web browser";
      categories = [ "Network" "WebBrowser" ];
    };

    chatgpt = {
      name       = "ChatGPT";
      exec       = "chatgpt %U";
      icon       = "/home/honey/Pictures/Icons/chatgpt.png";
      comment    = "AI assistant";
      mimeType   = [
        "x-scheme-handler/codex" "x-scheme-handler/http" "x-scheme-handler/https"
        "text/csv" "text/tab-separated-values" "application/vnd.ms-excel"
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        "application/vnd.ms-excel.sheet.macroEnabled.12"
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      ];
      categories = [ "Utility" "Development" ];
      startupNotify = true;
    };

    "com.anthropic.Claude" = {
      name       = "Claude";
      exec       = "claude-desktop %U";
      icon       = "/home/honey/Pictures/Icons/claude.png";
      comment    = "Desktop application for Claude.ai";
      mimeType   = [ "x-scheme-handler/claude" ];
      categories = [ "Utility" "Development" ];
      startupNotify = true;
      settings = {
        StartupWMClass = "com.anthropic.Claude";
        SingleMainWindow = "true";
      };
      actions = {
        NewChat = {
          name = "New Chat";
          exec = "claude-desktop \"claude://claude.ai/new?surface=chat&source=desktop_action\"";
        };
        NewCode = {
          name = "New Claude Code Session";
          exec = "claude-desktop \"claude://code/new?source=desktop_action\"";
        };
      };
    };

    element-desktop = {
      name       = "Element";
      exec       = "element-desktop %u";
      icon       = "/home/honey/Pictures/Icons/matrix.png";
      comment    = "Matrix client";
      mimeType   = [ "x-scheme-handler/element" "x-scheme-handler/io.element.desktop" ];
      categories = [ "Network" "InstantMessaging" "Chat" ];
      settings.StartupWMClass = "Element";
    };

    signal = {
      name       = "Signal";
      exec       = "signal-desktop %U";
      icon       = "${icons}/signal.png";
      comment    = "Private messaging from your desktop";
      mimeType   = [ "x-scheme-handler/sgnl" "x-scheme-handler/signalcaptcha" ];
      categories = [ "Network" "InstantMessaging" "Chat" ];
      settings.StartupWMClass = "signal";
    };

    "cider-2" = {
      name       = "Cider";
      exec       = "cider-2 %U";
      icon       = "/home/honey/Pictures/Icons/applemusic.png";
      comment    = "Apple Music client";
      mimeType   = [
        "x-scheme-handler/cider" "x-scheme-handler/itms" "x-scheme-handler/itmss"
        "x-scheme-handler/music" "x-scheme-handler/itunes"
      ];
      categories = [ "Audio" "AudioVideo" "Music" ];
      settings.StartupWMClass = "Cider";
      actions = {
        PlayPause = {
          name = "Play-Pause";
          exec = "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.cider /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause";
        };
        Next = {
          name = "Next";
          exec = "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.cider /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next";
        };
        Previous = {
          name = "Previous";
          exec = "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.cider /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous";
        };
        Stop = {
          name = "Stop";
          exec = "dbus-send --print-reply --dest=org.mpris.MediaPlayer2.cider /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Stop";
        };
      };
    };

    "cz.viceverse.serein" = {
      name       = "Discord";
      exec       = "serein";
      icon       = "/home/honey/Pictures/Icons/discord.png";
      comment    = "Discord client";
      categories = [ "Network" "InstantMessaging" ];
    };

    t3code = {
      name       = "T3 Code";
      exec       = "t3code-desktop %U";
      icon       = "/home/honey/Pictures/Icons/t3code.png";
      comment    = "Coding agent workspace";
      categories = [ "Development" "IDE" ];
      settings.StartupWMClass = "t3code";
    };

    "kimi-code" = {
      name       = "Kimi Code";
      exec       = "kimi-code-desktop %U";
      icon       = "kimi-code";
      comment    = "AI coding workspace";
      mimeType   = [ "x-scheme-handler/kimi-code" ];
      categories = [ "Development" "IDE" ];
      settings.StartupWMClass = "kimi-code";
    };

    # KDE applications and graphical tools, also visible outside Plasma
    kdesystemsettings = {
      name       = "KDE System Settings";
      exec       = "systemsettings";
      icon       = "preferences-system";
      settings.NotShowIn = "KDE;";
      noDisplay  = true;
      categories = [ "Qt" "KDE" "Settings" ];
    };

    kcm_kded = {
      name       = "Background Services";
      exec       = "kcmshell6 kcm_kded";
      icon       = "preferences-system-session-services";
      noDisplay  = true;
      categories = [ "Qt" "KDE" "Settings" ];
    };

    "org.kde.drkonqi.coredump.gui" = {
      name       = "Crashed Processes Viewer";
      exec       = "drkonqi-coredump-gui";
      icon       = "tools-report-bug";
      noDisplay  = true;
      categories = [ "Qt" "KDE" "System" ];
    };

    "org.kde.kcolorschemeeditor" = {
      name       = "KColorSchemeEditor";
      exec       = "kcolorschemeeditor";
      icon       = "preferences-desktop-color";
      noDisplay  = true;
      categories = [ "Qt" "KDE" "Settings" ];
    };

    "org.kde.kdenlive" = {
      name       = "Kdenlive";
      exec       = "kdenlive %F";
      icon       = "kdenlive";
      mimeType   = [
        "application/x-kdenlive" "application/vnd.mlt+xml" "video/mp4" "video/x-matroska"
        "video/webm" "video/quicktime" "video/x-msvideo" "video/mpeg" "video/3gpp" "video/3gpp2"
        "audio/mpeg" "audio/ogg" "audio/flac" "audio/wav" "audio/mp4" "audio/x-matroska"
        "image/gif" "image/jpeg" "image/png" "image/webp"
      ];
      categories = [ "Qt" "KDE" "AudioVideo" "AudioVideoEditing" ];
      settings.StartupWMClass = "kdenlive";
    };

    "org.kde.keditfiletype" = {
      name       = "File Type Editor";
      exec       = "keditfiletype";
      icon       = "preferences-desktop-filetype-association";
      noDisplay  = true;
      categories = [ "Qt" "KDE" "Settings" ];
    };

    "org.kde.kfontinst" = {
      name       = "KFontInst";
      exec       = "kfontinst %U";
      icon       = "preferences-desktop-font-installer";
      mimeType   = fontTypes;
      noDisplay  = true;
      categories = [ "Qt" "KDE" "Utility" ];
    };

    "org.kde.kfontview" = {
      name       = "KFontView";
      exec       = "kfontview %U";
      icon       = "kfontview";
      mimeType   = fontTypes;
      noDisplay  = true;
      categories = [ "Qt" "KDE" "Utility" ];
    };

    "org.kde.kinfocenter" = {
      name       = "Info Center";
      exec       = "kinfocenter";
      icon       = "hwinfo";
      noDisplay  = true;
      categories = [ "Qt" "KDE" "System" "Documentation" ];
    };

    "org.kde.kmenuedit" = {
      name       = "Menu Editor";
      exec       = "kmenuedit";
      icon       = "kmenuedit";
      noDisplay  = true;
      categories = [ "Qt" "KDE" "System" ];
    };

    "org.kde.knetattach" = {
      name       = "KNetAttach";
      exec       = "knetattach";
      icon       = "knetattach";
      noDisplay  = true;
      categories = [ "Qt" "KDE" "Network" "RemoteAccess" ];
    };

    "org.kde.kwalletmanager" = {
      name       = "KWalletManager";
      exec       = "kwalletmanager5 %F";
      icon       = "kwalletmanager";
      mimeType   = [ "application/x-kwallet" ];
      noDisplay  = true;
      categories = [ "Qt" "KDE" "System" "Security" ];
    };

    "org.kde.plasma-systemmonitor" = {
      name       = "System Monitor";
      exec       = "plasma-systemmonitor";
      icon       = "utilities-system-monitor";
      noDisplay  = true;
      categories = [ "Qt" "KDE" "System" ];
    };

    "org.kde.plasma.emojier" = {
      name       = "Emoji Selector";
      exec       = "plasma-emojier";
      icon       = "preferences-desktop-emoticons";
      noDisplay  = true;
      categories = [ "Qt" "KDE" "Utility" ];
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
      name       = "Jellyfin";
      exec       = "tsukimi";
      icon       = "/home/honey/Pictures/Icons/jellyfin.png";
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

    "org.gnome.Nautilus" = {
      name       = "Files";
      exec       = "nautilus --new-window %U";
      icon       = "org.gnome.Nautilus";
      comment    = "Access and organize files";
      noDisplay  = true;
      categories = [ "GNOME" "GTK" "Utility" "Core" "FileManager" ];
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
      exec       = "ghostty +new-window -e btop";
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
        "x-scheme-handler/element" = "element-desktop.desktop";
        "x-scheme-handler/io.element.desktop" = "element-desktop.desktop";
        "inode/directory" = "org.gnome.Nautilus.desktop";
      };
  };
}
