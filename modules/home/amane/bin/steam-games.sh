steam_dir="$HOME/.local/share/Steam"
grid_dir=""
for d in "$steam_dir"/userdata/*/config/grid; do
  if [[ -d "$d" ]]; then grid_dir="$d"; break; fi
done
cache_dir="$steam_dir/appcache/librarycache"
heroic_dir="$HOME/.config/heroic"
overrides_file="$heroic_dir/store/game-overrides.json"
lines=()

add_game() {
  local appid="$1"
  local name="$2"
  local art="$3"
  local launch_url="$4"

  [[ -z "$name" || -z "$launch_url" ]] && return

  lines+=("$(jq -cn \
    --arg appid "$appid" \
    --arg name "$name" \
    --arg art "$art" \
    --arg launchUrl "$launch_url" \
    '{name:$name,art:$art,launchUrl:$launchUrl} + if $appid == "" then {} else {appid:$appid} end')")
}

mapfile -t lib_paths < <(grep -oP '(?<="path"\t{1,8}")([^"]+)' "$steam_dir/config/libraryfolders.vdf" 2>/dev/null | sort -u)
[[ ${#lib_paths[@]} -eq 0 ]] && lib_paths=("$steam_dir")

resolve_art() {
  local appid="$1"
  for ext in png jpg; do
    [[ -f "$grid_dir/${appid}p.$ext" ]] && echo "$grid_dir/${appid}p.$ext" && return
  done
  for ext in jpg png; do
    [[ -f "$cache_dir/${appid}/library_600x900.$ext" ]] && echo "$cache_dir/${appid}/library_600x900.$ext" && return
  done
  echo ""
}

resolve_heroic_art() {
  local url="$1"
  local hash
  local cached

  [[ -z "$url" ]] && return

  hash=$(printf '%s' "$url" | sha256sum | cut -d ' ' -f1)
  cached="$heroic_dir/images-cache/$hash"

  if [[ -f "$cached" ]]; then
    echo "$cached"
  else
    echo "$url"
  fi
}

add_heroic_game() {
  local runner="$1"
  local app_name="$2"
  local fallback_title="$3"
  local library_file="$4"
  local metadata='{}'
  local title
  local art_url
  local art

  [[ -z "$app_name" ]] && return

  if [[ -f "$library_file" ]]; then
    metadata=$(jq -c --arg id "$app_name" \
      '[.games[]? | select((.app_name | tostring) == $id)][0] // {}' \
      "$library_file" 2>/dev/null || echo '{}')
  fi

  [[ "$(jq -r '.install.is_dlc // false' <<< "$metadata")" == "true" ]] && return

  title=$(jq -r '.title // empty' <<< "$metadata")
  art_url=$(jq -r '.art_square // .art_cover // empty' <<< "$metadata")
  # Custom covers set in Heroic (only the portrait one fits the launcher cards)
  override_art=$(jq -r --arg id "$app_name" '.overrides[$id].art_square // empty' "$overrides_file" 2>/dev/null || true)
  [[ -n "$override_art" ]] && art_url="$override_art"
  [[ -z "$title" ]] && title="$fallback_title"
  [[ -z "$title" ]] && title="$app_name"
  art=$(resolve_heroic_art "$art_url")

  add_game "" "$title" "$art" "heroic://launch?appName=$app_name&runner=$runner"
}

for lib in "${lib_paths[@]}"; do
  for acf in "$lib/steamapps"/appmanifest_*.acf; do
    [[ -f "$acf" ]] || continue

    appid=$(grep -m1 '"appid"' "$acf" | grep -oP '(?<=")\d+(?=")' || true)
    name=$(grep -m1 '"name"' "$acf" | sed 's/.*"name"[[:space:]]*"\([^"]*\)".*/\1/' || true)

    [[ -z "$appid" || -z "$name" ]] && continue
    [[ "$appid" == "39210" ]] && continue

    case "$name" in
      Proton*|"Steam Linux Runtime"*|"Steamworks Common"*|"Steam VR"*) continue ;;
    esac

    art=$(resolve_art "$appid")
    add_game "$appid" "$name" "$art" "steam://rungameid/$appid"
  done
done

sideload_file="$heroic_dir/sideload_apps/library.json"
if [[ -f "$sideload_file" ]]; then
  while IFS= read -r game; do
    app_name=$(jq -r '.app_name // empty | tostring' <<< "$game")
    title=$(jq -r '.title // empty' <<< "$game")
    add_heroic_game "sideload" "$app_name" "$title" "$sideload_file"
  done < <(jq -c '.games[]? | select((.is_installed // false) == true and (.install.is_dlc // false) == false)' "$sideload_file" 2>/dev/null)
fi

gog_installed="$heroic_dir/gog_store/installed.json"
gog_library="$heroic_dir/store_cache/gog_library.json"
if [[ -f "$gog_installed" ]]; then
  while IFS= read -r game; do
    app_name=$(jq -r '.appName // .app_name // empty | tostring' <<< "$game")
    title=$(jq -r '.title // .name // empty' <<< "$game")
    add_heroic_game "gog" "$app_name" "$title" "$gog_library"
  done < <(jq -c '.installed[]? | select((.is_dlc // false) == false)' "$gog_installed" 2>/dev/null)
fi

legendary_installed="$heroic_dir/legendaryConfig/legendary/installed.json"
legendary_library="$heroic_dir/store_cache/legendary_library.json"
if [[ -f "$legendary_installed" ]]; then
  while IFS= read -r game; do
    app_name=$(jq -r '.app_name // .appName // ._app_name // empty | tostring' <<< "$game")
    title=$(jq -r '.title // .name // empty' <<< "$game")
    add_heroic_game "legendary" "$app_name" "$title" "$legendary_library"
  done < <(jq -c 'to_entries[]? | select((.value.is_dlc // false) == false) | .value + {_app_name:.key}' "$legendary_installed" 2>/dev/null)
fi

nile_installed="$heroic_dir/nile_config/nile/installed.json"
nile_library="$heroic_dir/store_cache/nile_library.json"
if [[ -f "$nile_installed" ]]; then
  while IFS= read -r game; do
    app_name=$(jq -r '.id // .app_name // .appName // empty | tostring' <<< "$game")
    title=$(jq -r '.title // .name // empty' <<< "$game")
    add_heroic_game "nile" "$app_name" "$title" "$nile_library"
  done < <(jq -c '.[]?' "$nile_installed" 2>/dev/null)
fi

if [[ ${#lines[@]} -eq 0 ]]; then
  echo "[]"
else
  printf '%s\n' "${lines[@]}" | jq -s 'sort_by(.name | ascii_downcase)'
fi
