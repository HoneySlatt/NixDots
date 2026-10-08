switch_firefox() {
  local profiles_ini="$HOME/.config/mozilla/firefox/profiles.ini"
  [ -f "$profiles_ini" ] || return 0

  local profile_path
  profile_path=$(awk -F= '/^\[Profile/{path=""; def=0} /^Path=/{path=$2} /^Default=1/{def=1} def && path {print path; exit}' "$profiles_ini")
  [ -n "$profile_path" ] || return 0

  local profile_dir="$HOME/.config/mozilla/firefox/$profile_path"
  [ -d "$profile_dir" ] || return 0

  local chrome_dir="$profile_dir/chrome"
  local user_js="$profile_dir/user.js"
  local user_chrome="$chrome_dir/userChrome.css"
  local user_content="$chrome_dir/userContent.css"

  mkdir -p "$chrome_dir"

  local dark_mode
  case "${C[gtk_scheme]}" in
    prefer-light) dark_mode=0 ;;
    *)            dark_mode=1 ;;
  esac

  {
    echo 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
    echo "user_pref(\"ui.systemUsesDarkTheme\", ${dark_mode});"
  } > "$user_js"

  cat > "$user_chrome" << EOF
/* Quickshell theme - auto-generated, do not edit */
:root {
  --toolbox-bgcolor-inactive:     ${C[mantle]} !important;
  --toolbarbutton-icon-fill:      ${C[accent]} !important;
  --lwt-text-color:               ${C[text]} !important;
  --toolbar-field-color:          ${C[text]} !important;
  --tab-selected-textcolor:       ${C[text]} !important;
  --toolbar-field-focus-color:    ${C[text]} !important;
  --toolbar-color:                ${C[text]} !important;
  --newtab-text-primary-color:    ${C[text]} !important;
  --arrowpanel-color:             ${C[text]} !important;
  --arrowpanel-background:        ${C[base]} !important;
  --sidebar-text-color:           ${C[text]} !important;
  --lwt-sidebar-text-color:       ${C[text]} !important;
  --lwt-sidebar-background-color: ${C[crust]} !important;
  --toolbar-bgcolor:              ${C[surface0]} !important;
  --newtab-background-color:      ${C[base]} !important;
}

#permissions-granted-icon {
  color: ${C[mantle]} !important;
}

.sidebar-placesTree {
  background-color: ${C[base]} !important;
}

#TabsToolbar {
  background-color: ${C[mantle]} !important;
  color: ${C[text]} !important;
}

#TabsToolbar * {
  color: ${C[text]} !important;
}

hbox#titlebar {
  background-color: ${C[mantle]} !important;
  color: ${C[text]} !important;
}

.urlbar-background {
  background-color: ${C[base]} !important;
}

.urlbarView-url {
  color: ${C[accent]} !important;
}

#navigator-toolbox,
#nav-bar,
#toolbar-menubar,
#PersonalToolbar {
  background-color: ${C[mantle]} !important;
  color: ${C[text]} !important;
  border-color: ${C[surface1]} !important;
}

EOF

  cat > "$user_content" << EOF
/* Quickshell theme - auto-generated, do not edit */
@-moz-document url-prefix("about:") {
  :root {
    --in-content-page-color:      ${C[text]} !important;
    --color-accent-primary:       ${C[accent]} !important;
    --color-accent-primary-hover: ${C[blue]} !important;
    background-color:             ${C[base]} !important;
    --in-content-page-background: ${C[base]} !important;
  }
}

@-moz-document url("about:newtab"), url("about:home") {
  :root {
    --newtab-background-color:           ${C[base]} !important;
    --newtab-background-color-secondary: ${C[surface0]} !important;
    --newtab-element-hover-color:        ${C[surface0]} !important;
    --newtab-text-primary-color:         ${C[text]} !important;
    --newtab-wordmark-color:             ${C[text]} !important;
    --newtab-primary-action-background:  ${C[accent]} !important;
  }
}

@-moz-document url-prefix("about:preferences") {
  :root {
    --in-content-text-color:     ${C[text]} !important;
    --link-color:                ${C[accent]} !important;
    --link-color-hover:          ${C[blue]} !important;
    --in-content-box-background: ${C[surface0]} !important;
  }

  .main-content {
    background-color: ${C[crust]} !important;
  }
}
/* --- userstyles --- */
EOF
}
