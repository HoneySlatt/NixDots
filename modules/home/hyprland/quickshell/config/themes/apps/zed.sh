zed_reload() {
  local zf
  case "$THEME" in
    pastelglow)    zf="pastelglow" ;;
    rosepine)      zf="rosepine" ;;
    gruvbox)       zf="gruvbox" ;;
    gruvbox-light) zf="gruvbox-light" ;;
    carbonfox)     zf="carbonfox" ;;
    everforest)    zf="everforest" ;;
    *)             zf="gruvbox" ;;
  esac
  local pal="$HOME/.config/zed/theme-overrides/${zf}.json"
  [ -f "$pal" ] || return
  local cfg="$HOME/.config/zed/settings.json"
  if [ -L "$cfg" ]; then
    cp "$cfg" "$cfg.tmp" && rm "$cfg" && mv "$cfg.tmp" "$cfg"
  fi
  jq --slurpfile p "$pal" '.theme_overrides."One Dark" = $p[0]' \
    "$cfg" > /tmp/zed-settings.json \
    && mv /tmp/zed-settings.json "$cfg"
}
