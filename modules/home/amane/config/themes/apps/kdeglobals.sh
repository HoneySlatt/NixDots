gen_kdeglobals() {
  h2r() { printf "%d,%d,%d" "0x${1:1:2}" "0x${1:3:2}" "0x${1:5:2}"; }

  local win;     win=$(h2r "${C[base]}")
  local win_alt; win_alt=$(h2r "${C[mantle]}")
  local crust;   crust=$(h2r "${C[crust]}")
  local surf0;   surf0=$(h2r "${C[surface0]}")
  local surf1;   surf1=$(h2r "${C[surface1]}")
  local text;    text=$(h2r "${C[text]}")
  local sub0;    sub0=$(h2r "${C[subtext0]}")
  local ov0;     ov0=$(h2r "${C[overlay0]}")
  local accent;  accent=$(h2r "${C[accent]}")
  local blue;    blue=$(h2r "${C[blue]}")
  local mauve;   mauve=$(h2r "${C[mauve]}")
  local red;     red=$(h2r "${C[red]}")
  local yellow;  yellow=$(h2r "${C[yellow]}")
  local green;   green=$(h2r "${C[green]}")

  cat > "$HOME/.config/kdeglobals" << EOF
[Colors:Button]
BackgroundAlternate=$surf1
BackgroundNormal=$surf0
DecorationFocus=$accent
DecorationHover=$surf1
ForegroundActive=$accent
ForegroundInactive=$ov0
ForegroundLink=$blue
ForegroundNegative=$red
ForegroundNeutral=$yellow
ForegroundNormal=$text
ForegroundPositive=$green
ForegroundVisited=$mauve

[Colors:Complementary]
BackgroundAlternate=$crust
BackgroundNormal=$crust
DecorationFocus=$accent
DecorationHover=$surf0
ForegroundActive=$accent
ForegroundInactive=$ov0
ForegroundLink=$blue
ForegroundNegative=$red
ForegroundNeutral=$yellow
ForegroundNormal=$text
ForegroundPositive=$green
ForegroundVisited=$mauve

[Colors:Header]
BackgroundAlternate=$win_alt
BackgroundNormal=$win_alt
DecorationFocus=$accent
DecorationHover=$surf0
ForegroundActive=$accent
ForegroundInactive=$ov0
ForegroundLink=$blue
ForegroundNegative=$red
ForegroundNeutral=$yellow
ForegroundNormal=$text
ForegroundPositive=$green
ForegroundVisited=$mauve

[Colors:Selection]
BackgroundAlternate=$surf1
BackgroundNormal=$accent
DecorationFocus=$accent
DecorationHover=$surf1
ForegroundActive=$win
ForegroundInactive=$win_alt
ForegroundLink=$blue
ForegroundNegative=$red
ForegroundNeutral=$yellow
ForegroundNormal=$win
ForegroundPositive=$green
ForegroundVisited=$mauve

[Colors:Tooltip]
BackgroundAlternate=$surf0
BackgroundNormal=$surf0
DecorationFocus=$accent
DecorationHover=$surf1
ForegroundActive=$accent
ForegroundInactive=$ov0
ForegroundLink=$blue
ForegroundNegative=$red
ForegroundNeutral=$yellow
ForegroundNormal=$text
ForegroundPositive=$green
ForegroundVisited=$mauve

[Colors:View]
BackgroundAlternate=$win_alt
BackgroundNormal=$win
DecorationFocus=$accent
DecorationHover=$surf0
ForegroundActive=$accent
ForegroundInactive=$ov0
ForegroundLink=$blue
ForegroundNegative=$red
ForegroundNeutral=$yellow
ForegroundNormal=$text
ForegroundPositive=$green
ForegroundVisited=$mauve

[Colors:Window]
BackgroundAlternate=$win_alt
BackgroundNormal=$win
DecorationFocus=$accent
DecorationHover=$surf0
ForegroundActive=$accent
ForegroundInactive=$ov0
ForegroundLink=$blue
ForegroundNegative=$red
ForegroundNeutral=$yellow
ForegroundNormal=$text
ForegroundPositive=$green
ForegroundVisited=$mauve

[General]
ColorScheme=Quickshell
Name=Quickshell

[KDE]
contrast=4
EOF

  local colors_dir="$HOME/.local/share/color-schemes"
  mkdir -p "$colors_dir"
  cp "$HOME/.config/kdeglobals" "$colors_dir/Quickshell.colors"

  local kdenliverc="$HOME/.config/kdenliverc"
  if [ -f "$kdenliverc" ]; then
    sed -i \
      -e "s|^ColorScheme=.*|ColorScheme=Quickshell|" \
      -e "s|^ColorSchemePath=.*|ColorSchemePath=$colors_dir/Quickshell.colors|" \
      "$kdenliverc"
  fi
}