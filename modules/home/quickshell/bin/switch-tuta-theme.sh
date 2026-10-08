conf="$HOME/.config/tutanota-desktop/conf.json"
[ -f "$conf" ] || exit 0

theme_json="$1"
was_running=false

if pgrep -f '(^|/)tutanota-desktop($| )' > /dev/null; then
  was_running=true
  pkill -f '(^|/)tutanota-desktop($| )'
  i=0
  while pgrep -f '(^|/)tutanota-desktop($| )' > /dev/null && [ "$i" -lt 30 ]; do
    sleep 0.1
    i=$((i + 1))
  done
fi

tmp=$(mktemp)
jq --argjson theme "$theme_json" \
  '.themes = ([((.themes // [])[]) | select(.themeId != "quickshell")] + [$theme]) | .selectedTheme = "quickshell"' \
  "$conf" > "$tmp" && mv "$tmp" "$conf"

if $was_running; then
  tutanota-desktop &>/dev/null &
fi
