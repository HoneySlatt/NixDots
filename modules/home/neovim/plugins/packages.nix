{ pkgs, ... }:
{
  # Formatters and linters come from conform-nvim and lint autoInstall
  programs.nixvim.extraPackages = [ pkgs.lazygit ];
}
