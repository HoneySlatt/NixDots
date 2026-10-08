let
  lspSettings = import ../../../lib/lsp-settings.nix;
in
{
  programs.zed-editor.userSettings = {
    vim_mode = true;
    helix_mode = false;
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

    telemetry = {
      diagnostics = false;
      metrics = false;
      anthropic_retention = false;
    };
    # Updates come from Nix, so never ping zed.dev
    auto_update = false;

    lsp = {
      "rust-analyzer".initialization_options = lspSettings.rust-analyzer;
      gopls.settings = lspSettings.gopls;
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
