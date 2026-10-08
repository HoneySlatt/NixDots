switch_jellyfin() {
  local conf="$HOME/.config/jellyfin-theme.conf"
  [ -f "$conf" ] || return 0
  source "$conf"
  [ -n "$JELLYFIN_URL" ] && [ -n "$JELLYFIN_API_KEY" ] || return 0

  local css
  case "$THEME" in
    pastelglow)
      css=":root {
    --main-color: ${C[accent]};
    --main-background: ${C[base]};
    --main-background-transparent: ${C[base]}dd;
    --dark-background: ${C[crust]};
    --second-background: ${C[mantle]};
    --hover-background: ${C[surface0]};
    --main-text: ${C[text]};
    --white-text: ${C[text]};
    --dimmer-text: ${C[overlay1]};
    --red-color: ${C[red]};
    --green-color: ${C[green]};
    --yellow-color: ${C[yellow]};
}" ;;
    gruvbox-light)
      css="@import url('https://jellyfin.catppuccin.com/theme.css');
@import url('https://jellyfin.catppuccin.com/catppuccin-latte.css');
:root { --main-color: var(--yellow); }" ;;
    *)
      css="@import url('https://jellyfin.catppuccin.com/theme.css');
:root {
    --main-color: ${C[accent]};
    --main-background: ${C[base]};
    --main-background-transparent: ${C[base]}dd;
    --dark-background: ${C[crust]};
    --second-background: ${C[mantle]};
    --hover-background: ${C[surface0]};
    --main-text: ${C[text]};
    --white-text: ${C[text]};
    --dimmer-text: ${C[overlay1]};
    --red-color: ${C[red]};
    --green-color: ${C[green]};
    --yellow-color: ${C[yellow]};
}" ;;
  esac

  local css_escaped
  css_escaped=$(printf '%s' "$css" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/' | tr -d '\n' | sed 's/\\n$//')
  local payload="{\"CustomCss\":\"${css_escaped}\",\"LoginDisclaimer\":null,\"SplashscreenEnabled\":false}"

  curl -sf -X POST \
    -H "X-Emby-Token: $JELLYFIN_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "$JELLYFIN_URL/System/Configuration/Branding" > /dev/null
}