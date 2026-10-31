switch_t3code() {
  # T3 Code and Pluto (its fork, home ~/.pluto) share the theme format.
  command -v t3 >/dev/null 2>&1 || command -v pluto-server >/dev/null 2>&1 || return 0

  local theme_dir="${XDG_CACHE_HOME:-$HOME/.cache}/amane"
  local theme_file="$theme_dir/t3code.json"
  local appearance="dark" theme_tmp logo_role=""
  [ "${C[light]}" = "true" ] && appearance="light"
  # Pluto keeps its violet logo for themes that set C[logo]="brand". It goes in
  # "colors": the server drops top-level keys it does not know.
  [ "${C[logo]}" = "brand" ] && logo_role=$'\n    "logo": "brand",'
  mkdir -p "$theme_dir"
  theme_tmp="$(mktemp "${theme_file}.XXXXXX")" || return 1

  # Native environment themes update connected desktop clients automatically.
  cat > "$theme_tmp" << EOF
{
  "name": "Amane · ${C[name]}",
  "appearance": "$appearance",
  "canvas": "${C[base]}",
  "accent": "${C[accent]}",
  "colors": {${logo_role}
    "canvas": "${C[base]}",
    "chrome": "${C[mantle]}",
    "toolbar": "${C[mantle]}",
    "toolbarForeground": "${C[text]}",
    "toolbarBorder": "${C[surface1]}",
    "toolbarControl": "${C[surface0]}",
    "toolbarControlForeground": "${C[text]}",
    "toolbarControlHover": "${C[surface1]}",
    "surface": "${C[mantle]}",
    "surfaceRaised": "${C[surface0]}",
    "surfaceOverlay": "${C[surface0]}",
    "text": "${C[text]}",
    "textMuted": "${C[subtext0]}",
    "border": "${C[surface1]}",
    "input": "${C[surface2]}",
    "focus": "${C[accent]}",
    "accent": "${C[accent]}",
    "accentForeground": "${C[base]}",
    "secondary": "${C[surface0]}",
    "secondaryForeground": "${C[text]}",
    "muted": "${C[surface0]}",
    "mutedForeground": "${C[subtext0]}",
    "placeholder": "${C[overlay1]}",
    "secondaryLabel": "${C[subtext0]}",
    "iconMuted": "${C[overlay1]}",
    "error": "${C[red]}",
    "errorForeground": "${C[red]}",
    "warning": "${C[yellow]}",
    "warningForeground": "${C[yellow]}",
    "update": "${C[blue]}",
    "updateForeground": "${C[blue]}",
    "accentSurface": "${C[surface1]}",
    "accentSurfaceForeground": "${C[text]}",
    "messageSurface": "${C[surface0]}",
    "messageForeground": "${C[text]}",
    "messageAction": "${C[accent]}",
    "messageActionForeground": "${C[base]}",
    "messageActionHover": "${C[mauve]}",
    "codeBackground": "${C[mantle]}",
    "codeForeground": "${C[text]}",
    "sidebar": "${C[crust]}",
    "sidebarForeground": "${C[text]}",
    "sidebarMutedForeground": "${C[subtext0]}",
    "sidebarControlSurface": "${C[surface0]}",
    "sidebarRowHover": "${C[surface0]}",
    "sidebarRowActive": "${C[surface1]}",
    "sidebarRowSelected": "${C[surface1]}",
    "sidebarBorder": "${C[surface1]}",
    "terminalBackground": "${C[base]}",
    "terminalForeground": "${C[text]}",
    "terminalCursor": "${C[accent]}",
    "terminalSelection": "${C[surface2]}",
    "terminalScrollbar": "${C[surface1]}",
    "terminalScrollbarHover": "${C[surface2]}"
  }
}
EOF
  mv "$theme_tmp" "$theme_file"
  if command -v t3 >/dev/null 2>&1; then
    t3 theme set --id amane "$theme_file"
  fi
  if command -v pluto-server >/dev/null 2>&1; then
    pluto-server theme set --id amane "$theme_file"
  fi
}
