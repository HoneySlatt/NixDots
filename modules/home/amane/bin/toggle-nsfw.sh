NSFW_FILE="$HOME/.config/amane/.nsfw-enabled"
if [ -f "$NSFW_FILE" ] && [ "$(tr -d '[:space:]' < "$NSFW_FILE")" = "true" ]; then
  echo "false" > "$NSFW_FILE"
  notify-send "NSFW" "Disabled"
else
  echo "true" > "$NSFW_FILE"
  notify-send "NSFW" "Enabled"
fi
