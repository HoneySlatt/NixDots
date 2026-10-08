switch_niri() {
  local theme_file="$HOME/.config/niri/theme.kdl"
  local active="${C[hypr_accent]:-${C[accent]}}"
  local inactive="${C[surface0]}"

  mkdir -p "$(dirname "$theme_file")"
  cat > "$theme_file" << EOF2
layout {
    border {
        on
        active-color "${active}"
        inactive-color "${inactive}"
    }
    shadow {
        color "${C[crust]}aa"
    }
}
EOF2
}
