switch_obs() {
  local theme_dir="$HOME/.config/obs-studio/themes"
  local theme_file="$theme_dir/Quickshell.obt"
  local user_ini="$HOME/.config/obs-studio/user.ini"
  mkdir -p "$theme_dir"

  local is_dark
  is_dark=$([ "$THEME" = "gruvbox-light" ] && echo "false" || echo "true")

  cat > "$theme_file" << EOF
@OBSThemeMeta {
    name: 'Quickshell';
    id: 'io.github.quickshell';
    extends: 'com.obsproject.Yami';
    author: 'quickshell';
    dark: '$is_dark';
}

@OBSThemeVars {
    --bg_window: ${C[mantle]};
    --bg_base: ${C[base]};
    --bg_preview: ${C[crust]};

    --primary: ${C[accent_ui]:-${C[accent]}};
    --primary_light: ${C[blue]};
    --primary_lighter: ${C[sky]};
    --primary_dark: ${C[accent_ui]:-${C[accent]}};
    --primary_darker: ${C[mauve]};

    --warning: ${C[yellow]};
    --danger: ${C[red]};

    --text: ${C[text]};
    --text_light: ${C[subtext1]};
    --text_muted: ${C[subtext0]};
    --text_disabled: ${C[overlay0]};
    --text_inactive: ${C[text]};

    --input_bg: ${C[surface0]};
    --input_bg_hover: ${C[surface1]};
    --input_bg_focus: ${C[surface0]};
    --input_border: ${C[overlay0]};
    --input_border_hover: ${C[overlay1]};
    --input_border_focus: ${C[accent_ui]:-${C[accent]}};

    --border_color: ${C[surface1]};

    --button_bg: ${C[surface0]};
    --button_bg_hover: ${C[surface1]};
    --button_bg_down: ${C[surface2]};
    --button_bg_disabled: ${C[mantle]};
    --button_border: ${C[surface0]};
    --button_border_hover: ${C[overlay0]};
    --button_border_focus: ${C[overlay0]};

    --scrollbar_handle: ${C[surface1]};
    --scrollbar_bg: ${C[base]};
    --scrollbar_hover: ${C[surface2]};
    --scrollbar_down: ${C[overlay0]};
    --scrollbar_border: ${C[surface1]};

    --tab_bg: ${C[mantle]};
    --tab_bg_hover: ${C[surface0]};
    --tab_bg_down: ${C[accent_ui]:-${C[accent]}};
    --tab_bg_disabled: ${C[mantle]};
    --tab_border: ${C[surface1]};
    --tab_border_hover: ${C[overlay0]};
    --tab_border_focus: ${C[accent_ui]:-${C[accent]}};
    --tab_border_selected: ${C[accent_ui]:-${C[accent]}};
}
EOF

  if [ -f "$user_ini" ]; then
    if grep -q "^Theme=" "$user_ini"; then
      sed -i "s|^Theme=.*|Theme=io.github.quickshell|" "$user_ini"
    else
      sed -i '/^\[Appearance\]/a Theme=io.github.quickshell' "$user_ini"
    fi
  fi
}