{ pkgs, ... }:

{
  nixpkgs.overlays = [ (import ../../pkgs/overrides) ];

  environment.systemPackages = with pkgs; [
    # Browsers
    ladybird
    brave-origin

    # Communication
    serein
    cinny-desktop
    signal-desktop
    tutanota-desktop
    (discord.override { withVencord = true; })

    # AI
    claude-desktop
    chatgpt-desktop
    opencode-desktop
    claude-code
    codex
    opencode

    # Media
    kopuz
    cider-2
    jellyfin-desktop
    nuvio

    # Creation and office
    pkgsRocm.blender
    graphite
    gimp
    inkscape
    kdePackages.kdenlive
    libreoffice
    obsidian

    # Files and network
    nautilus
    localsend

    # Development
    git
    gh
    rustc
    cargo
    cargo-edit
    clippy
    rustfmt
    rust-analyzer
    nodejs
    gcc
    gnumake
    cmake
    pkg-config
    clang-tools
    gdb
    sqlite
    openssl

    # Command line
    fd
    fzf
    skim
    bat
    eza
    ripgrep
    gdu
    dua
    btop
    viu
    cava
    ffmpeg
    fastfetch
    trash-cli

    # GPU tuning
    lact
  ];

  programs.obs-studio.enable = true;
}
