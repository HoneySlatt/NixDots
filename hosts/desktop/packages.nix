{ lib, pkgs, ... }:

{
  nixpkgs.overlays = lib.mkAfter [ (import ../../pkgs/overrides) ];

  environment.systemPackages = with pkgs; [
    # Browsers
    ladybird
    brave-origin

    # Communication
    discord
    element-desktop
    signal-desktop
    tutanota-desktop

    # AI
    codex
    opencode
    goose-cli
    kimi-code
    deepseek-harness
    grok-build
    claude-code
    mistral-vibe
    goose-desktop
    claude-desktop
    zcode

    # Media
    nuvio
    tsukimi
    cider-2
    spotify

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
