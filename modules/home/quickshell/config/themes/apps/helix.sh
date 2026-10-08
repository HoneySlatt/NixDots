helix_reload() {
  local cfg="$HOME/.config/helix/config.toml"
  if [ -L "$cfg" ]; then
    cp "$cfg" "$cfg.tmp" && rm "$cfg" && mv "$cfg.tmp" "$cfg"
  fi
  sed -i "s/^theme = .*/theme = \"${C[helix]}\"/" "$cfg"
  pkill -USR1 -u "$USER" -x hx 2>/dev/null || true
}
