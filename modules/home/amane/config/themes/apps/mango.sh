switch_mango() {
  # Sourced last by modules/home/mango, which reloads when it changes
  local theme_file="$HOME/.config/mango/theme.conf"
  local active="${C[accent_ui]:-${C[accent]}}"
  local inactive="${C[surface0]}"

  mkdir -p "$(dirname "$theme_file")"
  cat > "$theme_file" << EOF2
focus_color=0x${active#\#}ff
border_color=0x${inactive#\#}ff
shadows_color=0x${C[crust]#\#}aa
EOF2
}
