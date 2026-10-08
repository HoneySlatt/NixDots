{
  programs.nixvim.plugins.lint = {
    enable = true;
    autoInstall.enable = true;
    lintersByFt = {
      python = [ "ruff" ];
      javascript = [ "eslint_d" ];
      typescript = [ "eslint_d" ];
      javascriptreact = [ "eslint_d" ];
      typescriptreact = [ "eslint_d" ];
    };
    autoCmd = {
      event = [ "BufEnter" "BufWritePost" "InsertLeave" ];
      callback.__raw = ''
        function()
          require("lint").try_lint()
        end
      '';
    };
  };
}
