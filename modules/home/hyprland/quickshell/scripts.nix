{ pkgs, ... }:

let
  shellDir = "$HOME/NixOS/modules/home/hyprland/quickshell/config";

  readProfile = ''
    STATE_FILE="$HOME/.config/quickshell/.current-shell"
    profile="modern"

    if [ -f "$STATE_FILE" ]; then
      profile="$(tr -d '[:space:]' < "$STATE_FILE")"
    fi
  '';

  qsIpc = modern: tui: ''
    ${readProfile}

    case "$profile" in
      tui) ${tui} ;;
      *) ${modern} ;;
    esac
  '';
in
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "steam-games";
      runtimeInputs = [ pkgs.jq pkgs.coreutils ];
      text = ''
        steam_dir="$HOME/.local/share/Steam"
        grid_dir="$steam_dir/userdata/303776471/config/grid"
        cache_dir="$steam_dir/appcache/librarycache"
        heroic_dir="$HOME/.config/heroic"
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
        [[ ''${#lib_paths[@]} -eq 0 ]] && lib_paths=("$steam_dir")

        resolve_art() {
          local appid="$1"
          for ext in png jpg; do
            [[ -f "$grid_dir/''${appid}p.$ext" ]] && echo "$grid_dir/''${appid}p.$ext" && return
          done
          for ext in jpg png; do
            [[ -f "$cache_dir/''${appid}/library_600x900.$ext" ]] && echo "$cache_dir/''${appid}/library_600x900.$ext" && return
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
          [[ -z "$title" ]] && title="$fallback_title"
          [[ -z "$title" ]] && title="$app_name"
          art=$(resolve_heroic_art "$art_url")

          add_game "" "$title" "$art" "heroic://launch?appName=$app_name&runner=$runner"
        }

        for lib in "''${lib_paths[@]}"; do
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

        if [[ ''${#lines[@]} -eq 0 ]]; then
          echo "[]"
        else
          printf '%s\n' "''${lines[@]}" | jq -s 'sort_by(.name | ascii_downcase)'
        fi
      '';
    })

    (pkgs.writeShellApplication {
      name = "qs-compile-userstyle";
      runtimeInputs = [ pkgs.nodejs pkgs.lessc ];
      text = ''
        LESS_MODULE_PATH="${pkgs.lessc}/lib/lessc/packages/less" node "$HOME/.config/quickshell/themes/compile-userstyle.js" "$@"
      '';
    })

    (pkgs.writeShellApplication {
      name = "qs-userstyles-server";
      runtimeInputs = [ pkgs.python3 ];
      text = ''
        exec python3 -m http.server 48531 --bind 127.0.0.1 --directory "$HOME/.config/quickshell/themes"
      '';
    })

    (pkgs.writeShellApplication {
      name = "switch-tuta-theme";
      runtimeInputs = [ pkgs.jq ];
      text = ''
        conf="$HOME/.config/tutanota-desktop/conf.json"
        [ -f "$conf" ] || exit 0

        theme_json="$1"
        was_running=false

        if pgrep -f '(^|/)tutanota-desktop($| )' > /dev/null; then
          was_running=true
          pkill -f '(^|/)tutanota-desktop($| )'
          i=0
          while pgrep -f '(^|/)tutanota-desktop($| )' > /dev/null && [ "$i" -lt 30 ]; do
            sleep 0.1
            i=$((i + 1))
          done
        fi

        tmp=$(mktemp)
        jq --argjson theme "$theme_json" \
          '.themes = ([((.themes // [])[]) | select(.themeId != "quickshell")] + [$theme]) | .selectedTheme = "quickshell"' \
          "$conf" > "$tmp" && mv "$tmp" "$conf"

        if $was_running; then
          tutanota-desktop &>/dev/null &
        fi
      '';
    })

    (pkgs.writeShellApplication {
      name = "switch-kopuz-theme";
      runtimeInputs = [ pkgs.jq pkgs.gawk pkgs.coreutils ];
      text = ''
        toml_conf="$HOME/.config/kopuz/settings.toml"
        json_conf="$HOME/.config/kopuz/config.json"
        [ -f "$toml_conf" ] || [ -f "$json_conf" ] || exit 0

        theme_name="$1"
        bg="$2"
        raised="$3"
        surface="$4"
        text_color="$5"
        text_muted="$6"
        accent="$7"
        accent_soft="$8"
        accent_alt="$9"
        accent_deep="''${10}"
        highlight="''${11}"
        highlight_dark="''${12}"
        progress="''${13}"
        danger="''${14}"

        if [ -f "$toml_conf" ]; then
          conf="$toml_conf"
          tmp=$(mktemp "$conf.XXXXXX")
          trap 'rm -f "$tmp"' EXIT

          awk '
            BEGIN {
              count = 0
              first_section = 0
              in_quickshell = 0
              seen_section = 0
              theme_set = 0
            }
            /^[[:space:]]*\[/ {
              header = $0
              sub(/^[[:space:]]*\[+/, "", header)
              sub(/\]+[[:space:]]*(#.*)?$/, "", header)
              in_quickshell = (header == "custom_themes.quickshell" || header == "custom_themes.quickshell.vars")
              seen_section = 1
              if (first_section == 0) first_section = count + 1
              if (in_quickshell) next
            }
            in_quickshell { next }
            !seen_section && !theme_set && /^[[:space:]]*theme[[:space:]]*=/ {
              lines[++count] = "theme = \"quickshell\""
              theme_set = 1
              next
            }
            { lines[++count] = $0 }
            END {
              insert_at = first_section ? first_section : count + 1
              for (i = 1; i <= count; i++) {
                if (!theme_set && i == insert_at) print "theme = \"quickshell\""
                print lines[i]
              }
              if (!theme_set && insert_at == count + 1) print "theme = \"quickshell\""
            }
          ' "$conf" > "$tmp"

          {
            printf '\n[custom_themes.quickshell]\n'
            printf 'name = "%s"\n' "$theme_name"
            printf '\n[custom_themes.quickshell.vars]\n'
            printf 'bg = "%s"\n' "$bg"
            printf 'raised = "%s"\n' "$raised"
            printf 'surface = "%s"\n' "$surface"
            printf 'text = "%s"\n' "$text_color"
            printf 'text-muted = "%s"\n' "$text_muted"
            printf 'accent = "%s"\n' "$accent"
            printf 'accent-soft = "%s"\n' "$accent_soft"
            printf 'accent-alt = "%s"\n' "$accent_alt"
            printf 'accent-deep = "%s"\n' "$accent_deep"
            printf 'highlight = "%s"\n' "$highlight"
            printf 'highlight-dark = "%s"\n' "$highlight_dark"
            printf 'progress = "%s"\n' "$progress"
            printf 'danger = "%s"\n' "$danger"
          } >> "$tmp"

          mv "$tmp" "$conf"
          trap - EXIT
          exit 0
        fi

        conf="$json_conf"
        tmp=$(mktemp "$conf.XXXXXX")
        trap 'rm -f "$tmp"' EXIT

        jq \
          --arg name "$theme_name" \
          --arg bg "$bg" \
          --arg raised "$raised" \
          --arg surface "$surface" \
          --arg text "$text_color" \
          --arg text_muted "$text_muted" \
          --arg accent "$accent" \
          --arg accent_soft "$accent_soft" \
          --arg accent_alt "$accent_alt" \
          --arg accent_deep "$accent_deep" \
          --arg highlight "$highlight" \
          --arg highlight_dark "$highlight_dark" \
          --arg progress "$progress" \
          --arg danger "$danger" \
          '.theme = "quickshell"
            | .custom_themes = (.custom_themes // {})
            | .custom_themes.quickshell = {
                name: $name,
                vars: {
                  "bg": $bg,
                  "raised": $raised,
                  "surface": $surface,
                  "text": $text,
                  "text-muted": $text_muted,
                  "accent": $accent,
                  "accent-soft": $accent_soft,
                  "accent-alt": $accent_alt,
                  "accent-deep": $accent_deep,
                  "highlight": $highlight,
                  "highlight-dark": $highlight_dark,
                  "progress": $progress,
                  "danger": $danger
                }
              }' "$conf" > "$tmp" && mv "$tmp" "$conf"

        trap - EXIT
      '';
    })

    (pkgs.writeShellApplication {
      name = "toggle-tailscale";
      text = ''
        ${pkgs.bash}/bin/bash "$HOME/NixOS/modules/home/hyprland/quickshell/config/scripts/toggle-tailscale-exit-node.sh" "$@"
      '';
    })

    (pkgs.writeShellApplication {
      name = "tailscale-exit-nodes";
      runtimeInputs = [ pkgs.jq ];
      text = ''
        ${pkgs.bash}/bin/bash "$HOME/NixOS/modules/home/hyprland/quickshell/config/scripts/tailscale-exit-nodes.sh"
      '';
    })

    (pkgs.writeShellApplication {
      name = "toggle-nsfw";
      text = ''
        NSFW_FILE="$HOME/.config/quickshell/.nsfw-enabled"
        if [ -f "$NSFW_FILE" ] && [ "$(cat "$NSFW_FILE" | tr -d '[:space:]')" = "true" ]; then
          echo "false" > "$NSFW_FILE"
          notify-send "NSFW" "Disabled"
        else
          echo "true" > "$NSFW_FILE"
          notify-send "NSFW" "Enabled"
        fi
      '';
    })

    (pkgs.writeShellApplication {
      name = "wallpaper-rotation";
      text = ''
        THEME_FILE="$HOME/.config/quickshell/.current-theme"
        NSFW_FILE="$HOME/.config/quickshell/.nsfw-enabled"
        BASE_DIR="$HOME/Pictures/Wallpapers"

        declare -A THEME_DIRS
        THEME_DIRS[pastelglow]="PastelGlow"
        THEME_DIRS[rosepine]="RosePine"
        THEME_DIRS[everforest]="Everforest"
        THEME_DIRS[carbonfox]="Carbonfox"
        THEME_DIRS[gruvbox]="GruvboxDark"
        THEME_DIRS[gruvbox-light]="GruvboxLight"

        until awww query >/dev/null 2>&1; do
          sleep 0.5
        done

        while true; do
          theme=$(cat "$THEME_FILE" 2>/dev/null | tr -d '[:space:]')
          subdir="''${THEME_DIRS[$theme]:-PastelGlow}"
          wallpaper_dir="$BASE_DIR/$subdir"
          nsfw_enabled=$(cat "$NSFW_FILE" 2>/dev/null | tr -d '[:space:]')

          if [ "$nsfw_enabled" = "true" ]; then
            wallpaper=$(find "$wallpaper_dir" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) 2>/dev/null | grep '\[NSFW\]' | shuf -n 1)
          else
            wallpaper=$(find "$wallpaper_dir" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) 2>/dev/null | grep -v '\[NSFW\]' | shuf -n 1)
          fi

          if [ -n "$wallpaper" ]; then
            awww img "$wallpaper" --transition-type wave --transition-duration 2 || true
          fi

          sleep 300
        done
      '';
    })

    (pkgs.writeShellApplication {
      name = "toggle-quickshell";
      text = ''
        shell_dir="${shellDir}"
        state_file="$shell_dir/.current-shell"
        current="modern"

        if [ -f "$state_file" ]; then
          current="$(tr -d '[:space:]' < "$state_file")"
        fi

        if [ "$current" = "tui" ]; then
          target="modern"
        else
          target="tui"
        fi

        quickshell kill -c modern --any-display || true
        quickshell kill -c tui --any-display || true
        sleep 0.2

        ln -sfnT "$shell_dir" "$HOME/.config/quickshell"
        printf '%s\n' "$target" > "$state_file"
        apply-font-profile
        "$HOME/.config/quickshell/themes/switch-theme.sh" --shell >/dev/null 2>&1 || true
        nohup qs -c "$target" >/dev/null 2>&1 &
      '';
    })

    (pkgs.writeShellApplication {
      name = "toggle-bar-position";
      text = qsIpc
        ''quickshell ipc -p "$HOME/.config/quickshell/modern" -n call togglePosition call''
        ''quickshell ipc -c tui call tuiTogglePosition call'';
    })

    (pkgs.writeShellApplication {
      name = "toggle-launcher";
      text = qsIpc
        ''quickshell ipc -p "$HOME/.config/quickshell/modern" -n call toggleLauncher call''
        ''quickshell ipc -c tui call tuiToggleAppLauncher call'';
    })

    (pkgs.writeShellApplication {
      name = "toggle-theme-launcher";
      text = qsIpc
        ''quickshell ipc -c modern call toggleThemeLauncher call''
        ''quickshell ipc -c tui call tuiToggleThemeLauncher call'';
    })

    (pkgs.writeShellApplication {
      name = "toggle-wallpaper-launcher";
      text = qsIpc
        ''quickshell ipc -c modern call toggleWallpaperLauncher call''
        ''quickshell ipc -c tui call tuiToggleWallpaperLauncher call'';
    })

    (pkgs.writeShellApplication {
      name = "toggle-game-launcher";
      text = qsIpc
        ''quickshell ipc -c modern call toggleSteamLauncher call''
        ''quickshell ipc -c tui call tuiToggleGameLauncher call'';
    })

    (pkgs.writeShellApplication {
      name = "toggle-music-launcher";
      text = qsIpc
        ''quickshell ipc -c modern call toggleMusicLauncher call''
        ''quickshell ipc -c tui call tuiToggleMusicLauncher call'';
    })

    (pkgs.writeShellApplication {
      name = "toggle-vpn-launcher";
      text = qsIpc
        ''quickshell ipc -c modern call toggleVpnLauncher call''
        ''quickshell ipc -c tui call tuiToggleVpnLauncher call'';
    })

    (pkgs.writeShellApplication {
      name = "toggle-power-launcher";
      text = qsIpc
        ''quickshell ipc -c modern call togglePowerMenu call''
        ''quickshell ipc -c tui call tuiTogglePowerLauncher call'';
    })

    (pkgs.writeShellApplication {
      name = "toggle-overview";
      runtimeInputs = [ pkgs.hyprland pkgs.jq ];
      text = ''
        active_layout="$(hyprctl -j activeworkspace 2>/dev/null | jq -r '.tiledLayout // empty' 2>/dev/null || true)"
        if [[ -z "$active_layout" && -f "$HOME/.config/hypr/layout-mode" ]]; then
          active_layout="$(tr -d '[:space:]' < "$HOME/.config/hypr/layout-mode")"
        fi

        if [[ "$active_layout" == "scrolling" ]]; then
          hyprctl eval 'hl.dispatch(hl.plugin.scrolloverview.overview("toggle all"))'
        else
          hyprctl eval 'hl.plugin.hymission.toggle("onlycurrentworkspace")'
        fi
      '';
    })

    (pkgs.writeShellApplication {
      name = "toggle-browser";
      text = qsIpc ''brave-origin'' ''firefox'';
    })

    (pkgs.writeShellApplication {
      name = "toggle-secondary-browser";
      text = qsIpc ''firefox'' ''brave-origin'';
    })

    (pkgs.writeShellApplication {
      name = "lock-screen";
      text = ''
        if pgrep -x hyprlock > /dev/null; then
          exit 0
        fi

        if [ ! -f "$HOME/.config/hypr/hyprlock-theme.conf" ]; then
          THEME_FILE="$HOME/.config/quickshell/.current-theme"
          THEME="carbonfox"
          if [ -f "$THEME_FILE" ]; then
            THEME="$(tr -d '[:space:]' < "$THEME_FILE")"
          fi
          THEMES_DIR="$HOME/.config/quickshell/themes"
          if [ -f "$THEMES_DIR/switch-theme.sh" ]; then
            bash "$THEMES_DIR/switch-theme.sh" "$THEME" >/dev/null 2>&1 || true
          fi
        fi

        ${readProfile}

        if [ "$profile" = "tui" ] && [ -f "$HOME/.config/hypr/hyprlock-tui.conf" ]; then
          hyprlock --config "$HOME/.config/hypr/hyprlock-tui.conf" --immediate-render
        else
          hyprlock --immediate-render
        fi
      '';
    })

    (pkgs.writeShellApplication {
      name = "apply-font-profile";
      text = ''
        ${readProfile}

        case "$profile" in
          tui)
            FONT="IosevkaTerm Nerd Font Mono"
            FONT_NAME="IosevkaTerm Nerd Font Mono 11"
            FSIZE=12
            BOLD="IosevkaTerm Nerd Font Mono"
            ITALIC="IosevkaTerm Nerd Font Mono"
            BOLD_ITALIC="IosevkaTerm Nerd Font Mono"
            ;;
          *)
            FONT="JetBrainsMono Nerd Font"
            FONT_NAME="JetBrainsMono Nerd Font 10"
            FSIZE=11
            BOLD="JetBrainsMono Nerd Font"
            ITALIC="JetBrainsMono Nerd Font"
            BOLD_ITALIC="JetBrainsMono Nerd Font"
            ;;
        esac

        mkdir -p "$HOME/.config/ghostty"
        cat > "$HOME/.config/ghostty/fonts.conf" << AEOF
# Font profile: $profile - auto-generated by apply-font-profile
font-family = "$FONT"
font-family-bold = "$BOLD"
font-family-italic = "$ITALIC"
font-family-bold-italic = "$BOLD_ITALIC"
font-size = ''${FSIZE}
AEOF

        mkdir -p "$HOME/.config/gtk-3.0"
        if [ -f "$HOME/.config/gtk-3.0/settings.ini" ]; then
          sed -i "s/^gtk-font-name=.*/gtk-font-name=$FONT_NAME/" "$HOME/.config/gtk-3.0/settings.ini"
        else
          cat > "$HOME/.config/gtk-3.0/settings.ini" << EOF
[Settings]
gtk-font-name=$FONT_NAME
EOF
        fi

        dconf write /org/gnome/desktop/interface/font-name "'$FONT_NAME'" 2>/dev/null || true
      '';
    })

    (pkgs.writeShellApplication {
      name = "hyprquickshot-toggle";
      runtimeInputs = [ pkgs.quickshell pkgs.procps pkgs.coreutils ];
      text = ''
        if pgrep -x wf-recorder > /dev/null; then
          pkill --signal SIGINT wf-recorder
        else
          ${readProfile}

          if [ "$profile" = "tui" ]; then
            quickshell -c tuiquickshot -n
          else
            quickshell -c hyprquickshot -n
          fi
        fi
      '';
    })

    (pkgs.writeShellApplication {
      name = "start-quickshell";
      text = ''
        shell_dir="${shellDir}"
        state_file="$shell_dir/.current-shell"
        profile="modern"

        if [ -f "$state_file" ]; then
          profile="$(tr -d '[:space:]' < "$state_file")"
        fi

        case "$profile" in
          tui) ;;
          *) profile="modern" ;;
        esac

        quickshell kill -c modern --any-display || true
        quickshell kill -c tui --any-display || true
        sleep 0.2

        ln -sfnT "$shell_dir" "$HOME/.config/quickshell"
        apply-font-profile
        "$HOME/.config/quickshell/themes/switch-theme.sh" --shell >/dev/null 2>&1 || true
        nohup qs -c "$profile" >/dev/null 2>&1 &
      '';
    })
  ];
}
