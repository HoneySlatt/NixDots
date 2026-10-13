HDR_MONITOR="DP-2"

current=$(hyprctl monitors -j | jq -r --arg mon "$HDR_MONITOR" '.[] | select(.name == $mon) | .colorManagementPreset')

if [ "$current" = "hdr" ] || [ "$current" = "hdredid" ]; then
  hyprctl eval "hl.monitor({ output = \"$HDR_MONITOR\", cm = \"srgb\" })" >/dev/null
  notify-send "HDR" "Disabled on $HDR_MONITOR"
else
  hyprctl eval "hl.monitor({ output = \"$HDR_MONITOR\", cm = \"hdr\" })" >/dev/null
  notify-send "HDR" "Enabled on $HDR_MONITOR"
fi
