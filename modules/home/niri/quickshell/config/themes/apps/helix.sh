helix_reload() {
  local hx_theme
  case "$THEME" in
    pastelglow)    hx_theme="pastelglow" ;;
    rosepine)      hx_theme="rose_pine" ;;
    gruvbox)       hx_theme="gruvbox_dark" ;;
    gruvbox-light) hx_theme="gruvbox_light" ;;
    carbonfox)     hx_theme="carbonfox" ;;
    everforest)    hx_theme="everforest_dark" ;;
    *)             hx_theme="gruvbox_dark" ;;
  esac
  local cfg="$HOME/.config/helix/config.toml"
  if [ -L "$cfg" ]; then
    cp "$cfg" "$cfg.tmp" && rm "$cfg" && mv "$cfg.tmp" "$cfg"
  fi
  sed -i "s/^theme = .*/theme = \"$hx_theme\"/" "$cfg"
  pkill -USR1 -u "$USER" -x hx 2>/dev/null || true
}
