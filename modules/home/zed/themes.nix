{ ... }:

let
  palettes = {
    gruvbox = {
      bg = "#282828"; bg1 = "#3c3836"; bg2 = "#504945"; bg3 = "#665c54";
      fg = "#fbf1c7"; fg2 = "#a89984";
      red = "#fb4934"; green = "#b8bb26"; yellow = "#fabd2f";
      blue = "#83a598"; purple = "#d3869b"; aqua = "#8ec07c"; orange = "#fe8019";
    };
    gruvbox-light = {
      bg = "#fbf1c7"; bg1 = "#ebdbb2"; bg2 = "#d5c4a1"; bg3 = "#bdae93";
      fg = "#3c3836"; fg2 = "#7c6f64";
      red = "#9d0006"; green = "#79740e"; yellow = "#b57614";
      blue = "#076678"; purple = "#8f3f71"; aqua = "#427b58"; orange = "#af3a03";
    };
    rose-pine = {
      bg = "#191724"; bg1 = "#1f1d2e"; bg2 = "#26233a"; bg3 = "#6e6a86";
      fg = "#e0def4"; fg2 = "#908caa";
      red = "#eb6f92"; green = "#31748f"; yellow = "#f6c177";
      blue = "#c4a7e7"; purple = "#c4a7e7"; aqua = "#9ccfd8"; orange = "#f6c177";
    };
    everforest = {
      bg = "#2b3339"; bg1 = "#323c41"; bg2 = "#3a4248"; bg3 = "#7a8478";
      fg = "#d3c6aa"; fg2 = "#7a8478";
      red = "#e67e80"; green = "#a7c080"; yellow = "#dbbc7f";
      blue = "#7fbbb3"; purple = "#d699b6"; aqua = "#83c092"; orange = "#e69875";
    };
    carbonfox = {
      bg = "#161616"; bg1 = "#262626"; bg2 = "#393939"; bg3 = "#525252";
      fg = "#f2f4f8"; fg2 = "#525252";
      red = "#ee5396"; green = "#25be6a"; yellow = "#08bdba";
      blue = "#78a9ff"; purple = "#be95ff"; aqua = "#33b1ff"; orange = "#ee5396";
    };
    pastel = {
      bg = "#1A1D23"; bg1 = "#22262E"; bg2 = "#2A2F38"; bg3 = "#5C6370";
      fg = "#C5CDD9"; fg2 = "#5C6370";
      red = "#E06C75"; green = "#98C379"; yellow = "#E5C07B";
      blue = "#61AFEF"; purple = "#C678DD"; aqua = "#56B6C2"; orange = "#E5C07B";
    };
  };

  mkOverride = pal: {
    "editor.background" = pal.bg;
    "editor.foreground" = pal.fg;
    "editor.gutter.background" = pal.bg;
    "editor.line_number" = pal.fg2;
    "editor.active_line_number" = pal.fg;
    "editor.active_line.background" = "${pal.bg1}bf";
    background = pal.bg;
    "status_bar.background" = pal.bg;
    "title_bar.background" = pal.bg;
    "tab_bar.background" = pal.bg;
    "tab.inactive_background" = pal.bg1;
    "panel.background" = pal.bg;
    "toolbar.background" = pal.bg1;
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
    border = pal.bg1;
    "border.focused" = pal.blue;
    "border.variant" = pal.bg2;
    "scrollbar.thumb.background" = "${pal.fg}4c";
    text = pal.fg;
    "text.muted" = pal.fg2;
    "text.accent" = pal.blue;
    icon = pal.fg;
    "icon.muted" = pal.fg2;
    "icon.accent" = pal.blue;
    "element.background" = pal.bg1;
    "element.hover" = pal.bg2;
    "element.active" = pal.bg3;
    "element.selected" = pal.bg3;
    "surface.background" = pal.bg1;
    "elevated_surface.background" = pal.bg1;
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
