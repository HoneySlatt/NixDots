switch_fastfetch() {
  local dir="${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch"
  [ -f "$dir/base.json" ] || return 0

  local accent="${C[accent]}"
  local h="${accent#\#}"
  local base="${C[base]#\#}"
  local text="${C[text]#\#}"
  local shade

  if [ $((0x${base:0:2} + 0x${base:2:2} + 0x${base:4:2})) -gt \
       $((0x${text:0:2} + 0x${text:2:2} + 0x${text:4:2})) ]; then
    shade=$(printf '#%02x%02x%02x' \
      $((0x${h:0:2} * 85 / 100)) \
      $((0x${h:2:2} * 85 / 100)) \
      $((0x${h:4:2} * 85 / 100)))
  else
    shade=$(printf '#%02x%02x%02x' \
      $((0x${h:0:2} + (255 - 0x${h:0:2}) * 15 / 100)) \
      $((0x${h:2:2} + (255 - 0x${h:2:2}) * 15 / 100)) \
      $((0x${h:4:2} + (255 - 0x${h:4:2}) * 15 / 100)))
    [ "$shade" != "$accent" ] || shade=$(printf '#%02x%02x%02x' \
      $((0x${h:0:2} * 85 / 100)) \
      $((0x${h:2:2} * 85 / 100)) \
      $((0x${h:4:2} * 85 / 100)))
  fi

  # Layout comes from base.json (Home Manager), only the logo colors follow the theme
  local tmp
  tmp=$(mktemp "$dir/config.jsonc.XXXXXX") || return 0
  if jq --arg a "$accent" --arg s "$shade" \
    '.logo.color = {"1": $a, "2": $s, "3": $a, "4": $s, "5": $a, "6": $s}' \
    "$dir/base.json" > "$tmp"; then
    mv "$tmp" "$dir/config.jsonc"
  else
    rm -f "$tmp"
  fi
}
