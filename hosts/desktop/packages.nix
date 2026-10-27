{ pkgs, ... }:

{
  nixpkgs.overlays = [ (import ../../pkgs/overrides) ];

  environment.systemPackages = with pkgs; [
    # Browsers
    brave-origin

    # Communication
    serein
    element-desktop
    signal-desktop
    tutanota-desktop

    # AI
    codex
    t3code
    chatgpt
    opencode
    goose-cli
    kimi-code
    grok-build
    claude-code
    goose-desktop
    claude-desktop
    kimi-code-desktop
    zcode

    # Media
    kopuz
    nuvio
    tsukimi
    cider-2

    # Gaming
    kytyps5

    # Creation and office
    pkgsRocm.blender
    gimp
    inkscape
    kdePackages.kdenlive
    libreoffice
    obsidian

    # Files and network
    nautilus
    cosmic-viewer
    localsend
    rqbit
    rqbit-desktop

    # Development
    git
    gh
    rustc
    cargo
    cargo-edit
    clippy
    rustfmt
    rust-analyzer
    python3
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
