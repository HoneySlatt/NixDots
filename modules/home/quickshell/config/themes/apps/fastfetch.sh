switch_fastfetch() {
  local config="${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/config.jsonc"
  [ -f "$config" ] || return 0

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

  local colors
  colors=$(cat <<EOF
        // quickshell-theme:fastfetch-colors:start
        "color": {
            "1": "$accent",
            "2": "$shade",
            "3": "$accent",
            "4": "$shade",
            "5": "$accent",
            "6": "$shade"
        },
        // quickshell-theme:fastfetch-colors:end
EOF
)

  local tmp
  tmp=$(mktemp "$config.XXXXXX") || return 0
  FASTFETCH_COLORS="$colors" perl -0pe '
    BEGIN { $colors = $ENV{FASTFETCH_COLORS} . "\n" }
    if (!s{^[ \t]*// quickshell-theme:fastfetch-colors:start\n.*?^[ \t]*// quickshell-theme:fastfetch-colors:end\n}{$colors}ms) {
      s{(^[ \t]*"type"[ \t]*:[ \t]*"builtin",[ \t]*\n)}{$1$colors}m;
    }
  ' "$config" > "$tmp"

  if grep -q 'quickshell-theme:fastfetch-colors:start' "$tmp"; then
    chmod --reference="$config" "$tmp"
    mv "$tmp" "$config"
  else
    rm -f "$tmp"
  fi
}
