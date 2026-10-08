{
  programs.nixvim = {
    lsp.inlayHints.enable = true;

    globals = {
      mapleader = " ";
      maplocalleader = " ";
    };

    opts = {
      number = true;
      relativenumber = true;
      tabstop = 4;
      shiftwidth = 4;
      expandtab = true;
      smartindent = true;
      wrap = false;
      cursorline = true;
      termguicolors = true;
      signcolumn = "yes";
      scrolloff = 8;
      sidescrolloff = 8;
      clipboard = "unnamedplus";
      ignorecase = true;
      smartcase = true;
      splitbelow = true;
      splitright = true;
      undofile = true;
      updatetime = 250;
      timeoutlen = 300;
      mouse = "a";
      showmode = false;
      # Live preview of substitutions (:s/foo/bar)
      inccommand = "split";
    };
  };
}
