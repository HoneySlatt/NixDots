switch_tuta() {
  command -v switch-tuta-theme &>/dev/null 2>&1 || return 0

  local theme_json
  theme_json=$(printf '{
    "themeId":"quickshell",
    "primary":"%s","on_primary":"%s",
    "primary_container":"%s","on_primary_container":"%s",
    "primary_fixed":"%s","on_primary_fixed":"%s",
    "primary_fixed_dim":"%s","on_primary_fixed_variant":"%s",
    "secondary":"%s","on_secondary":"%s",
    "secondary_container":"%s","on_secondary_container":"%s",
    "secondary_fixed":"%s","on_secondary_fixed":"%s",
    "secondary_fixed_dim":"%s","on_secondary_fixed_variant":"%s",
    "tertiary":"%s","on_tertiary":"%s",
    "tertiary_container":"%s","on_tertiary_container":"%s",
    "tertiary_fixed":"%s","on_tertiary_fixed":"%s",
    "tertiary_fixed_dim":"%s","on_tertiary_fixed_variant":"%s",
    "surface":"%s","on_surface":"%s",
    "surface_container":"%s","surface_container_high":"%s",
    "surface_container_highest":"%s","on_surface_variant":"%s",
    "outline":"%s","outline_variant":"%s","scrim":"#000000",
    "error":"%s","on_error":"%s","error_container":"%s","on_error_container":"%s",
    "warning":"%s","on_warning":"%s","warning_container":"%s","on_warning_container":"%s",
    "success":"%s","on_success":"%s","success_container":"%s","on_success_container":"%s",
    "experimental_primary_container":"%s","experimental_on_primary_container":"%s",
    "experimental_tertiary":"%s",
    "state_bg_hover":"%s44","state_bg_focus":"%s55","state_bg_active":"%s66",
    "tuta_color_nota":"%s",
    "content_accent_tuta_bday":"%s","content_accent_secondary_tuta_bday":"%s",
    "content_bg_tuta_bday":"%s",
    "go_european":"%s","on_go_european":"%s",
    "il_outline":"%s","il_ne_outline":"%s","il_highlight":"%s",
    "il_sign_up_flow_switch":"%s","il_sign_up_flow_switch_2":"%s","il_sign_up_flow_switch_4":"%s",
    "drive_folder":"%s","drive_document":"%s","drive_image":"%s",
    "drive_video":"%s","drive_audio":"%s"
  }' \
    "${C[accent]}"   "${C[crust]}" \
    "${C[surface1]}" "${C[accent]}" \
    "${C[surface2]}" "${C[text]}" \
    "${C[overlay1]}" "${C[accent]}" \
    "${C[blue]}"     "${C[crust]}" \
    "${C[surface1]}" "${C[blue]}" \
    "${C[surface2]}" "${C[text]}" \
    "${C[overlay1]}" "${C[blue]}" \
    "${C[mauve]}"    "${C[crust]}" \
    "${C[surface1]}" "${C[mauve]}" \
    "${C[surface2]}" "${C[text]}" \
    "${C[overlay1]}" "${C[mauve]}" \
    "${C[base]}"     "${C[text]}" \
    "${C[mantle]}"   "${C[surface0]}" \
    "${C[surface1]}" "${C[subtext0]}" \
    "${C[overlay0]}" "${C[surface1]}" \
    "${C[red]}"      "${C[crust]}"    "${C[surface1]}" "${C[red]}" \
    "${C[yellow]}"   "${C[crust]}"    "${C[surface1]}" "${C[yellow]}" \
    "${C[green]}"    "${C[crust]}"    "${C[surface1]}" "${C[green]}" \
    "${C[crust]}"    "${C[accent]}" \
    "${C[accent]}" \
    "${C[surface1]}" "${C[surface1]}" "${C[surface1]}" \
    "${C[accent]}" \
    "${C[pink]}"     "${C[mauve]}" \
    "${C[crust]}" \
    "${C[blue]}"     "${C[crust]}" \
    "${C[crust]}"    "${C[surface0]}" "${C[surface1]}" \
    "${C[surface0]}" "${C[base]}"     "${C[base]}" \
    "${C[yellow]}"   "${C[accent]}"   "${C[green]}" \
    "${C[mauve]}"    "${C[peach]}")

  switch-tuta-theme "$theme_json"
}