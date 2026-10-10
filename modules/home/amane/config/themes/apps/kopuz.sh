switch_kopuz() {
  local dir="$HOME/.config/kopuz"
  [ -d "$dir" ] || return 0

  # Kopuz polls this palette while its "live" theme is selected and recolours in place.
  local tmp
  tmp=$(mktemp "$dir/matugen.json.XXXXXX") || return 0
  printf '{
  "bg": "%s",
  "raised": "%s",
  "surface": "%s",
  "text": "%s",
  "text-muted": "%s",
  "accent": "%s",
  "accent-soft": "%s",
  "accent-alt": "%s",
  "accent-deep": "%s",
  "highlight": "%s",
  "highlight-dark": "%s",
  "progress": "%s",
  "danger": "%s"
}\n' \
    "${C[base]}" "${C[surface0]}" "${C[surface1]}" "${C[text]}" "${C[subtext0]}" \
    "${C[accent]}" "${C[sapphire]}" "${C[blue]}" "${C[crust]}" \
    "${C[mauve]}" "${C[pink]}" "${C[green]}" "${C[red]}" > "$tmp"
  mv "$tmp" "$dir/matugen.json"

  local toml_conf="$dir/settings.toml"
  [ -f "$toml_conf" ] && sed -i '0,/^\[/ s/^theme = .*/theme = "live"/' "$toml_conf"
  return 0
}
