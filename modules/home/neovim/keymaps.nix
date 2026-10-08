{
  programs.nixvim.keymaps = [
    # Window navigation
    { mode = "n"; key = "<C-h>"; action = "<C-w>h"; options.desc = "Move to left window"; }
    { mode = "n"; key = "<C-j>"; action = "<C-w>j"; options.desc = "Move to lower window"; }
    { mode = "n"; key = "<C-k>"; action = "<C-w>k"; options.desc = "Move to upper window"; }
    { mode = "n"; key = "<C-l>"; action = "<C-w>l"; options.desc = "Move to right window"; }

    # Window resize
    { mode = "n"; key = "<C-Up>";    action = "<cmd>resize +5<cr>";          options.desc = "Increase window height"; }
    { mode = "n"; key = "<C-Down>";  action = "<cmd>resize -5<cr>";          options.desc = "Decrease window height"; }
    { mode = "n"; key = "<C-Left>";  action = "<cmd>vertical resize -5<cr>"; options.desc = "Decrease window width"; }
    { mode = "n"; key = "<C-Right>"; action = "<cmd>vertical resize +5<cr>"; options.desc = "Increase window width"; }

    # Buffer navigation
    { mode = "n"; key = "<S-h>";      action = "<cmd>bprevious<cr>"; options.desc = "Previous buffer"; }
    { mode = "n"; key = "<S-l>";      action = "<cmd>bnext<cr>";     options.desc = "Next buffer"; }
    { mode = "n"; key = "<leader>bd"; action = "<cmd>bdelete<cr>";   options.desc = "Delete buffer"; }

    # Better indenting (stay in visual mode)
    { mode = "v"; key = "<"; action = "<gv"; }
    { mode = "v"; key = ">"; action = ">gv"; }

    # Move lines up/down in visual mode
    { mode = "v"; key = "J"; action = ":m '>+1<cr>gv=gv"; options.desc = "Move line down"; }
    { mode = "v"; key = "K"; action = ":m '<-2<cr>gv=gv"; options.desc = "Move line up"; }

    # Clear search highlight
    { mode = "n"; key = "<Esc>"; action = "<cmd>nohlsearch<cr>"; options.desc = "Clear search highlight"; }

    # Exit terminal mode
    { mode = "t"; key = "<Esc><Esc>"; action = "<C-\\><C-n>"; options.desc = "Exit terminal mode"; }

    # Neo-tree
    { mode = "n"; key = "<leader>e"; action = "<cmd>Neotree toggle<cr>"; options.desc = "Toggle file explorer"; }

    # FzfLua
    { mode = "n"; key = "<leader>ff"; action = "<cmd>FzfLua files<cr>";              options.desc = "Find files"; }
    { mode = "n"; key = "<leader>fg"; action = "<cmd>FzfLua live_grep<cr>";          options.desc = "Live grep"; }
    { mode = "n"; key = "<leader>fb"; action = "<cmd>FzfLua buffers<cr>";            options.desc = "Find buffers"; }
    { mode = "n"; key = "<leader>fh"; action = "<cmd>FzfLua help_tags<cr>";          options.desc = "Help tags"; }
    { mode = "n"; key = "<leader>fr"; action = "<cmd>FzfLua oldfiles<cr>";           options.desc = "Recent files"; }
    { mode = "n"; key = "<leader>fd"; action = "<cmd>FzfLua diagnostics_document<cr>"; options.desc = "Document diagnostics"; }
    { mode = "n"; key = "<leader>ft"; action = "<cmd>TodoFzfLua<cr>";                options.desc = "Find TODOs"; }

    # Code (format, action, rename; the rest is in lsp.nix)
    {
      mode = "n";
      key = "<leader>cf";
      action.__raw = ''function() require("conform").format({ async = true, lsp_format = "fallback" }) end'';
      options.desc = "Format file";
    }

    # Git — lazygit via toggleterm
    {
      mode = "n";
      key = "<leader>gg";
      action.__raw = ''
        function()
          local Terminal = require("toggleterm.terminal").Terminal
          local lazygit = Terminal:new({
            cmd = "lazygit",
            dir = vim.fn.expand("%:p:h"),
            direction = "float",
            float_opts = { border = "rounded" },
            hidden = true,
          })
          lazygit:toggle()
        end
      '';
      options.desc = "Lazygit";
    }

    # Trouble — diagnostics list
    { mode = "n"; key = "<leader>xx"; action = "<cmd>Trouble diagnostics toggle<cr>";          options.desc = "Workspace diagnostics"; }
    { mode = "n"; key = "<leader>xd"; action = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>"; options.desc = "Document diagnostics"; }
    { mode = "n"; key = "<leader>xs"; action = "<cmd>Trouble symbols toggle<cr>";              options.desc = "Symbols"; }
    { mode = "n"; key = "<leader>xq"; action = "<cmd>Trouble qflist toggle<cr>";               options.desc = "Quickfix"; }

    # ToggleTerm
    {
      mode = "n";
      key = "<leader>tt";
      action.__raw = ''
        function()
          require("toggleterm").toggle(1, nil, vim.fn.expand("%:p:h"), "float")
        end
      '';
      options.desc = "Toggle floating terminal";
    }
    {
      mode = "n";
      key = "<leader>th";
      action.__raw = ''
        function()
          require("toggleterm").toggle(1, 15, vim.fn.expand("%:p:h"), "horizontal")
        end
      '';
      options.desc = "Toggle horizontal terminal";
    }

    # DAP
    { mode = "n"; key = "<leader>db"; action.__raw = ''function() require("dap").toggle_breakpoint() end''; options.desc = "Toggle breakpoint"; }
    { mode = "n"; key = "<leader>dc"; action.__raw = ''function() require("dap").continue() end'';          options.desc = "Continue"; }
    { mode = "n"; key = "<leader>di"; action.__raw = ''function() require("dap").step_into() end'';         options.desc = "Step into"; }
    { mode = "n"; key = "<leader>do"; action.__raw = ''function() require("dap").step_over() end'';         options.desc = "Step over"; }
    { mode = "n"; key = "<leader>dO"; action.__raw = ''function() require("dap").step_out() end'';          options.desc = "Step out"; }
    { mode = "n"; key = "<leader>dt"; action.__raw = ''function() require("dap").terminate() end'';         options.desc = "Terminate"; }
    { mode = "n"; key = "<leader>du"; action.__raw = ''function() require("dapui").toggle() end'';          options.desc = "Toggle debug UI"; }

    # Python venv
    { mode = "n"; key = "<leader>pv"; action = "<cmd>VenvSelect<cr>";       options.desc = "Select venv"; }
    { mode = "n"; key = "<leader>pc"; action = "<cmd>VenvSelectCached<cr>"; options.desc = "Select cached venv"; }

    # Markdown live preview
    { mode = "n"; key = "<leader>mp"; action = "<cmd>LivePreview start<cr>"; options.desc = "Start live preview"; }
    { mode = "n"; key = "<leader>ms"; action = "<cmd>LivePreview close<cr>"; options.desc = "Stop live preview"; }

    # OpenCode
    { mode = "n"; key = "<leader>aa"; action.__raw = ''function() require("opencode").ask("@this: ", { submit = true }) end''; options.desc = "Ask OpenCode"; }
    { mode = "x"; key = "<leader>aa"; action.__raw = ''function() require("opencode").ask("@this: ", { submit = true }) end''; options.desc = "Ask OpenCode"; }
    { mode = "n"; key = "<leader>ax"; action.__raw = ''function() require("opencode").select() end'';                          options.desc = "OpenCode select action"; }
    { mode = "n"; key = "<leader>at"; action.__raw = ''function() require("opencode").toggle() end'';                            options.desc = "Toggle OpenCode"; }
    { mode = "n"; key = "<leader>ao"; action.__raw = ''function() return require("opencode").operator("@this ") end'';            options.desc = "Add range to OpenCode"; }
    { mode = "n"; key = "<leader>ap"; action.__raw = ''function() require("opencode").prompt("explain @this") end'';             options.desc = "Explain with OpenCode"; }

    # Claude Code and Codex
    { mode = "n"; key = "<leader>ac"; action = "<cmd>ClaudeCode<cr>"; options.desc = "Toggle Claude Code"; }
    { mode = "n"; key = "<leader>ad"; action = "<cmd>CodexToggle<cr>"; options.desc = "Toggle Codex"; }
  ];
}
