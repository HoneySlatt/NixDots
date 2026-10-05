switch_cider() {
  local config="$HOME/.config/sh.cider.genten/spa-config.yml"
  [ -f "$config" ] || return 0

  local appearance="dark"
  case "${C[gtk_scheme]:-prefer-dark}" in
    prefer-light) appearance="light" ;;
  esac

  # Use readable content on filled accent controls.
  local accent="${C[accent_ui]:-${C[accent]}}"

  local accent_hex="${accent#\#}" on_accent
  on_accent="$(awk -v r="$((16#${accent_hex:0:2}))" -v g="$((16#${accent_hex:2:2}))" -v b="$((16#${accent_hex:4:2}))" '
    function linear(c) { c /= 255; return c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ^ 2.4 }
    BEGIN { l = .2126 * linear(r) + .7152 * linear(g) + .0722 * linear(b); print (l > .179 ? "#000000" : "#ffffff") }
  ')"

  local css
  css=$(cat << EOF
  customCSS: |
    :root {
      --qs-cider-base: ${C[base]};
      --qs-cider-mantle: ${C[mantle]};
      --qs-cider-text: ${C[text]};
      --qs-cider-subtext: ${C[subtext0]};
      --qs-cider-accent: ${accent};
      --qs-cider-on-accent: ${on_accent};
      --qs-cider-surface: ${C[surface0]};
    }

    :root:root,
    body.body--dark,
    body.body--light {
      --q-primary: var(--qs-cider-accent);
      --qDark: var(--qs-cider-mantle);
      --qDarkPage: var(--qs-cider-base);
      --lightBackgroundColor: var(--qs-cider-mantle);
      --glassFallbackColor: var(--qs-cider-mantle);
      --mats-darkBackgroundBase: var(--qs-cider-mantle);
      --mats-lightBackgroundBase: var(--qs-cider-mantle);
      --textDefault: var(--qs-cider-text);
      --systemPrimary: var(--qs-cider-text);
      --systemSecondary: var(--qs-cider-subtext);
      --textSecondary: var(--qs-cider-subtext);
      --systemQuaternary: var(--qs-cider-surface);
      --keyColor-tonal: color-mix(in srgb, var(--qs-cider-accent) 18%, var(--qs-cider-base));
      --mats-glazeOpacity: 0;
      --chromeButtonShadow: none;
    }

    body {
      background: var(--qs-cider-mantle) !important;
      color: var(--qs-cider-text) !important;
    }

    .new-shell-page-container {
      --pageContainerBg: var(--qs-cider-base) !important;
      background-color: var(--qs-cider-base) !important;
    }

    /* Material surfaces: preserve the layout, replace decorative glass. */
    body .blurmap-container, body .lgs-clone, body .lgs-inner,
    body .lgs-fallback, body .lcd-glass-bg, body .lcd-scrim { display: none !important; }
    body :is(.ns-sidebar--left, .new-shell-page-container) {
      background: var(--qs-cider-base) !important;
      box-shadow: none !important;
      backdrop-filter: none !important;
      -webkit-backdrop-filter: none !important;
    }
    body :is(.lgs-glass, .ns-bottom-toolbar_inline, .ns-bottom-toolbar,
      .chrome-button, .chrome-button-group, .nav-flipper,
      .search-box_container, .amp-lcd-container .player, .volume-quick-menu) {
      --textDefault: var(--qs-cider-text);
      background: var(--qs-cider-surface) !important;
      color: var(--qs-cider-text) !important;
      border: 0 !important;
      box-shadow: none !important;
      backdrop-filter: none !important;
      -webkit-backdrop-filter: none !important;
    }
    body :is(.chrome-button, .chrome-button-group, .nav-flipper,
      .search-box_container, .nav-button-content, .amp-lcd-container .player,
      .ns-bottom-toolbar_inline, .ns-sidebar--left, .new-shell-page-container,
      .c-btn--surface)::before,
    body :is(.chrome-button, .chrome-button-group, .nav-flipper,
      .search-box_container, .nav-button-content, .amp-lcd-container .player,
      .ns-bottom-toolbar_inline, .ns-sidebar--left, .new-shell-page-container,
      .c-btn--surface)::after { box-shadow: none !important; background: none !important; }
    body .ns-bottom-toolbar_inline {
      --floatingRadius: 28px !important;
      --lg-radius: 28px !important;
      --mats-glazeOpacity: 0;
      box-shadow: none !important;
    }
    /* The floating player has its own glass layer, separate from the LCD. */
    body .ns-bottom-toolbar_inline > :is(.lg-surface, .blur-surface),
    body .ns-bottom-toolbar_inline .player-border { display: none !important; }
    body .ns-bottom-toolbar_inline.ns-bottom-toolbar_floating {
      border-radius: 28px !important;
    }
    body .ns-bottom-toolbar_inline .amp-lcd-container .player {
      background: transparent !important;
      border-radius: 16px !important;
    }
    body .ns-bottom-toolbar_inline .am-playback-actions { gap: 4px; }
    body .ns-bottom-toolbar_inline .playback-action-button {
      border-radius: 16px;
      color: var(--qs-cider-text);
      opacity: 1;
      transition: border-radius .2s ease, background-color .2s ease;
    }
    body .ns-bottom-toolbar_inline .playback-action-button:hover {
      background: var(--keyColor-tonal);
    }
    body .ns-bottom-toolbar_inline .playback-action-button:active { border-radius: 10px; }
    body .ns-bottom-toolbar_inline .playback-action-button:focus-visible {
      outline: 2px solid var(--qs-cider-accent);
      outline-offset: 2px;
    }
    @media (prefers-reduced-motion: reduce) {
      body .ns-bottom-toolbar_inline .playback-action-button { transition: none; }
    }
    body[reduced-motion=true] .ns-bottom-toolbar_inline .playback-action-button { transition: none; }
    body .amp-lcd-container .player {
      background: var(--qs-cider-base) !important;
      border-radius: 16px;
    }
    body :is(.chrome-button, .chrome-button-group, .nav-flipper, .search-box_container) {
      border-radius: 999px !important;
    }
    body .search-box {
      background: transparent !important;
      color: var(--qs-cider-text) !important;
      border-radius: 999px;
    }
    body .search-box_container:focus-within {
      outline: 2px solid var(--qs-cider-accent);
      outline-offset: 2px;
    }
    /* Compact navigation pills with readable accent content. */
    body .nav-button-content {
      border-radius: 24px;
      transition: border-radius .3s cubic-bezier(.2,.8,.2,1), background-color .18s ease;
    }
    body .nav-button-content:not(.active):hover { background: var(--qs-cider-surface) !important; }
    body .nav-button-content.active {
      --textDefault: var(--qs-cider-on-accent);
      background: var(--qs-cider-accent) !important;
      color: var(--qs-cider-on-accent) !important;
    }
    body .nav-button-content.active :is(.nav-icon, .nav-text) { color: var(--qs-cider-on-accent) !important; }
    body .nav-button-content:active { border-radius: 12px; }
    /* Informational chips use flat, opaque Material surfaces. */
    body .meta-chip {
      background: var(--qs-cider-accent) !important;
      color: var(--qs-cider-on-accent) !important;
      border: 0 !important;
      outline: 0 !important;
      box-shadow: none !important;
      backdrop-filter: none !important;
      -webkit-backdrop-filter: none !important;
    }
    /* Album and playlist actions use Quasar buttons, not CBtn surfaces. */
    body:is(.body--dark, .body--light) :is(.album-actions, .album-playback-actions) .q-btn {
      --textColor1: var(--qs-cider-text);
      background: var(--keyColor-tonal) !important;
      color: var(--qs-cider-text) !important;
      border: 0 !important;
      box-shadow: none !important;
      backdrop-filter: none !important;
      -webkit-backdrop-filter: none !important;
    }
    body:is(.body--dark, .body--light) .album-playback-actions .q-btn.button {
      --textColor1: var(--qs-cider-on-accent);
      background: var(--qs-cider-accent) !important;
      color: var(--qs-cider-on-accent) !important;
    }
    body :is(.album-actions, .album-playback-actions) .q-btn::before,
    body :is(.album-actions, .album-playback-actions) .q-btn::after { display: none !important; }
    body :is(.album-actions, .album-playback-actions) .q-btn .q-btn__content {
      color: inherit !important;
    }
    body :is(.album-actions, .album-playback-actions) .q-btn:focus-visible {
      outline: 2px solid var(--qs-cider-accent);
      outline-offset: 3px;
    }
    /* Updated Cider buttons draw an outline directly on the surface. */
    body :is(.album-actions, .album-playback-actions) .c-btn > .c-btn--surface {
      outline: 0 !important;
      border: 0 !important;
      backdrop-filter: none !important;
      -webkit-backdrop-filter: none !important;
    }
    body .album-playback-actions .c-btn.button > .c-btn--surface {
      background: var(--qs-cider-accent) !important;
      color: var(--qs-cider-on-accent) !important;
    }
    /* Keep button sizes, change only their surfaces and press response. */
    body .c-btn > .c-btn--surface::before,
    body .c-btn > .c-btn--surface::after { display: none !important; }
    body .c-btn > .c-btn--surface {
      background: var(--keyColor-tonal) !important;
      color: var(--qs-cider-text) !important;
      border-radius: 24px;
      box-shadow: none !important;
      transition: border-radius .3s cubic-bezier(.2,.8,.2,1), background-color .18s ease;
    }
    body .c-btn.c-btn--primary-text > .c-btn--surface {
      background: var(--qs-cider-accent) !important;
      --textDefault: var(--qs-cider-on-accent);
      color: var(--qs-cider-on-accent) !important;
    }
    body .c-btn--primary-text { color: var(--qs-cider-on-accent) !important; }
    body .c-btn:active > .c-btn--surface { border-radius: 12px; }
    body .chrome-button:hover { background: var(--keyColor-tonal) !important; }
    body :is(.c-btn, .chrome-button, .sidebar_nav-btn):focus-visible {
      outline: 2px solid var(--qs-cider-accent);
      outline-offset: 3px;
    }
    body :is(.q-menu, .volume-quick-menu, .q-dialog__inner > .q-card) {
      background: var(--qs-cider-surface) !important;
      color: var(--qs-cider-text) !important;
      border-radius: 24px;
      border: 0 !important;
      backdrop-filter: none !important;
      -webkit-backdrop-filter: none !important;
      box-shadow: 0 6px 24px #00000030 !important;
    }
    body .q-menu .q-item { border-radius: 16px; }
    body .cider-progress-bar .progress-current,
    body .cider-progress-bar .progress-cursor {
      background-color: var(--qs-cider-accent) !important;
      box-shadow: none !important;
    }
    body .cider-progress-bar .progress-bar-content { background-color: var(--keyColor-tonal) !important; }
    body .cider-progress-bar .transition-glow { display: none; }
    body .c-listitem.selected { background-color: var(--keyColor-tonal) !important; }
    @media (prefers-reduced-motion: reduce) {
      body :is(.nav-button-content, .c-btn--surface) { transition: none !important; }
    }
    body[reduced-motion=true] :is(.nav-button-content, .c-btn--surface) { transition: none !important; }
EOF
)

  local tmp
  tmp="$(mktemp)" || return 0

  if APPEARANCE="$appearance" ACCENT="$accent" CSS_BLOCK="$css" perl -0pe '
    my $appearance = $ENV{APPEARANCE};
    my $accent = $ENV{ACCENT};
    my $css = $ENV{CSS_BLOCK};

    s/(^visual:\n.*?^  appearance: )[^\n]*/${1}$appearance/ms;
    s/^  customCSS:.*?(?=^  [A-Za-z0-9_]+:)/$css\n/ms;
    s/^    useSystemAccentColor: .*/    useSystemAccentColor: false/m;
    s/^    customAccentColor: .*/    customAccentColor: true/m;
    s/^    customAccentColorValue: .*/    customAccentColorValue: "$accent"/m;
  ' "$config" > "$tmp"; then
    mv "$tmp" "$config"
  else
    rm -f "$tmp"
  fi
}
