{
  programs.nixvim.plugins.rustaceanvim = {
    enable = true;
    settings.server.default_settings.rust-analyzer = (import ../../lsp-settings.nix).rust-analyzer;
  };
}
