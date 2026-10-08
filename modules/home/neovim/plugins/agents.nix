{
  programs.nixvim.plugins = {
    claude-code = {
      enable = true;
      settings = {
        window = {
          position = "vertical";
          split_ratio = 0.3;
        };
        keymaps = {
          toggle = {
            normal = false;
            terminal = false;
            variants = {
              continue = false;
              verbose = false;
            };
          };
          window_navigation = false;
        };
      };
    };

    codex = {
      enable = true;
      settings = {
        autoinstall = false;
        panel = true;
      };
    };
  };
}
