switch_umbriel() {
  local theme_file="$HOME/.config/umbriel/theme.toml"

  mkdir -p "$(dirname "$theme_file")"
  cat > "$theme_file" << EOF2
[colors]
background = "${C[base]}"
text_primary = "${C[text]}"
text_muted = "${C[subtext0]}"
accent_primary = "${C[accent_ui]:-${C[accent]}}"
accent_secondary = "${C[teal]}"
warning = "${C[mauve]}"
error = "${C[red]}"
shadow = "${C[crust]}aa"

[colors.border]
focused = "${C[accent_ui]:-${C[accent]}}"
unfocused = "${C[surface0]}"
EOF2
}
