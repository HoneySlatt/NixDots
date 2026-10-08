switch_cosmic() {
  local root="$HOME/.config/cosmic"
  local variant="Dark" is_dark=true
  [ "${C[light]}" = true ] && variant="Light" is_dark=false
  local dir="$root/com.system76.CosmicTheme.$variant/v2"
  mkdir -p "$dir" "$root/com.system76.CosmicTheme.Mode/v1"

  # "#rrggbb" + alpha -> "#RRGGBBAA"
  rgba() { local c="${1#\#}"; printf '"#%s%s"' "${c^^}" "${2:-FF}"; }

  # args: base hover pressed on border
  component() {
    cat << EOF
(
    base: $1,
    hover: $2,
    pressed: $3,
    selected: $2,
    selected_text: $(rgba "${C[accent]}"),
    focus: $(rgba "${C[accent]}"),
    divider: $(rgba "$4" 33),
    on: $(rgba "$4"),
    disabled: ${1:0:8}80",
    on_disabled: $(rgba "$4" A6),
    border: $(rgba "$5"),
    disabled_border: $(rgba "$5" 80),
)
EOF
  }

  # args: base component-base component-hover component-pressed alpha
  container() {
    local a="${5:-FF}"
    cat << EOF
(
    base: $(rgba "$1" "$a"),
    component: $(component "$(rgba "$2" "$a")" "$(rgba "$3" "$a")" "$(rgba "$4" "$a")" "${C[text]}" "${C[overlay0]}"),
    divider: $(rgba "${C[surface1]}"),
    on: $(rgba "${C[text]}"),
    small_widget: $(rgba "${C[surface0]}" 40),
)
EOF
  }

  # args: color
  solid() {
    component "$(rgba "$1")" "$(rgba "$1" D9)" "$(rgba "$1" B3)" "${C[base]}" "$1"
  }

  # args: base-alpha hover-alpha pressed-alpha on
  flat() {
    component "$(rgba "${C[overlay0]}" "$1")" "$(rgba "${C[overlay0]}" "$2")" \
              "$(rgba "${C[overlay0]}" "$3")" "$4" "${C[overlay0]}"
  }

  container "${C[base]}"     "${C[surface0]}" "${C[surface1]}" "${C[surface2]}"     > "$dir/background"
  container "${C[mantle]}"   "${C[surface0]}" "${C[surface1]}" "${C[surface2]}"     > "$dir/primary"
  container "${C[surface0]}" "${C[surface1]}" "${C[surface2]}" "${C[overlay0]}"     > "$dir/secondary"
  container "${C[base]}"     "${C[surface0]}" "${C[surface1]}" "${C[surface2]}" 99  > "$dir/transparent_background"
  container "${C[mantle]}"   "${C[surface0]}" "${C[surface1]}" "${C[surface2]}" E6  > "$dir/transparent_primary"
  container "${C[surface0]}" "${C[surface1]}" "${C[surface2]}" "${C[overlay0]}"     > "$dir/transparent_secondary"

  solid "${C[accent]}" | tee "$dir/accent" > "$dir/accent_button"
  solid "${C[green]}"  | tee "$dir/success" > "$dir/success_button"
  solid "${C[red]}"    | tee "$dir/destructive" > "$dir/destructive_button"
  solid "${C[yellow]}" | tee "$dir/warning" > "$dir/warning_button"

  flat 40 66 99 "${C[text]}"  > "$dir/button"
  flat 00 33 66 "${C[text]}"  | tee "$dir/icon_button" > "$dir/list_button"
  flat 00 33 66 "${C[accent]}" > "$dir/text_button"
  flat 00 00 00 "${C[accent]}" > "$dir/link_button"

  printf '%s\n' "$is_dark" > "$dir/is_dark"
  printf '"%s"\n' "${C[name]}" > "$dir/name"
  mkdir -p "$root/com.system76.CosmicTk/v1"
  printf '"%s"\n' "${C[icon_theme]:-kora}" > "$root/com.system76.CosmicTk/v1/icon_theme"
  # Mode last so apps switch variant once its theme is complete
  printf '%s\n' "$is_dark" > "$root/com.system76.CosmicTheme.Mode/v1/is_dark"
}
