{ pkgs, ... }:

{
  programs.rio = {
    enable = true;
    settings = {
      "confirm-before-quit" = false;
      theme = "switch-theme";
      "line-height" = 1.18;
      navigation."hide-if-single" = true;
      fonts = {
        size = 15;
        family = "Google Sans Code";
        extras = [ { family = "Symbols Nerd Font Mono"; } ];
      };
      bindings = {
        keys = [
          {
            key = "t";
            "with" = "control | alt";
            action = "CreateTab";
          }
          {
            key = "k";
            "with" = "control | alt | shift";
            action = "MoveDividerUp";
          }
          {
            key = "j";
            "with" = "control | alt | shift";
            action = "MoveDividerDown";
          }
          {
            key = "h";
            "with" = "control | alt | shift";
            action = "MoveDividerLeft";
          }
          {
            key = "l";
            "with" = "control | alt | shift";
            action = "MoveDividerRight";
          }
          {
            key = "j";
            "with" = "control | alt";
            action = "SelectNextSplit";
          }
          {
            key = "k";
            "with" = "control | alt";
            action = "SelectPrevSplit";
          }
        ];
      };
    };
  };
}
