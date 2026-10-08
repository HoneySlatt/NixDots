{ pkgs, ... }:
{
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      (pkgs.vimUtils.buildVimPlugin {
        pname = "pastel-nvim";
        version = "2024-03-14";
        src = pkgs.fetchFromGitHub {
          owner = "ankushbhagats";
          repo = "pastel.nvim";
          rev = "67e5aa4a6f70a38a4cc2e814221c9b2f8f354749";
          sha256 = "sha256-+6/HgHjNdiXGA8Zn2MS6gRdSCyV9v5I/bgoCf/wvnmQ=";
        };
      })
      rose-pine
      gruvbox-nvim
      nightfox-nvim
      everforest
    ];

    extraConfigLua = ''
      require("pastel").setup({
        style = {
          transparent = true,
          italic = true,
          bold = true,
        },
      })

      require("rose-pine").setup({
        variant = "auto",
        dark_variant = "main",
        dim_inactive_windows = false,
        extend_background_behind_borders = true,
        enable = {
          terminal = true,
          legacy_highlights = true,
          migrations = true,
        },
        styles = {
          bold = true,
          italic = true,
          transparency = true,
        },
      })

      require("gruvbox").setup({
        terminal_colors = true,
        undercurl = true,
        underline = true,
        bold = true,
        italic = {
          strings = false,
          emphasis = true,
          comments = true,
          operators = false,
          folds = true,
        },
        strikethrough = true,
        contrast = "hard",
        transparent_mode = true,
        dim_inactive = false,
        inverse = true,
        invert_selection = false,
        invert_signs = false,
        invert_tabline = false,
        invert_intend_guides = false,
      })

      require("nightfox").setup({
        options = {
          transparent = true,
          terminal_colors = true,
          dim_inactive = { enabled = false },
          styles = {
            comments = "italic",
            keywords = "bold",
            functions = "italic",
            types = "bold",
          },
          modules = {
            dap = true,
            diagnostic = true,
            gitsigns = true,
            indent_blankline = true,
            native_lsp = true,
            neotree = true,
            treesitter = true,
            whichkey = true,
          },
        },
      })


      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "carbonfox",
        callback = function()
          vim.schedule(function()
            vim.api.nvim_set_hl(0, "Normal",       { bg = "NONE" })
            vim.api.nvim_set_hl(0, "NormalNC",     { bg = "NONE" })
            vim.api.nvim_set_hl(0, "NormalFloat",  { bg = "NONE" })
            vim.api.nvim_set_hl(0, "lualine_a_normal", { fg = "#161616", bg = "#c6c6c6", bold = true })
            vim.api.nvim_set_hl(0, "lualine_b_normal", { fg = "#f2f4f8", bg = "#3a3a3a" })
            vim.api.nvim_set_hl(0, "lualine_y_normal", { fg = "#f2f4f8", bg = "#3a3a3a" })
            vim.api.nvim_set_hl(0, "lualine_z_normal", { fg = "#161616", bg = "#c6c6c6", bold = true })
          end)
        end,
      })

      -- Dynamic colorscheme from .current-theme, names from themes.json
      local qs = vim.fn.expand("~/.config/amane")
      local ok, themes = pcall(function()
        return vim.json.decode(table.concat(vim.fn.readfile(qs .. "/themes/themes.json"), "\n"))
      end)
      if ok then
        local current = vim.fn.filereadable(qs .. "/.current-theme") == 1
          and vim.fn.readfile(qs .. "/.current-theme")[1]:gsub("%s+", "")
        local entry = themes[current] or themes.pastelglow
        vim.opt.background = entry.light and "light" or "dark"
        vim.cmd.colorscheme(entry.nvim)
      end
    '';
  };
}
