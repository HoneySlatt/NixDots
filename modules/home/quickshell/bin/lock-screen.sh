if pgrep -x hyprlock > /dev/null; then
  exit 0
fi

if [ ! -f "$HOME/.config/hypr/hyprlock-theme.conf" ]; then
  THEME_FILE="$HOME/.config/quickshell/.current-theme"
  THEME="carbonfox"
  if [ -f "$THEME_FILE" ]; then
    THEME="$(tr -d '[:space:]' < "$THEME_FILE")"
  fi
  THEMES_DIR="$HOME/.config/quickshell/themes"
  if [ -f "$THEMES_DIR/switch-theme.sh" ]; then
    bash "$THEMES_DIR/switch-theme.sh" "$THEME" >/dev/null 2>&1 || true
  fi
fi

hyprlock --immediate-render
