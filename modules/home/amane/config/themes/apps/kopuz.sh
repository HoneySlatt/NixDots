switch_kopuz() {
  local toml_conf="$HOME/.config/kopuz/settings.toml"
  if [ -f "$toml_conf" ]; then
    local theme_name="Amane ${C[name]}"
    local tmp

    tmp=$(mktemp "$toml_conf.XXXXXX") || return 0
    awk '
      BEGIN {
        count = 0
        first_section = 0
        in_amane = 0
        seen_section = 0
        theme_set = 0
      }
      /^[[:space:]]*\[/ {
        header = $0
        sub(/^[[:space:]]*\[+/, "", header)
        sub(/\]+[[:space:]]*(#.*)?$/, "", header)
        in_amane = (header ~ /^custom_themes\.(amane|quickshell)(\.vars)?$/)
        seen_section = 1
        if (first_section == 0) first_section = count + 1
        if (in_amane) next
      }
      in_amane { next }
      !seen_section && !theme_set && /^[[:space:]]*theme[[:space:]]*=/ {
        lines[++count] = "theme = \"amane\""
        theme_set = 1
        next
      }
      { lines[++count] = $0 }
      END {
        insert_at = first_section ? first_section : count + 1
        for (i = 1; i <= count; i++) {
          if (!theme_set && i == insert_at) print "theme = \"amane\""
          print lines[i]
        }
        if (!theme_set && insert_at == count + 1) print "theme = \"amane\""
      }
    ' "$toml_conf" > "$tmp" || {
      rm -f "$tmp"
      return 0
    }

    {
      printf '\n[custom_themes.amane]\n'
      printf 'name = "%s"\n' "$theme_name"
      printf '\n[custom_themes.amane.vars]\n'
      printf 'bg = "%s"\n' "${C[base]}"
      printf 'raised = "%s"\n' "${C[surface0]}"
      printf 'surface = "%s"\n' "${C[surface1]}"
      printf 'text = "%s"\n' "${C[text]}"
      printf 'text-muted = "%s"\n' "${C[subtext0]}"
      printf 'accent = "%s"\n' "${C[accent]}"
      printf 'accent-soft = "%s"\n' "${C[sapphire]}"
      printf 'accent-alt = "%s"\n' "${C[blue]}"
      printf 'accent-deep = "%s"\n' "${C[crust]}"
      printf 'highlight = "%s"\n' "${C[mauve]}"
      printf 'highlight-dark = "%s"\n' "${C[pink]}"
      printf 'progress = "%s"\n' "${C[green]}"
      printf 'danger = "%s"\n' "${C[red]}"
    } >> "$tmp"

    mv "$tmp" "$toml_conf"
    return 0
  fi

  command -v switch-kopuz-theme >/dev/null 2>&1 || return 0

  switch-kopuz-theme \
    "Amane ${C[name]}" \
    "${C[base]}" \
    "${C[surface0]}" \
    "${C[surface1]}" \
    "${C[text]}" \
    "${C[subtext0]}" \
    "${C[accent]}" \
    "${C[sapphire]}" \
    "${C[blue]}" \
    "${C[crust]}" \
    "${C[mauve]}" \
    "${C[pink]}" \
    "${C[green]}" \
    "${C[red]}"
}
