switch_wallpaper() {
  local wp_dir="$HOME/Pictures/Wallpapers/${C[wallpaperDir]}"
  [ -d "$wp_dir" ] || return
  local nsfw_filter=(-v)
  [ "$(tr -d '[:space:]' < "$HOME/.config/amane/.nsfw-enabled" 2>/dev/null)" = "true" ] && nsfw_filter=()
  local wp
  wp=$(find "$wp_dir" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | grep "${nsfw_filter[@]}" '\[NSFW\]' | shuf -n 1)
  [ -n "$wp" ] && awww img "$wp" --transition-type wave --transition-duration 2 2>/dev/null || true
}
