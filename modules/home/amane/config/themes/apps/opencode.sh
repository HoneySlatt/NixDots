switch_opencode() {
  local themes_dir="$HOME/.config/opencode/themes"
  local tui_conf="$HOME/.config/opencode/tui.json"
  mkdir -p "$themes_dir"

  cat > "$themes_dir/amane.json" << EOF
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

  printf '{ "theme": "amane" }\n' > "$tui_conf"
}
