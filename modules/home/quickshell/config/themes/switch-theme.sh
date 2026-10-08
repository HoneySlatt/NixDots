#!/usr/bin/env bash
# Switch theme — btop, gdu, fastfetch, ghostty, yazi, nvim, gtk, qt, niri, hyprland, wallpaper,
# discord, steam, heroic, obsidian, obs, firefox, userstyles, jellyfin, kopuz, cider,
# blender, kdeglobals, hyprlock, tuta, opencode

MODE="full"
THEME_FILE="$HOME/.config/quickshell/.current-theme"
THEME="${1:-pastelglow}"
REQUEST_ID="${2:-$(date +%s%3N)00}"

if [ "$THEME" = "--background-current" ]; then
  MODE="background"

  if [ -f "$THEME_FILE" ]; then
    THEME="$(tr -d '[:space:]' < "$THEME_FILE")"
  else
    THEME="pastelglow"
  fi
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

declare -A C
source "$SCRIPT_DIR/themes.conf"

if ! load_palette "$THEME"; then
  echo "Unknown theme: $THEME" >&2
  exit 1
fi

# Script-specific keys per theme
case "$THEME" in
  pastelglow)
    C[cat_accent]="pink"
    C[gtk_theme]="Gruvbox-Light" C[gtk_scheme]="prefer-light"
    C[icon_theme]="Papirus-Light"
    ;;
  rosepine)
    C[cat_accent]="lavender"
    C[gtk_theme]="catppuccin-mocha-lavender-standard" C[gtk_scheme]="prefer-dark"
    ;;
  gruvbox)
    C[cat_accent]="yellow"
    C[gtk_theme]="Gruvbox-Dark" C[gtk_scheme]="prefer-dark"
    ;;
  everforest)
    C[cat_accent]="green"
    C[gtk_theme]="adw-gtk3-dark" C[gtk_scheme]="prefer-dark"
    ;;
  carbonfox)
    C[cat_accent]="mauve" C[hypr_accent]="#3a3a3a" C[accent_ui]="#3a3a3a"
    C[gtk_theme]="catppuccin-mocha-lavender-standard" C[gtk_scheme]="prefer-dark"
    ;;
  gruvbox-light)
    C[cat_accent]="yellow"
    C[gtk_theme]="Gruvbox-Light" C[gtk_scheme]="prefer-light"
    C[icon_theme]="Papirus-Light"
    ;;
esac

# Metadata shared with Theme.qml, Neovim and wallpaper-rotation: light, wallpaperDir, nvim, helix
while IFS="=" read -r key value; do
  C[$key]="$value"
done < <(jq -r --arg t "$THEME" '.[$t] | to_entries[] | "\(.key)=\(.value)"' "$SCRIPT_DIR/themes.json")

# ── Source all app scripts ──────────────────────────────────────────────────
for f in "$SCRIPT_DIR/apps/"*.sh; do
  source "$f"
done

# Slow application updates run in a restartable user service.
if [ "$MODE" = "background" ]; then
  # gen_userstyles appends to the userContent.css written by switch_firefox
  { switch_firefox; gen_userstyles; } &
  for fn in switch_discord switch_steam switch_heroic switch_obsidian switch_obs switch_jellyfin \
            switch_kopuz switch_cider switch_blender gen_kdeglobals switch_tuta switch_opencode; do
    "$fn" &
  done
  wait
  echo "Finished background theme update: ${C[name]}"
  exit 0
fi

request_dir="$HOME/.cache/quickshell"
request_file="$request_dir/theme-request-id"
mkdir -p "$request_dir"
exec 9>"$request_dir/theme-switch.lock"
flock 9

last_request=0
if [ -f "$request_file" ]; then
  last_request="$(tr -dc '0-9' < "$request_file")"
fi

if [ -n "$last_request" ] && [ "$REQUEST_ID" -le "$last_request" ]; then
  exit 0
fi

request_tmp="$(mktemp "${request_file}.XXXXXX")"
printf '%s\n' "$REQUEST_ID" > "$request_tmp"
mv "$request_tmp" "$request_file"

mkdir -p "$(dirname "$THEME_FILE")"
theme_tmp="$(mktemp "${THEME_FILE}.XXXXXX")"
printf '%s\n' "$THEME" > "$theme_tmp"
mv "$theme_tmp" "$THEME_FILE"

# Desktop-wide changes first, then every app in parallel (each writes its own files).
switch_niri
live_reload
switch_wallpaper
systemctl --user restart --no-block quickshell-theme-background.service

for fn in switch_btop switch_gdu switch_fastfetch switch_ghostty switch_rio gen_yazi_theme nvim_reload \
          helix_reload zed_reload switch_gtk switch_qt gen_hyprlock_theme switch_swaync; do
  "$fn" &
done
wait
flock -u 9
echo "Applied desktop theme: ${C[name]}"
