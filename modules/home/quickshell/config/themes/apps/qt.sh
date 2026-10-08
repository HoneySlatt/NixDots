switch_qt() {
  local icons="${C[icon_theme]:-Papirus-Dark}"
  local local_kvantum="$HOME/.config/Kvantum"
  local theme_dir="$local_kvantum/quickshell-theme"

  mkdir -p "$theme_dir"

  local svg_src="$local_kvantum/KvAdaptaDark/KvAdaptaDark.svg"
  if [ ! -f "$svg_src" ]; then
    svg_src=$(find /nix/store -maxdepth 5 -name "KvAdaptaDark.svg" \
      -path "*/Kvantum/*" 2>/dev/null | head -1)
  fi

  if [ -n "$svg_src" ] && [ -f "$svg_src" ]; then
    local svg_tmp
    svg_tmp=$(mktemp)
    sed \
      -e "s/#00bcd4/${C[accent]}/gI" \
      -e "s/#00c3dc/${C[accent]}/gI" \
      -e "s/#008dd4/${C[blue]}/gI" \
      -e "s/#4db6ac/${C[teal]}/gI" \
      -e "s/#263238/${C[base]}/g" \
      -e "s/#1e282d/${C[crust]}/g" \
      -e "s/#141b1e/${C[crust]}/g" \
      -e "s/#212b30/${C[crust]}/g" \
      -e "s/#212c31/${C[crust]}/g" \
      -e "s/#222d32/${C[mantle]}/g" \
      -e "s/#29353b/${C[mantle]}/g" \
      -e "s/#2d3a41/${C[mantle]}/g" \
      -e "s/#28343a/${C[surface0]}/g" \
      -e "s/#293439/${C[surface0]}/g" \
      -e "s/#2d393f/${C[surface0]}/g" \
      -e "s/#304048/${C[surface1]}/g" \
      -e "s/#314047/${C[surface1]}/g" \
      -e "s/#39444a/${C[surface1]}/g" \
      -e "s/#3e4a50/${C[surface1]}/g" \
      -e "s/#275f59/${C[surface2]}/g" \
      -e "s/#2d4c4f/${C[surface2]}/g" \
      -e "s/#556165/${C[overlay0]}/g" \
      -e "s/#565b5e/${C[overlay0]}/g" \
      -e "s/#60727c/${C[overlay0]}/g" \
      -e "s/#6c787d/${C[overlay1]}/g" \
      -e "s/#717b81/${C[overlay1]}/g" \
      -e "s/#7f898f/${C[overlay1]}/g" \
      -e "s/#a6afb4/${C[subtext0]}/g" \
      -e "s/#acb1bc/${C[subtext0]}/g" \
      -e "s/#cfd8dc/${C[subtext1]}/g" \
      -e "s/#000931/${C[crust]}/g" \
      -e "s/#192023/${C[crust]}/g" \
      -e "s/#252f35/${C[mantle]}/g" \
      "$svg_src" > "$svg_tmp" && mv -f "$svg_tmp" "$theme_dir/quickshell-theme.svg"
    chmod 644 "$theme_dir/quickshell-theme.svg"
  fi

  local kvcfg_src="$local_kvantum/KvAdaptaDark/KvAdaptaDark.kvconfig"
  if [ ! -f "$kvcfg_src" ]; then
    kvcfg_src=$(find /nix/store -maxdepth 5 -name "KvAdaptaDark.kvconfig" \
      -path "*/Kvantum/*" 2>/dev/null | head -1)
  fi
  if [ -n "$kvcfg_src" ] && [ -f "$kvcfg_src" ]; then
    local kvcfg_tmp
    kvcfg_tmp=$(mktemp)
    sed \
      -e "s|^window\.color=.*|window.color=${C[base]}|" \
      -e "s|^base\.color=.*|base.color=${C[mantle]}|" \
      -e "s|^alt\.base\.color=.*|alt.base.color=${C[crust]}|" \
      -e "s|^button\.color=.*|button.color=${C[surface0]}|" \
      -e "s|^light\.color=.*|light.color=${C[surface1]}|" \
      -e "s|^mid\.light\.color=.*|mid.light.color=${C[surface0]}|" \
      -e "s|^dark\.color=.*|dark.color=${C[crust]}|" \
      -e "s|^mid\.color=.*|mid.color=${C[mantle]}|" \
      -e "s|^highlight\.color=.*|highlight.color=${C[accent]}|" \
      -e "s|^inactive\.highlight\.color=.*|inactive.highlight.color=${C[surface1]}|" \
      -e "s|^text\.color=.*|text.color=${C[text]}|" \
      -e "s|^window\.text\.color=.*|window.text.color=${C[subtext1]}|" \
      -e "s|^button\.text\.color=.*|button.text.color=${C[subtext1]}|" \
      -e "s|^disabled\.text\.color=.*|disabled.text.color=${C[overlay0]}|" \
      -e "s|^tooltip\.text\.color=.*|tooltip.text.color=${C[text]}|" \
      -e "s|^highlight\.text\.color=.*|highlight.text.color=${C[base]}|" \
      -e "s|^link\.color=.*|link.color=${C[blue]}|" \
      -e "s|^link\.visited\.color=.*|link.visited.color=${C[mauve]}|" \
      -e "s|^progress\.indicator\.text\.color=.*|progress.indicator.text.color=${C[base]}|" \
      "$kvcfg_src" > "$kvcfg_tmp" && mv -f "$kvcfg_tmp" "$theme_dir/quickshell-theme.kvconfig"
  fi

  cat > "$local_kvantum/kvantum.kvconfig" << EOF
[General]
theme=quickshell-theme
EOF

  local font_str="Google Sans Flex,10,-1,5,50,0,0,0,0,0"
  local fixed_str="Google Sans Code,10,-1,5,50,0,0,0,0,0"
  for ct_dir in "$HOME/.config/qt5ct" "$HOME/.config/qt6ct"; do
    mkdir -p "$ct_dir"
    cat > "$ct_dir/$(basename "$ct_dir").conf" << EOF
[Appearance]
color_scheme_path=
custom_palette=false
icon_theme=$icons
standard_dialogs=default
style=kvantum

[Fonts]
fixed="$fixed_str"
general="$font_str"
EOF
  done
}