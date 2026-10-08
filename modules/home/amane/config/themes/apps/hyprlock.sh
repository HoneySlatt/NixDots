gen_hyprlock_theme() {
  mkdir -p "$HOME/.config/hypr"
  cat > "$HOME/.config/hypr/hyprlock-theme.conf" << EOF
\$hl_background = ${C[base]#\#}
\$hl_surface    = ${C[surface0]#\#}
\$hl_accent     = ${C[accent]#\#}
\$hl_text       = ${C[text]#\#}
\$hl_red        = ${C[red]#\#}
\$hl_yellow     = ${C[yellow]#\#}
\$hl_dim        = ${C[surface1]#\#}
\$hl_bright     = ${C[subtext1]#\#}
EOF
}