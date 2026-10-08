{
  programs.helix.settings = {
    editor = {
      line-number = "relative";
      cursorline = true;
      scrolloff = 8;
      mouse = true;
      auto-format = false;
      auto-completion = true;
      auto-info = true;
      true-color = true;
      bufferline = "always";
      color-modes = true;
      idle-timeout = 250;
      completion-timeout = 250;
      completion-trigger-len = 2;
      indent-heuristic = "hybrid";
      popup-border = "all";
      lsp = {
        display-inlay-hints = true;
        display-messages = true;
      };
      indent-guides = {
        render = true;
        character = "│";
      };
      gutters = [
        "diagnostics"
        "spacer"
        "line-numbers"
        "spacer"
        "diff"
      ];
      statusline = {
        left = [ "mode" "spinner" "file-name" ];
        center = [];
        right = [ "diagnostics" "selections" "position" "file-type" ];
        separator = "│";
        mode = {
          normal = "NORMAL";
          insert = "INSERT";
          select = "SELECT";
        };
      };
      whitespace = {
        render = "none";
      };
      soft-wrap = {
        enable = false;
      };
      inline-diagnostics = {
        cursor-line = "warning";
        other-lines = "disable";
      };
      end-of-line-diagnostics = "hint";
    };
  };
}
