{
  programs.nixvim.plugins.rustaceanvim = {
    enable = true;
    settings.server.default_settings.rust-analyzer = (import ../../../../lib/lsp-settings.nix).rust-analyzer;
  };
}
