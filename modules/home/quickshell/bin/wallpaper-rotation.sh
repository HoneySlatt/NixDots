themes="$HOME/.config/quickshell/themes"
declare -A C
# shellcheck source=/dev/null
source "$themes/apps/wallpaper.sh"

until awww query >/dev/null 2>&1; do
  sleep 0.5
done

while true; do
  theme=$(tr -d '[:space:]' < "$HOME/.config/quickshell/.current-theme" 2>/dev/null || true)
  C[wallpaperDir]=$(jq -r --arg t "$theme" '(.[$t] // .pastelglow).wallpaperDir' "$themes/themes.json")
  switch_wallpaper || true
  sleep 300
done
