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
    oxi
    codex
    t3code
    chatgpt
    opencode
    grok-build
    claude-code
    claude-desktop
    opencode-desktop

    # Media
    kopuz
    nuvio
    tsukimi
    cider-2

    # Creation and office
    pkgsRocm.blender
    gimp
    inkscape
    kdePackages.kdenlive
    libreoffice
    obsidian

    # Files and network
    cosmic-files
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
