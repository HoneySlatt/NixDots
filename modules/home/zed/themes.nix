let
  # UI roles mirror material/Theme.qml: surfaces, primary containers and state layers.
  # Zed reuses foregrounds across containers: soften tint where needed for contrast.
  # Syntax colors stay editor-specific so code remains easy to distinguish.
  palettes = {
    gruvbox = {
      bg = "#282828"; bg1 = "#353231"; bg2 = "#423d3a";
      fg = "#ebdbb2"; fg2 = "#ccbe9c";
      red = "#fb4934"; green = "#b8bb26"; yellow = "#fabd2f";
      blue = "#83a598"; purple = "#d3869b"; aqua = "#8ec07c"; orange = "#fe8019";
      primary = "#d3869b";
      accentText = "#d3869b";
      selected = "#5f464d";
      hover = "#383633";
      pressed = "#3f3d39";
      outline = "#4f4c44";
    };
    gruvbox-light = {
      bg = "#fbf1c7"; bg1 = "#f1e3b9"; bg2 = "#e6d4ac";
      fg = "#3c3836"; fg2 = "#5e5950";
      red = "#9d0006"; green = "#79740e"; yellow = "#b57614";
      blue = "#076678"; purple = "#8f3f71"; aqua = "#427b58"; orange = "#af3a03";
      primary = "#b16286";
      accentText = "#472736";
      selected = "#ebd2b9";
      hover = "#ece2bb";
      pressed = "#e4dbb6";
      outline = "#d5ccaa";
    };
    rose-pine = {
      bg = "#191724"; bg1 = "#211f32"; bg2 = "#2a2741";
      fg = "#e0def4"; fg2 = "#bcbacf";
      red = "#eb6f92"; green = "#31748f"; yellow = "#f6c177";
      blue = "#c4a7e7"; purple = "#c4a7e7"; aqua = "#9ccfd8"; orange = "#f6c177";
      primary = "#c4a7e7";
      accentText = "#c4a7e7";
      selected = "#504562";
      hover = "#292735";
      pressed = "#312f3d";
      outline = "#413f4e";
    };
    everforest = {
      bg = "#2d353b"; bg1 = "#323c41"; bg2 = "#364247";
      fg = "#d3c6aa"; fg2 = "#bfb59d";
      red = "#e67e80"; green = "#a7c080"; yellow = "#dbbc7f";
      blue = "#7fbbb3"; purple = "#d699b6"; aqua = "#83c092"; orange = "#e69875";
      primary = "#a7c080";
      accentText = "#a7c080";
      selected = "#3e4845";
      hover = "#3a4144";
      pressed = "#414648";
      outline = "#4e5251";
    };
    carbonfox = {
      bg = "#161616"; bg1 = "#232323"; bg2 = "#303030";
      fg = "#f2f4f8"; fg2 = "#bdbfc2";
      red = "#ee5396"; green = "#25be6a"; yellow = "#08bdba";
      blue = "#78a9ff"; purple = "#be95ff"; aqua = "#33b1ff"; orange = "#ee5396";
      primary = "#c6c6c6";
      accentText = "#c6c6c6";
      selected = "#4e4e4e";
      hover = "#282828";
      pressed = "#303131";
      outline = "#424243";
    };
    pastel = {
      bg = "#F8E9EE"; bg1 = "#ead0d7"; bg2 = "#dbb6c1";
      fg = "#3B2730"; fg2 = "#59464e";
      red = "#a32646"; green = "#356c47"; yellow = "#795d17";
      blue = "#425db0"; purple = "#8540ad"; aqua = "#216e70"; orange = "#a14e28";
      primary = "#B86EE6";
      accentText = "#4a2c5c";
      selected = "#eaceec";
      hover = "#e9d9df";
      pressed = "#e1d2d7";
      outline = "#d2c2c8";
    };
  };

  mkOverride = pal: {
    "editor.background" = pal.bg;
    "editor.foreground" = pal.fg;
    "editor.gutter.background" = pal.bg;
    "editor.line_number" = pal.fg2;
    "editor.active_line_number" = pal.fg;
    "editor.active_line.background" = pal.hover;
    "editor.highlighted_line.background" = pal.selected;
    "editor.document_highlight.read_background" = "${pal.primary}20";
    "editor.document_highlight.write_background" = "${pal.primary}30";
    "editor.document_highlight.bracket_background" = pal.selected;
    "editor.indent_guide" = pal.outline;
    "editor.indent_guide_active" = pal.primary;
    "editor.wrap_guide" = pal.outline;
    "editor.active_wrap_guide" = pal.fg2;
    background = pal.bg;
    "background.appearance" = "opaque";
    accents = [ pal.primary ];
    "status_bar.background" = pal.bg;
    "title_bar.background" = pal.bg;
    "title_bar.inactive_background" = pal.bg;
    "tab_bar.background" = pal.bg;
    "tab.inactive_background" = pal.bg;
    "tab.active_background" = pal.selected;
    "panel.background" = pal.bg;
    "toolbar.background" = pal.bg;
    "editor.subheader.background" = pal.bg1;
    "terminal.background" = pal.bg;
    "terminal.foreground" = pal.fg;
    "terminal.ansi.black" = pal.bg;
    "terminal.ansi.red" = pal.red;
    "terminal.ansi.green" = pal.green;
    "terminal.ansi.yellow" = pal.yellow;
    "terminal.ansi.blue" = pal.blue;
    "terminal.ansi.magenta" = pal.purple;
    "terminal.ansi.cyan" = pal.aqua;
    "terminal.ansi.white" = pal.fg;
    "terminal.ansi.bright_black" = pal.fg2;
    border = pal.outline;
    "border.focused" = pal.primary;
    "border.selected" = pal.primary;
    "border.disabled" = pal.outline;
    "border.transparent" = "#00000000";
    "panel.focused_border" = pal.primary;
    "pane.focused_border" = pal.primary;
    "pane_group.border" = pal.outline;
    "border.variant" = pal.outline;
    "scrollbar.thumb.background" = "${pal.fg2}66";
    "scrollbar.thumb.hover_background" = "${pal.fg2}99";
    "scrollbar.thumb.border" = "#00000000";
    "scrollbar.track.background" = "#00000000";
    "scrollbar.track.border" = "#00000000";
    text = pal.fg;
    "text.muted" = pal.fg2;
    "text.accent" = pal.accentText;
    "text.placeholder" = pal.fg2;
    "text.disabled" = "${pal.fg}61";
    icon = pal.fg;
    "icon.muted" = pal.fg2;
    "icon.accent" = pal.accentText;
    "icon.placeholder" = pal.fg2;
    "icon.disabled" = "${pal.fg}61";
    "link_text.hover" = pal.accentText;
    "element.background" = pal.bg1;
    "element.hover" = pal.pressed;
    "element.active" = pal.selected;
    "element.selected" = pal.selected;
    "element.disabled" = pal.bg1;
    "ghost_element.background" = "#00000000";
    "ghost_element.hover" = pal.hover;
    "ghost_element.active" = pal.pressed;
    "ghost_element.selected" = pal.selected;
    "ghost_element.disabled" = "#00000000";
    "drop_target.background" = "${pal.primary}30";
    "search.match_background" = "${pal.primary}40";
    players = [{ cursor = pal.primary; background = pal.primary; selection = "${pal.primary}40"; }];
    "surface.background" = pal.bg;
    "elevated_surface.background" = pal.bg2;
    "syntax" = {
      comment = { color = pal.fg2; font_style = "italic"; };
      string = { color = pal.green; };
      keyword = { color = pal.purple; };
      function = { color = pal.blue; };
      constructor = { color = pal.blue; };
      variable = { color = pal.fg; };
      type = { color = pal.yellow; };
      constant = { color = pal.orange; };
      number = { color = pal.orange; };
      operator = { color = pal.aqua; };
      property = { color = pal.red; };
      attribute = { color = pal.blue; };
      "diff.plus" = { color = pal.green; };
      "diff.minus" = { color = pal.red; };
    };
  };
in
{
  # Deploy palette files for dynamic theme switching
  xdg.configFile = {
    "zed/theme-overrides/gruvbox.json".text = builtins.toJSON (mkOverride palettes.gruvbox);
    "zed/theme-overrides/gruvbox-light.json".text = builtins.toJSON (mkOverride palettes.gruvbox-light);
    "zed/theme-overrides/rosepine.json".text = builtins.toJSON (mkOverride palettes.rose-pine);
    "zed/theme-overrides/everforest.json".text = builtins.toJSON (mkOverride palettes.everforest);
    "zed/theme-overrides/carbonfox.json".text = builtins.toJSON (mkOverride palettes.carbonfox);
    "zed/theme-overrides/pastelglow.json".text = builtins.toJSON (mkOverride palettes.pastel);
  };
}
