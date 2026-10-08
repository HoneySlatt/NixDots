zed_reload() {
  local pal="$HOME/.config/zed/theme-overrides/$THEME.json"
  [ -f "$pal" ] || return
  local mode="dark" theme_name="One Dark"
  [ "${C[light]}" = true ] && mode="light" theme_name="One Light"
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
