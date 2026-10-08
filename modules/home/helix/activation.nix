{ lib, pkgs, ... }:

{
  # Reapply the Quickshell theme over the freshly linked config
  home.activation.helixThemeSync = lib.hm.dag.entryAfter ["linkGeneration"] ''
    themes="$HOME/.config/quickshell/themes"
    theme_file="$HOME/.config/quickshell/.current-theme"
    if [ -f "$theme_file" ] && [ -f "$themes/themes.json" ]; then
      declare -A C
      C[helix]=$(${pkgs.jq}/bin/jq -r --arg t "$(tr -d '[:space:]' < "$theme_file")" \
        '.[$t].helix // "gruvbox_dark"' "$themes/themes.json")
      source "$themes/apps/helix.sh"
      helix_reload
    fi
  '';
}
