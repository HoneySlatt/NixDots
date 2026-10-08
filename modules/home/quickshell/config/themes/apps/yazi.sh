gen_yazi_theme() {
  local tmpl="$HOME/.config/quickshell/templates/yazi-theme.toml.tmpl"
  [ -f "$tmpl" ] || return
  mkdir -p "$HOME/.config/yazi"
  sed \
    -e "s/#1e1e2e/${C[base]}/g" \
    -e "s/#181825/${C[mantle]}/g" \
    -e "s/#11111b/${C[crust]}/g" \
    -e "s/#313244/${C[surface0]}/g" \
    -e "s/#45475a/${C[surface1]}/g" \
    -e "s/#585b70/${C[surface2]}/g" \
    -e "s/#6c7086/${C[overlay0]}/g" \
    -e "s/#7f849c/${C[overlay1]}/g" \
    -e "s/#9399b2/${C[overlay2]}/g" \
    -e "s/#cdd6f4/${C[text]}/g" \
    -e "s/#bac2de/${C[subtext1]}/g" \
    -e "s/#a6adc8/${C[subtext0]}/g" \
    -e "s/#f38ba8/${C[red]}/g" \
    -e "s/#eba0ac/${C[maroon]}/g" \
    -e "s/#f5e0dc/${C[rosewater]}/g" \
    -e "s/#f2cdcd/${C[flamingo]}/g" \
    -e "s/#f5c2e7/${C[pink]}/g" \
    -e "s/#cba6f7/${C[mauve]}/g" \
    -e "s/#b4befe/${C[lavender]}/g" \
    -e "s/#89b4fa/${C[blue]}/g" \
    -e "s/#74c7ec/${C[sapphire]}/g" \
    -e "s/#89dceb/${C[sky]}/g" \
    -e "s/#94e2d5/${C[teal]}/g" \
    -e "s/#a6e3a1/${C[green]}/g" \
    -e "s/#f9e2af/${C[yellow]}/g" \
    -e "s/#fab387/${C[peach]}/g" \
    "$tmpl" > "$HOME/.config/yazi/theme.toml"
}