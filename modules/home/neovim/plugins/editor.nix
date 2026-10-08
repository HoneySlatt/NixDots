{
  programs.nixvim.plugins = {
    nvim-autopairs.enable = true;

    indent-blankline = {
      enable = true;
      settings = {
        indent = {
          char = "│";
        };
        scope = {
          enabled = true;
        };
      };
    };

    todo-comments = {
      enable = true;
      settings = {
        signs = true;
        search = {
          command = "rg";
        };
      };
    };

    nvim-surround.enable = true;
  };
}
