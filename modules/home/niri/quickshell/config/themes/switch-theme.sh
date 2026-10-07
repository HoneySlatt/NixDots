#!/usr/bin/env bash
# Switch theme — btop, gdu, fastfetch, ghostty, kitty, yazi, nvim, gtk, qt, niri, wallpaper,
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

if load_common_palette "$THEME"; then
  :
else
  case "$THEME" in
    carbonfox)
      C[name]="Carbonfox"
      C[base]="#161616" C[mantle]="#121212" C[crust]="#121212"
      C[surface0]="#222222" C[surface1]="#2a2a2a" C[surface2]="#525253"
      C[overlay0]="#6e7074" C[overlay1]="#9a9ca0"
      C[text]="#f2f4f8" C[subtext1]="#dfdfe0" C[subtext0]="#b2b4b8"
      C[red]="#ff0000" C[maroon]="#ff0000" C[rosewater]="#dfdfe0" C[flamingo]="#dfdfe0"
      C[pink]="#c6c6c6" C[mauve]="#ffffff" C[lavender]="#c6c6c6"
      C[blue]="#c6c6c6" C[sapphire]="#a0a0a0" C[sky]="#a0a0a0"
      C[teal]="#808080" C[green]="#a0a0a0" C[yellow]="#c6c6c6"
      C[peach]="#a0a0a0" C[orange]="#a0a0a0"
      C[accent]="#ffffff"
      C[overlay2]="#b2b4b8"
      ;;
    *)
      echo "Unknown theme: $THEME" >&2
      exit 1
      ;;
  esac
fi

# Script-specific keys per theme
case "$THEME" in
  pastelglow)
    C[cat_accent]="pink"
    C[gtk_theme]="Gruvbox-Light" C[gtk_scheme]="prefer-light"
    C[icon_theme]="Papirus-Light"
    C[wallpaper_dir]="PastelGlow"
    ;;
  rosepine)
    C[cat_accent]="lavender"
    C[gtk_theme]="catppuccin-mocha-lavender-standard" C[gtk_scheme]="prefer-dark"
    C[wallpaper_dir]="RosePine"
    ;;
  gruvbox)
    C[cat_accent]="yellow"
    C[gtk_theme]="Gruvbox-Dark" C[gtk_scheme]="prefer-dark"
    C[wallpaper_dir]="GruvboxDark"
    ;;
  everforest)
    C[cat_accent]="green"
    C[gtk_theme]="adw-gtk3-dark" C[gtk_scheme]="prefer-dark"
    C[wallpaper_dir]="Everforest"
    ;;
  carbonfox)
    C[cat_accent]="mauve" C[hypr_accent]="#3a3a3a" C[accent_ui]="#3a3a3a"
    C[gtk_theme]="catppuccin-mocha-lavender-standard" C[gtk_scheme]="prefer-dark"
    C[wallpaper_dir]="Carbonfox"
    ;;
  gruvbox-light)
    C[cat_accent]="yellow"
    C[gtk_theme]="Gruvbox-Light" C[gtk_scheme]="prefer-light"
    C[icon_theme]="Papirus-Light"
    C[wallpaper_dir]="GruvboxLight"
    ;;
esac

# ── Source all app scripts ──────────────────────────────────────────────────
for f in "$SCRIPT_DIR/apps/"*.sh; do
  source "$f"
done

# Slow application updates run in a restartable user service.
if [ "$MODE" = "background" ]; then
  switch_discord
  switch_steam
  switch_heroic
  switch_obsidian
  switch_obs
  switch_firefox
  gen_userstyles
  switch_jellyfin
  switch_kopuz
  switch_cider
  switch_blender
  gen_kdeglobals
  switch_tuta
  switch_opencode
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

# Apply the visible desktop first.
switch_btop
switch_gdu
switch_fastfetch
switch_kitty
switch_ghostty
switch_rio
gen_yazi_theme
nvim_reload
helix_reload
zed_reload
switch_gtk
switch_qt
switch_niri
switch_wallpaper
gen_hyprlock_theme
switch_swaync

systemctl --user restart --no-block quickshell-theme-background.service
flock -u 9
echo "Applied desktop theme: ${C[name]}"
