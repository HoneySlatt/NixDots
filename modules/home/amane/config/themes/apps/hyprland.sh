live_reload() {
  if command -v hyprctl &>/dev/null; then
    local active_hex="${C[hypr_accent]:-${C[accent]}}"
    active_hex="${active_hex#\#}"
    local inactive_hex="${C[surface0]#\#}"
    local lua="hl.config({ general = { col = { active_border = \"rgba(${active_hex}ff)\", inactive_border = \"rgba(${inactive_hex}ff)\" } } })"

    hyprctl eval "$lua" >/dev/null 2>&1 || hyprctl -i 0 eval "$lua" >/dev/null 2>&1 || true
  fi
}
