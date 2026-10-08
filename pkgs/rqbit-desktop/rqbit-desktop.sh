#!@shell@

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
theme_root="$config_home/amane/themes"
if [ -r "$theme_root/themes.conf" ]; then
  declare -A C
  source "$theme_root/themes.conf"
  THEME="$(tr -d '[:space:]' 2>/dev/null < "$config_home/amane/.current-theme")"
  THEME="${THEME:-pastelglow}"
  if load_palette "$THEME"; then
    source "@out@/share/rqbit-desktop/rqbit.sh"
    switch_rqbit
  fi
fi

export LD_PRELOAD="@out@/lib/librqbit-theme.so${LD_PRELOAD:+:$LD_PRELOAD}"
exec "@out@/libexec/rqbit-desktop" "$@"
