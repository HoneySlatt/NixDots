let
  esc = builtins.fromJSON ''"\u001b"'';
  # Nerd Font private-use glyphs, written by code point so editors cannot drop them
  glyph = code: builtins.fromJSON ''"\u${code}"'';
  frame = text: { type = "custom"; format = "${esc}[90m${text}"; };
  module = type: key: keyColor: { inherit type key keyColor; };
in
{
  # Layout only: themes/apps/fastfetch.sh renders config.jsonc from it with the theme colors
  xdg.configFile."fastfetch/base.json".text = builtins.toJSON {
    "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
    logo = {
      type = "builtin";
      padding.top = 1;
    };
    modules = [
      "break"
      (frame "┌──────────────────────Hardware──────────────────────┐")
      (module "host" "󰌢  PC" "green")
      (module "cpu" "│ ├󰻠 " "green")
      (module "gpu" "│ ├󰍹 " "green")
      (module "memory" "│ ├󰑭 " "green")
      (frame "└────────────────────────────────────────────────────┘")
      "break"
      (frame "┌──────────────────────Software──────────────────────┐")
      (module "os" "${glyph "e843"}  OS" "yellow")
      (module "kernel" "│ ├${glyph "ebc6"} " "yellow")
      (module "packages" "│ ├󰏗 " "yellow")
      (module "shell" "└ └󰞷 " "yellow")
      "break"
      (module "de" "󰧨  DE" "blue")
      (module "wm" "│ ├󱂬 " "blue")
      (module "wmtheme" "│ ├󰉦 " "blue")
      (module "terminal" "└ └󰆍 " "blue")
      (frame "└────────────────────────────────────────────────────┘")
      "break"
      (frame "┌────────────────────Uptime / Age / DT────────────────────┐")
      ((module "command" "  ›  OS Age  " "magenta") // {
        text = "birth_install=$(stat -c %W /); current=$(date +%s); time_progression=$((current - birth_install)); days_difference=$((time_progression / 86400)); echo $days_difference days";
      })
      (module "uptime" "  ›  Uptime  " "magenta")
      (frame "└─────────────────────────────────────────────────────────┘")
      {
        type = "colors";
        paddingLeft = 2;
        symbol = "circle";
      }
    ];
  };
}
