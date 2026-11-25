LADYBIRD_NEWTAB_URL="http://127.0.0.1:48531/ladybird-newtab.html"

# Themed blank new-tab page, served by amane-userstyles-server (root: ~/.config/amane/themes)
gen_ladybird_newtab() {
  local pref="$1"
  local out="$HOME/.config/amane/themes/ladybird-newtab.html"
  mkdir -p "$(dirname "$out")"
  cat > "$out.tmp" << EOF
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>New Tab</title>
<style>
  :root { color-scheme: ${pref}; }
  html, body { height: 100%; margin: 0; }
  body { background: ${C[base]}; }
</style>
</head>
<body></body>
</html>
EOF
  mv "$out.tmp" "$out"
}

switch_ladybird() {
  # Ladybird rewrites Settings.json when it exits, so only write while it is not running
  if pgrep -x Ladybird > /dev/null; then
    echo "Ladybird is running; its theme will apply on next launch" >&2
    return 0
  fi

  local pref="dark"
  [ "${C[gtk_scheme]}" = "prefer-light" ] && pref="light"

  gen_ladybird_newtab "$pref"

  local profiles_root="${XDG_CONFIG_HOME:-$HOME/.config}/Ladybird/Profiles"
  local profile settings tmp
  for profile in "$profiles_root"/*/; do
    [ -d "$profile" ] || continue
    settings="$profile/Settings.json"
    [ -f "$settings" ] || continue
    tmp=$(mktemp "${settings}.XXXXXX")
    # A custom newTabPageURL chosen by the user is left alone
    if jq --arg pref "$pref" --arg newtab "$LADYBIRD_NEWTAB_URL" '
      .appearance.interfaceTheme = $pref |
      .appearance.websiteColorScheme = $pref |
      (if ((.newTabPageURL // "about:newtab") == "about:newtab" or (.newTabPageURL // "") == "about:blank")
       then .newTabPageURL = $newtab else . end)
    ' "$settings" > "$tmp" 2> /dev/null; then
      mv "$tmp" "$settings"
    else
      rm -f "$tmp"
      echo "Could not update $settings; keeping the previous file" >&2
    fi
  done

  # Ladybird never ran: seed the default profile so the first launch already follows the theme
  if [ ! -e "$profiles_root/default/Settings.json" ]; then
    mkdir -p "$profiles_root/default"
    printf '{"appearance":{"interfaceTheme":"%s","websiteColorScheme":"%s"},"newTabPageURL":"%s"}\n' \
      "$pref" "$pref" "$LADYBIRD_NEWTAB_URL" > "$profiles_root/default/Settings.json"
  fi
}
