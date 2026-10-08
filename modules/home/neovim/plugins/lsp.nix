{
  programs.nixvim.plugins.lsp = {
    enable = true;

    keymaps = {
      lspBuf = {
        "gd"          = { action = "definition";      desc = "Go to definition"; };
        "gD"          = { action = "declaration";     desc = "Go to declaration"; };
        "gr"          = { action = "references";      desc = "Go to references"; };
        "gi"          = { action = "implementation";  desc = "Go to implementation"; };
        "K"           = { action = "hover";           desc = "Hover documentation"; };
        "<leader>ca"  = { action = "code_action";     desc = "Code action"; };
        "<leader>cr"  = { action = "rename";          desc = "Rename symbol"; };
      };
      # [d and ]d are Neovim defaults
      diagnostic."<leader>cd" = { action = "open_float"; desc = "Show diagnostic"; };
    };

    servers = {
      # Rust — handled by rustaceanvim, not here

      # C / C++
      clangd = {
        enable = true;
        cmd = [ "clangd" "--background-index" "--clang-tidy" ];
        filetypes = [ "c" "cpp" "h" "hpp" ];
        rootMarkers = [ "compile_commands.json" "Makefile" ".git" ];
      };

      # Go
      gopls = {
        enable = true;
        settings.gopls = (import ../../../../lib/lsp-settings.nix).gopls;
      };

      # TOML
      taplo = {
        enable = true;
        rootMarkers = [ "Cargo.toml" ".git" ];
      };

      # Lua
      lua_ls = {
        enable = true;
        rootMarkers = [ ".luarc.json" ".git" ];
        settings = {
          Lua = {
            runtime.version = "LuaJIT";
            workspace.checkThirdParty = false;
            telemetry.enable = false;
          };
        };
      };

      # Python
      pyright = {
        enable = true;
        rootMarkers = [ "pyproject.toml" "requirements.txt" ".git" ];
      };

      # Web
      ts_ls.enable = true;
      html.enable = true;
      cssls.enable = true;
    };
  };
}
