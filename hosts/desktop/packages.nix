{ pkgs, inputs, ... }:

{
  nixpkgs.overlays = [
    inputs.millennium.overlays.default
    (final: prev: {
      # Sort library by overridden title when set
      heroic-unwrapped = prev.heroic-unwrapped.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ../../pkgs/heroic-gog-profile.patch ];
        postPatch = (old.postPatch or "") + ''
          substituteInPlace src/frontend/screens/Library/index.tsx \
            --replace-fail "a.title.toUpperCase()" "(a.overrides?.title || a.title).toUpperCase()" \
            --replace-fail "b.title.toUpperCase()" "(b.overrides?.title || b.title).toUpperCase()"
          # Game page background uses the (possibly overridden) cover art first
          substituteInPlace src/frontend/screens/Game/GamePage/index.tsx \
            --replace-fail "src={art_background || art_cover}" "src={art_cover || art_background}"
        '';
      });

      # No title bar, and Quickshell theme injected into the bundled frontend
      cinny-desktop = prev.cinny-desktop.overrideAttrs (old: {
        postPatch = old.postPatch + ''
          frontend="$NIX_BUILD_TOP/frontend"
          cp -rL "$(${final.jq}/bin/jq -r .build.frontendDist tauri.conf.json)" "$frontend"
          chmod -R u+w "$frontend"
          substituteInPlace "$frontend/index.html" \
            --replace-fail "</head>" "$(cat ${../../pkgs/cinny-desktop-theme.html})</head>"
          ${final.jq}/bin/jq --arg dist "$frontend" '.build.frontendDist = $dist' tauri.conf.json \
            | ${final.moreutils}/bin/sponge tauri.conf.json

          substituteInPlace src/lib.rs \
            --replace-fail '.title("Cinny")' '.title("Cinny").decorations(false)' \
            --replace-fail 'tauri_plugin_window_state::Builder::default()' \
              'tauri_plugin_window_state::Builder::default().with_state_flags(tauri_plugin_window_state::StateFlags::all() - tauri_plugin_window_state::StateFlags::DECORATIONS)'
        '';
      });
    })
  ];

  environment.systemPackages = with pkgs; [

    # Web Browsers
    firefox
    ladybird
    brave-origin

    # Desktop Apps
    claude-desktop
    chatgpt-desktop
    pkgsRocm.blender
    gimp
    kopuz
    cider-2
    obsidian
    inkscape
    localsend
    libreoffice
    qbittorrent
    cinny-desktop
    signal-desktop
    tutanota-desktop
    opencode-desktop
    jellyfin-desktop
    kdePackages.kdenlive

    # Development
    git
    rustc
    rustfmt
    rust-analyzer
    cargo
    cargo-edit
    clippy
    nodejs
    gcc
    gnumake
    clang-tools
    gdb
    pkg-config
    cmake

    # Gaming
    heroic
    xivlauncher
    protonplus
    prismlauncher

    # TUI/CLI
    gh
    fd
    fzf
    bat
    eza
    gdu
    imv
    cava
    btop
    ffmpeg
    ripgrep
    fastfetch
    trash-cli
    codex
    opencode
    claude-code

    # Virtualisation
    virt-manager
    virtio-win

    # Others
    lact
    sqlite
    openssl
    nautilus

    # Custom pkgs
    steam-metadata-editor
    nuvio

    # Discord
    (discord.override {
      withVencord = true;
    })
  ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    protontricks.enable = true;
    package = pkgs.millennium-steam;
  };

  programs.gamemode.enable = true;

  programs.obs-studio.enable = true;
}
