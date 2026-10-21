switch_oxi() {
  command -v oxi >/dev/null 2>&1 || return 0

  local theme_dir="${XDG_CONFIG_HOME:-$HOME/.config}/oxi/themes"
  local theme_file="$theme_dir/amane.json"
  local base="dark" theme_tmp
  [ "${C[light]}" = "true" ] && base="light"
  mkdir -p "$theme_dir"
  theme_tmp="$(mktemp "${theme_file}.XXXXXX")" || return 1

  # Oxi reads custom palettes at startup; its Nix wrapper selects this stable id.
  cat > "$theme_tmp" << EOF
{
  "name": "Amane · ${C[name]}",
  "base": "$base",
  "colors": {
    "bg_main": "${C[base]}",
    "bg_sidebar": "${C[crust]}",
    "bg_elevated": "${C[mantle]}",
    "bg_elevated_2": "${C[surface0]}",
    "bg_input": "${C[mantle]}",
    "faint_bg": "${C[surface0]}",
    "border": "${C[surface1]}",
    "border_subtle": "${C[surface0]}",
    "accent": "${C[accent]}",
    "text": "${C[text]}",
    "text_strong": "${C[text]}",
    "text_muted": "${C[subtext0]}",
    "text_faint": "${C[overlay1]}",
    "sidebar_section": "${C[subtext0]}",
    "user_bubble": "${C[surface0]}",
    "success": "${C[green]}",
    "danger": "${C[red]}",
    "diff_add_fg": "${C[green]}",
    "diff_del_fg": "${C[red]}",
    "widget_inactive_bg": "${C[surface0]}",
    "widget_hovered_bg": "${C[surface1]}",
    "widget_active_bg": "${C[surface2]}",
    "widget_open_bg": "${C[surface0]}",
    "widget_active_border": "${C[accent]}",
    "selection_bg": "${C[surface2]}",
    "selection_stroke": "${C[accent]}",
    "md_code_bg": "${C[surface0]}",
    "md_code_block_bg": "${C[mantle]}",
    "md_code_block_header_bg": "${C[surface0]}",
    "md_code_block_border": "${C[surface1]}",
    "md_quote_accent": "${C[accent]}",
    "md_code_fg": "${C[text]}",
    "syntax_foreground": "${C[text]}",
    "syntax_comment": "${C[overlay1]}",
    "syntax_keyword": "${C[mauve]}",
    "syntax_function": "${C[blue]}",
    "syntax_type": "${C[yellow]}",
    "syntax_string": "${C[green]}",
    "syntax_number": "${C[peach]}",
    "syntax_constant": "${C[peach]}",
    "syntax_variable": "${C[text]}",
    "syntax_operator": "${C[sky]}",
    "syntax_tag": "${C[red]}",
    "syntax_attribute": "${C[yellow]}",
    "syntax_regexp": "${C[teal]}"
  }
}
EOF
  mv "$theme_tmp" "$theme_file"
}
