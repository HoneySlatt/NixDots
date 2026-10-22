switch_element() {
  command -v jq >/dev/null 2>&1 || return 0

  local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/Element"
  local css_dir="${XDG_CONFIG_HOME:-$HOME/.config}/element-desktop"
  local config_file="$config_dir/config.json"
  local css_file="$css_dir/amane.css"
  local dark=true
  [ "${C[light]}" = "true" ] && dark=false
  mkdir -p "$config_dir" "$css_dir"

  local palette theme config_tmp css_tmp existing="{}"
  palette=$(jq -n \
    --arg base "${C[base]}" --arg mantle "${C[mantle]}" --arg crust "${C[crust]}" \
    --arg surface0 "${C[surface0]}" --arg surface1 "${C[surface1]}" --arg surface2 "${C[surface2]}" \
    --arg overlay0 "${C[overlay0]}" --arg overlay1 "${C[overlay1]}" --arg overlay2 "${C[overlay2]}" \
    --arg text "${C[text]}" --arg subtext1 "${C[subtext1]}" --arg subtext0 "${C[subtext0]}" \
    --arg red "${C[red]}" --arg maroon "${C[maroon]}" --arg peach "${C[peach]}" \
    --arg pink "${C[pink]}" --arg mauve "${C[mauve]}" --arg lavender "${C[lavender]}" \
    --arg blue "${C[blue]}" --arg sapphire "${C[sapphire]}" --arg sky "${C[sky]}" \
    --arg green "${C[green]}" --arg yellow "${C[yellow]}" --arg teal "${C[teal]}" \
    --arg accent "${C[accent]}" --arg rosewater "${C[rosewater]}" \
    '$ARGS.named') || return 1

  # Compound semantic tokens, plus the gray ramp Element still reads directly.
  # Light and dark palettes already flip base/text; the gray steps do not.
  theme=$(jq -n --argjson p "$palette" --argjson dark "$dark" '
    def hue($name; $color): {
      ("--cpd-color-\($name)-100"): $p.surface0,
      ("--cpd-color-\($name)-600"): $color,
      ("--cpd-color-\($name)-900"): $color
    };
    (if $dark then
      [$p.crust,$p.mantle,$p.base,$p.surface0,$p.surface1,$p.surface2,$p.overlay0,$p.overlay1,$p.overlay2,$p.subtext0,$p.subtext1,$p.text,$p.text,$p.rosewater]
    else
      [$p.base,$p.mantle,$p.text,$p.subtext1,$p.subtext0,$p.overlay2,$p.overlay1,$p.overlay0,$p.surface2,$p.surface1,$p.surface0,$p.base,$p.mantle,$p.crust]
    end) as $gray
    | ["100","200","300","400","500","600","700","800","900","1000","1100","1200","1300","1400"] as $step
    | (reduce range(0; $step | length) as $i ({}; .["--cpd-color-gray-\($step[$i])"] = $gray[$i])
      + hue("red"; $p.red) + hue("orange"; $p.peach) + hue("yellow"; $p.yellow)
      + hue("lime"; $p.green) + hue("green"; $p.green) + hue("cyan"; $p.sky)
      + hue("blue"; $p.blue) + hue("purple"; $p.mauve) + hue("fuchsia"; $p.mauve) + hue("pink"; $p.pink)
      + {
        "--cpd-color-theme-bg": $p.base,
        "--cpd-color-text-primary": $p.text,
        "--cpd-color-text-secondary": $p.subtext0,
        "--cpd-color-text-disabled": $p.overlay0,
        "--cpd-color-text-action-primary": $p.text,
        "--cpd-color-text-action-accent": $p.accent,
        "--cpd-color-text-link-external": $p.blue,
        "--cpd-color-text-critical-primary": $p.red,
        "--cpd-color-text-success-primary": $p.green,
        "--cpd-color-text-info-primary": $p.blue,
        "--cpd-color-text-on-solid-primary": $p.base,
        "--cpd-color-text-decorative-1": $p.green,
        "--cpd-color-text-decorative-2": $p.sky,
        "--cpd-color-text-decorative-3": $p.pink,
        "--cpd-color-text-decorative-4": $p.mauve,
        "--cpd-color-text-decorative-5": $p.maroon,
        "--cpd-color-text-decorative-6": $p.peach,
        "--cpd-color-bg-subtle-primary": $p.surface0,
        "--cpd-color-bg-subtle-secondary": $p.base,
        "--cpd-color-bg-canvas-default": $p.base,
        "--cpd-color-bg-canvas-default-level-1": $p.mantle,
        "--cpd-color-bg-canvas-disabled": $p.mantle,
        "--cpd-color-bg-subtle-secondary-level-0": $p.crust,
        "--cpd-color-bg-action-primary-disabled": $p.overlay0,
        "--cpd-color-bg-action-secondary-rest": $p.base,
        "--cpd-color-bg-action-tertiary-rest": $p.base,
        "--cpd-color-bg-action-tertiary-hovered": $p.surface0,
        "--cpd-color-bg-action-tertiary-selected": $p.surface1,
        "--cpd-color-bg-critical-primary": $p.red,
        "--cpd-color-bg-critical-hovered": $p.red,
        "--cpd-color-bg-critical-subtle": $p.surface0,
        "--cpd-color-bg-success-subtle": $p.surface0,
        "--cpd-color-bg-info-subtle": $p.surface0,
        "--cpd-color-bg-accent-rest": $p.accent,
        "--cpd-color-bg-accent-hovered": $p.accent,
        "--cpd-color-bg-accent-pressed": $p.accent,
        "--cpd-color-bg-accent-selected": $p.surface1,
        "--cpd-color-bg-decorative-1": $p.surface0,
        "--cpd-color-bg-decorative-2": $p.surface0,
        "--cpd-color-bg-decorative-3": $p.surface0,
        "--cpd-color-bg-decorative-4": $p.surface0,
        "--cpd-color-bg-decorative-5": $p.surface0,
        "--cpd-color-bg-decorative-6": $p.surface0,
        "--cpd-color-icon-primary": $p.text,
        "--cpd-color-icon-secondary": $p.subtext0,
        "--cpd-color-icon-tertiary": $p.overlay1,
        "--cpd-color-icon-quaternary": $p.overlay0,
        "--cpd-color-icon-accent-primary": $p.accent,
        "--cpd-color-icon-critical-primary": $p.red,
        "--cpd-color-icon-success-primary": $p.green,
        "--cpd-color-icon-info-primary": $p.blue,
        "--cpd-color-icon-on-solid-primary": $p.base,
        "--cpd-color-icon-disabled": $p.surface2,
        "--cpd-color-border-interactive-primary": $p.overlay2,
        "--cpd-color-border-interactive-secondary": $p.overlay0,
        "--cpd-color-border-interactive-hovered": $p.text,
        "--cpd-color-border-disabled": $p.surface2,
        "--cpd-color-border-focused": $p.accent,
        "--cpd-color-border-critical-primary": $p.red,
        "--cpd-color-border-success-subtle": $p.green,
        "--cpd-color-border-info-subtle": $p.blue,
        "--cpd-color-border-accent-subtle": $p.overlay0
      }) as $compound
    | {
        name: "Amane",
        is_dark: $dark,
        colors: {
          "accent-color": $p.accent,
          "primary-color": $p.accent,
          "warning-color": $p.red,
          "alert": $p.yellow,
          "sidebar-color": $p.crust,
          "roomlist-background-color": $p.mantle,
          "roomlist-text-color": $p.text,
          "roomlist-text-secondary-color": $p.overlay2,
          "roomlist-highlights-color": $p.surface1,
          "roomlist-separator-color": $p.overlay1,
          "timeline-background-color": $p.base,
          "timeline-text-color": $p.text,
          "secondary-content": $p.text,
          "tertiary-content": $p.text,
          "timeline-text-secondary-color": $p.subtext0,
          "timeline-highlights-color": $p.mantle,
          "reaction-row-button-selected-bg-color": $p.surface1,
          "menu-selected-color": $p.surface1,
          "focus-bg-color": $p.surface2,
          "room-highlight-color": $p.sky,
          "togglesw-off-color": $p.overlay2,
          "other-user-pill-bg-color": $p.sky,
          "username-colors": [$p.mauve,$p.maroon,$p.peach,$p.green,$p.teal,$p.sky,$p.sapphire,$p.lavender],
          "avatar-background-colors": [$p.blue,$p.accent,$p.green]
        },
        compound: $compound
      }
  ') || return 1

  if [ -f "$config_file" ]; then
    existing=$(<"$config_file")
    printf '%s' "$existing" | jq -e . >/dev/null 2>&1 || {
      printf 'Could not update Element theme; config.json is not valid JSON.\n' >&2
      return 1
    }
  fi

  config_tmp=$(mktemp "${config_file}.XXXXXX") || return 1
  css_tmp=$(mktemp "${css_file}.XXXXXX") || { rm -f "$config_tmp"; return 1; }

  if ! printf '%s' "$existing" | jq --argjson theme "$theme" '
    . as $orig
    | .default_theme = "custom-Amane"
    | .setting_defaults = (($orig.setting_defaults // {}) + {
        theme: "custom-Amane",
        use_system_theme: false,
        feature_custom_themes: true,
        custom_themes: ([($orig.setting_defaults.custom_themes // [])[] | select(.name != "Amane")] + [$theme])
      })
  ' > "$config_tmp"; then
    rm -f "$config_tmp" "$css_tmp"
    return 1
  fi

  {
    printf '%s\n' "/* Auto-generated by switch-theme.sh */"
    jq -n -r --argjson theme "$theme" '
      def decl($k; $v): "  \($k): \($v) !important;";
      ([ $theme.compound | to_entries[] | decl(.key; .value) ]
        + [ $theme.colors | to_entries[] | select(.value | type == "string") | decl("--\(.key)"; .value) ]
        + [ $theme.colors["username-colors"] | to_entries[] | decl("--username-colors_\(.key)"; .value) ]
      ) as $lines
      | ":root, body, [class*=\"cpd-theme-\"] {",
        "  color-scheme: \(if $theme.is_dark then "dark" else "light" end) !important;",
        ($lines | .[]),
        "}"
    ' 
  } > "$css_tmp" || { rm -f "$config_tmp" "$css_tmp"; return 1; }

  mv "$config_tmp" "$config_file" && mv "$css_tmp" "$css_file"
}
