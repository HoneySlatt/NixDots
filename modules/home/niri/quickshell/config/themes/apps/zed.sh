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
  local mode="dark" theme_name="One Dark"
  case "$zf" in
    pastelglow|gruvbox-light) mode="light"; theme_name="One Light" ;;
  esac
  local cfg="$HOME/.config/zed/settings.json" tmp
  tmp="$(mktemp "${cfg}.XXXXXX")" || return 1
  if jq --slurpfile p "$pal" --arg mode "$mode" --arg name "$theme_name" '
    .theme = {mode: $mode, dark: "One Dark", light: "One Light"}
    | .theme_overrides[$name] = $p[0]
  ' "$cfg" > "$tmp"; then
    mv "$tmp" "$cfg"
  else
    rm -f "$tmp"
    return 1
  fi
}
