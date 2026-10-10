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

    # AI
    claude-desktop
    chatgpt-desktop
    opencode-desktop
    # Sandbox of the Codex agent bundled with ChatGPT Desktop
    bubblewrap
    claude-code
    codex
    opencode

    # Media
    kopuz
    tsukimi
    cider-2
    nuvio

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
