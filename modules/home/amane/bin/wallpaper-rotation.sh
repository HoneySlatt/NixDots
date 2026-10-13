themes="$HOME/.config/amane/themes"
declare -A C
# shellcheck source=/dev/null
source "$themes/apps/wallpaper.sh"

until awww query >/dev/null 2>&1; do
  sleep 0.5
done

# The compositor's own socket goes away with its session; wayland-1 is reused by the next one,
# so without this a loop left by an old session keeps changing the new session's wallpaper
session=${NIRI_SOCKET:-$XDG_RUNTIME_DIR/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket.sock}

while [ -S "$session" ]; do
  theme=$(tr -d '[:space:]' < "$HOME/.config/amane/.current-theme" 2>/dev/null || true)
  C[wallpaperDir]=$(jq -r --arg t "$theme" '(.[$t] // .pastelglow).wallpaperDir' "$themes/themes.json")
  switch_wallpaper || true
  sleep 300
done
