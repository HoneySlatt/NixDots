switch_gtk() {
  local scheme="${C[gtk_scheme]}"
  local icons="${C[icon_theme]:-Papirus-Dark}"
  local prefer_dark
  prefer_dark=$([ "$scheme" = "prefer-dark" ] && echo 1 || echo 0)

  # Replaces read-only leftovers from when Home Manager owned these files
  write_file() {
    rm -f "$1"
    printf '%s\n' "$2" > "$1"
  }

  mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

  local gtk_base_theme
  [ "$scheme" = "prefer-light" ] && gtk_base_theme="adw-gtk3" || gtk_base_theme="adw-gtk3-dark"

  local settings_block="[Settings]
gtk-theme-name=$gtk_base_theme
gtk-application-prefer-dark-theme=$prefer_dark
gtk-font-name=Google Sans Flex 10
gtk-icon-theme-name=$icons
gtk-cursor-theme-name=phinger-cursors-dark
gtk-cursor-theme-size=24"

  write_file "$HOME/.config/gtk-3.0/settings.ini" "$settings_block"
  write_file "$HOME/.config/gtk-4.0/settings.ini" "$settings_block"

  local gtk_css
  gtk_css=$(cat << EOF
@define-color accent_color ${C[accent]};
@define-color accent_bg_color ${C[accent]};
@define-color accent_fg_color ${C[base]};
@define-color destructive_color ${C[red]};
@define-color destructive_bg_color ${C[red]};
@define-color destructive_fg_color ${C[base]};
@define-color success_color ${C[green]};
@define-color success_bg_color ${C[green]};
@define-color success_fg_color ${C[base]};
@define-color warning_color ${C[yellow]};
@define-color warning_bg_color ${C[yellow]};
@define-color warning_fg_color ${C[base]};
@define-color error_color ${C[red]};
@define-color error_bg_color ${C[red]};
@define-color error_fg_color ${C[base]};
@define-color window_bg_color ${C[base]};
@define-color window_fg_color ${C[text]};
@define-color view_bg_color ${C[mantle]};
@define-color view_fg_color ${C[text]};
@define-color headerbar_bg_color ${C[crust]};
@define-color headerbar_fg_color ${C[text]};
@define-color headerbar_border_color ${C[surface0]};
@define-color headerbar_backdrop_color ${C[mantle]};
@define-color headerbar_shade_color ${C[crust]};
@define-color card_bg_color ${C[surface0]};
@define-color card_fg_color ${C[text]};
@define-color card_shade_color ${C[crust]};
@define-color dialog_bg_color ${C[base]};
@define-color dialog_fg_color ${C[text]};
@define-color popover_bg_color ${C[surface0]};
@define-color popover_fg_color ${C[text]};
@define-color shade_color ${C[crust]};
@define-color scrollbar_outline_color ${C[crust]};
@define-color sidebar_bg_color ${C[mantle]};
@define-color sidebar_fg_color ${C[text]};
@define-color sidebar_backdrop_color ${C[base]};
@define-color sidebar_shade_color ${C[crust]};
@define-color thumbnail_bg_color ${C[surface0]};
@define-color thumbnail_fg_color ${C[text]};
EOF
)
  write_file "$HOME/.config/gtk-3.0/gtk.css" "$gtk_css"
  write_file "$HOME/.config/gtk-4.0/gtk.css" "$gtk_css"

  if command -v dconf &>/dev/null; then
    dconf write /org/gnome/desktop/interface/gtk-theme      "'$gtk_base_theme'" 2>/dev/null || true
    dconf write /org/gnome/desktop/interface/color-scheme   "'$scheme'"    2>/dev/null || true
    dconf write /org/gnome/desktop/interface/font-name      "'Google Sans Flex 10'" 2>/dev/null || true
    dconf write /org/gnome/desktop/interface/document-font-name "'Google Sans Flex 10'" 2>/dev/null || true
    dconf write /org/gnome/desktop/interface/monospace-font-name "'Google Sans Code 10'" 2>/dev/null || true
    dconf write /org/gnome/desktop/interface/icon-theme     "'$icons'"     2>/dev/null || true
  fi
}
