switch_opencode() {
  local themes_dir="$HOME/.config/opencode/themes"
  local tui_conf="$HOME/.config/opencode/tui.json"
  mkdir -p "$themes_dir"

  cat > "$themes_dir/quickshell.json" << EOF
{
  "\$schema": "https://opencode.ai/theme.json",
  "theme": {
    "primary":                 "${C[accent]}",
    "secondary":               "${C[blue]}",
    "accent":                  "${C[accent]}",
    "error":                   "${C[red]}",
    "warning":                 "${C[yellow]}",
    "success":                 "${C[green]}",
    "info":                    "${C[sapphire]}",
    "text":                    "${C[text]}",
    "textMuted":               "${C[subtext0]}",
    "background":              "${C[base]}",
    "backgroundPanel":         "${C[mantle]}",
    "backgroundElement":       "${C[surface0]}",
    "border":                  "${C[surface1]}",
    "borderActive":            "${C[accent]}",
    "borderSubtle":            "${C[surface0]}",
    "diffAdded":               "${C[green]}",
    "diffRemoved":             "${C[red]}",
    "diffContext":             "${C[overlay0]}",
    "diffHunkHeader":          "${C[overlay0]}",
    "diffHighlightAdded":      "${C[green]}",
    "diffHighlightRemoved":    "${C[red]}",
    "diffAddedBg":             "${C[surface0]}",
    "diffRemovedBg":           "${C[surface0]}",
    "diffContextBg":           "${C[mantle]}",
    "diffLineNumber":          "${C[overlay0]}",
    "diffAddedLineNumberBg":   "${C[surface0]}",
    "diffRemovedLineNumberBg": "${C[surface0]}",
    "markdownText":            "${C[text]}",
    "markdownHeading":         "${C[accent]}",
    "markdownLink":            "${C[blue]}",
    "markdownLinkText":        "${C[sapphire]}",
    "markdownCode":            "${C[green]}",
    "markdownBlockQuote":      "${C[overlay1]}",
    "markdownEmph":            "${C[peach]}",
    "markdownStrong":          "${C[yellow]}",
    "markdownHorizontalRule":  "${C[surface1]}",
    "markdownListItem":        "${C[accent]}",
    "markdownListEnumeration": "${C[blue]}",
    "markdownImage":           "${C[blue]}",
    "markdownImageText":       "${C[sapphire]}",
    "markdownCodeBlock":       "${C[text]}",
    "syntaxComment":           "${C[overlay0]}",
    "syntaxKeyword":           "${C[mauve]}",
    "syntaxFunction":          "${C[blue]}",
    "syntaxVariable":          "${C[text]}",
    "syntaxString":            "${C[green]}",
    "syntaxNumber":            "${C[peach]}",
    "syntaxType":              "${C[yellow]}",
    "syntaxOperator":          "${C[sky]}",
    "syntaxPunctuation":       "${C[text]}"
  }
}
EOF

  printf '{ "theme": "quickshell" }\n' > "$tui_conf"

  # Desktop has its own palette format and native v1/v2 color tokens.
  local desktop_conf="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/quickshell-desktop.json"
  local mode="dark" desktop_tmp
  [ "${C[gtk_scheme]}" = "prefer-light" ] && mode="light"
  mkdir -p "$(dirname "$desktop_conf")"
  desktop_tmp="$(mktemp "${desktop_conf}.XXXXXX")"
  if jq --arg name "${C[name]}" --arg mode "$mode" '
    .theme as $t | {
      name: $name, mode: $mode,
      variant: {
        palette: {
          neutral: $t.background, ink: $t.text, primary: $t.primary,
          accent: $t.accent, interactive: $t.accent,
          success: $t.success, warning: $t.warning, error: $t.error, info: $t.info
        },
        overrides: ({
          "background-base": $t.background,
          "background-stronger": $t.backgroundPanel,
          "background-weak": $t.backgroundElement,
          "surface-raised-base": $t.backgroundPanel,
          "surface-raised-strong": $t.backgroundElement,
          "input-base": $t.backgroundPanel,
          "text-base": $t.text, "text-strong": $t.text, "text-weak": $t.textMuted,
          "border-base": $t.border, "border-weak-base": $t.borderSubtle
        } + ($t | with_entries(
          select(.key | test("^(syntax|markdown)")) |
          .key |= (gsub("(?<c>[A-Z])"; "-\(.c)") | ascii_downcase)
        ))),
        v2Overrides: {
          "v2-background-bg-base": $t.background,
          "v2-background-bg-deep": $t.backgroundPanel,
          "v2-background-bg-layer-01": $t.backgroundElement,
          "v2-background-bg-layer-02": $t.border,
          "v2-background-bg-layer-03": $t.border,
          "v2-background-bg-layer-04": $t.textMuted,
          "v2-background-bg-button-neutral": $t.backgroundElement,
          "v2-text-text-accent": $t.accent,
          "v2-border-border-focus": $t.accent
        }
      }
    }
  ' "$themes_dir/quickshell.json" > "$desktop_tmp"; then
    mv "$desktop_tmp" "$desktop_conf"
  else
    rm -f "$desktop_tmp"
    return 1
  fi
}
