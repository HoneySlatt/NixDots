{ pkgs, ... }:

{
  programs.zed-editor.userSettings = {
    helix_mode = true;
    relative_line_numbers = "enabled";
    current_line_highlight = "all";
    vertical_scroll_margin = 8;
    tab_size = 4;
    soft_wrap = "none";
    cursor_blink = false;
    buffer_font_family = "Google Sans Code";
    buffer_font_size = 14;
    ui_font_family = "Google Sans Code";
    ui_font_size = 14;
    auto_signature_help = true;
    indent_guides = { enabled = true; };
    format_on_save = "on";
    ensure_final_newline_on_save = true;
    show_wrap_guides = true;
    scroll_beyond_last_line = "off";
    autosave = "off";

    lsp = {
      "rust-analyzer" = {
        initialization_options = {
          check = {
            command = "clippy";
            extraArgs = [ "--" "-W" "clippy::pedantic" ];
          };
          cargo = {
            allFeatures = true;
            loadOutDirsFromCheck = true;
          };
          inlayHints = {
            bindingModeHints.enable = false;
            chainingHints.enable = true;
            closingBraceHints.enable = true;
            closureReturnTypeHints.enable = "always";
            parameterHints.enable = true;
            typeHints.enable = true;
          };
          procMacro = {
            enable = true;
          };
        };
      };

      gopls = {
        settings = {
          hints = {
            assignVariableTypes = true;
            compositeLiteralFields = true;
            functionTypeParameters = true;
            parameterNames = true;
            rangeVariableTypes = true;
          };
          analyses = {
            unusedparams = true;
            shadow = true;
          };
          staticcheck = true;
        };
      };

      wakatime = {
        binary = {
          path = "${pkgs.zed-wakatime-ls}/bin/wakatime-ls";
          arguments = [
            "--wakatime-cli"
            "${pkgs.wakatime-cli}/bin/wakatime-cli"
          ];
        };
      };
    };

    theme = {
      mode = "dark";
      dark = "One Dark";
      light = "One Light";
    };

    languages = {
      Rust.tab_size = 4;
      Go.tab_size = 4;
      Python.tab_size = 4;
      C.tab_size = 4;
      Cpp.tab_size = 4;
      Lua.tab_size = 2;
      JavaScript.tab_size = 2;
      TypeScript.tab_size = 2;
      HTML.tab_size = 2;
      CSS.tab_size = 2;
      JSON.tab_size = 2;
      Markdown.soft_wrap = "editor_width";
    };
  };
}
