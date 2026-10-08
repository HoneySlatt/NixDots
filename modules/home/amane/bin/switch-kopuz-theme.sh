toml_conf="$HOME/.config/kopuz/settings.toml"
json_conf="$HOME/.config/kopuz/config.json"
[ -f "$toml_conf" ] || [ -f "$json_conf" ] || exit 0

theme_name="$1"
bg="$2"
raised="$3"
surface="$4"
text_color="$5"
text_muted="$6"
accent="$7"
accent_soft="$8"
accent_alt="$9"
accent_deep="${10}"
highlight="${11}"
highlight_dark="${12}"
progress="${13}"
danger="${14}"

if [ -f "$toml_conf" ]; then
  conf="$toml_conf"
  tmp=$(mktemp "$conf.XXXXXX")
  trap 'rm -f "$tmp"' EXIT

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
  ' "$conf" > "$tmp"

  {
    printf '\n[custom_themes.amane]\n'
    printf 'name = "%s"\n' "$theme_name"
    printf '\n[custom_themes.amane.vars]\n'
    printf 'bg = "%s"\n' "$bg"
    printf 'raised = "%s"\n' "$raised"
    printf 'surface = "%s"\n' "$surface"
    printf 'text = "%s"\n' "$text_color"
    printf 'text-muted = "%s"\n' "$text_muted"
    printf 'accent = "%s"\n' "$accent"
    printf 'accent-soft = "%s"\n' "$accent_soft"
    printf 'accent-alt = "%s"\n' "$accent_alt"
    printf 'accent-deep = "%s"\n' "$accent_deep"
    printf 'highlight = "%s"\n' "$highlight"
    printf 'highlight-dark = "%s"\n' "$highlight_dark"
    printf 'progress = "%s"\n' "$progress"
    printf 'danger = "%s"\n' "$danger"
  } >> "$tmp"

  mv "$tmp" "$conf"
  trap - EXIT
  exit 0
fi

conf="$json_conf"
tmp=$(mktemp "$conf.XXXXXX")
trap 'rm -f "$tmp"' EXIT

jq \
  --arg name "$theme_name" \
  --arg bg "$bg" \
  --arg raised "$raised" \
  --arg surface "$surface" \
  --arg text "$text_color" \
  --arg text_muted "$text_muted" \
  --arg accent "$accent" \
  --arg accent_soft "$accent_soft" \
  --arg accent_alt "$accent_alt" \
  --arg accent_deep "$accent_deep" \
  --arg highlight "$highlight" \
  --arg highlight_dark "$highlight_dark" \
  --arg progress "$progress" \
  --arg danger "$danger" \
  '.theme = "amane"
    | del(.custom_themes.quickshell)
    | .custom_themes = (.custom_themes // {})
    | .custom_themes.amane = {
        name: $name,
        vars: {
          "bg": $bg,
          "raised": $raised,
          "surface": $surface,
          "text": $text,
          "text-muted": $text_muted,
          "accent": $accent,
          "accent-soft": $accent_soft,
          "accent-alt": $accent_alt,
          "accent-deep": $accent_deep,
          "highlight": $highlight,
          "highlight-dark": $highlight_dark,
          "progress": $progress,
          "danger": $danger
        }
      }' "$conf" > "$tmp" && mv "$tmp" "$conf"

trap - EXIT
