switch_serein() {
  local data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
  local roots=("$data_home/serein" "$data_home/serein-development")
  if [ -n "${SEREIN_DATA_DIR:-}" ]; then
    roots=("$SEREIN_DATA_DIR")
  fi

  local root themes_dir package sha256 download_bytes package_tmp active_tmp
  for root in "${roots[@]}"; do
    [ -d "$root" ] || continue
    themes_dir="$root/extensions/themes"

    # Serein allows at most eight installed themes.
    if [ ! -d "$themes_dir/quickshell" ] && [ -d "$themes_dir" ] &&
       [ "$(find "$themes_dir" -mindepth 1 -maxdepth 1 -type d | wc -l)" -ge 8 ]; then
      echo "Serein: disable a theme before adding Quickshell (eight-theme limit)." >&2
      continue
    fi

    # Both appearances use the selected Quickshell palette, regardless of OS mode.
    package="$(jq -cn \
      --arg name "Quickshell — ${C[name]}" \
      --arg base "${C[base]}" --arg sidebar "${C[mantle]}" \
      --arg raised "${C[surface0]}" --arg hover "${C[surface1]}" \
      --arg selected "${C[surface2]}" --arg text "${C[text]}" \
      --arg muted "${C[subtext0]}" --arg link "${C[blue]}" \
      --arg accent "${C[accent]}" --arg positive "${C[green]}" \
      --arg warning "${C[yellow]}" --arg danger "${C[red]}" '
      {colors: {
        base: $base, sidebar: $sidebar, chat: $base, raised: $raised,
        hover: $hover, selected: $selected, border: $hover,
        text_strong: $text, text: $text, muted: $muted, link: $link,
        accent: $accent, accent_text: $base, positive: $positive,
        warning: $warning, danger: $danger,
        mention_bg: $raised, mention_text: $accent
      }} as $palette | {
        manifest: {
          api_version: 1, id: "quickshell", name: $name, version: "1.0.0",
          author: "Quickshell", license: "CC0-1.0", source: "",
          kind: "theme", capabilities: [], actions: []
        },
        theme: {light: $palette, dark: $palette}
      }')" || return 1
    sha256="$(printf '%s' "$package" | sha256sum)"
    sha256="${sha256%% *}"
    download_bytes="$(printf '%s' "$package" | wc -c)"

    mkdir -p "$themes_dir/quickshell" || return 1
    package_tmp="$(mktemp "$themes_dir/quickshell/package.json.XXXXXX")" || return 1
    if jq -n --argjson package "$package" --arg sha256 "$sha256" \
      --argjson bytes "$download_bytes" '{
        package: $package, grants: [], reviewed: false, local_theme: true,
        sha256: $sha256, download_bytes: $bytes
      }' > "$package_tmp"; then
      mv "$package_tmp" "$themes_dir/quickshell/package.json" || return 1
    else
      rm -f "$package_tmp"
      return 1
    fi

    # Despite its name, active.json contains the raw ID, without quotes/newline.
    # Serein reads it at startup; external file changes are not hot-reloaded.
    active_tmp="$(mktemp "$themes_dir/active.json.XXXXXX")" || return 1
    printf '%s' quickshell > "$active_tmp"
    mv "$active_tmp" "$themes_dir/active.json" || return 1
  done
}
