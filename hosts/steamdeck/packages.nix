{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Browsers
    brave-origin

    # AI
    claude-code
    codex

    # Gaming
    heroic
    xivlauncher
    protonplus
    moonlight-qt

    # Files
    cosmic-files

    # Command line
    git
    neovim
  ];
}
