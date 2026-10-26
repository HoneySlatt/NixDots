# Patched nixpkgs packages, applied on the desktop only
final: prev: {
  # Sort library by overridden title when set
  heroic-unwrapped = prev.heroic-unwrapped.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./heroic-gog-profile.patch ];
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/frontend/screens/Library/index.tsx \
        --replace-fail "a.title.toUpperCase()" "(a.overrides?.title || a.title).toUpperCase()" \
        --replace-fail "b.title.toUpperCase()" "(b.overrides?.title || b.title).toUpperCase()"
      # Game page background uses the (possibly overridden) cover art first
      substituteInPlace src/frontend/screens/Game/GamePage/index.tsx \
        --replace-fail "src={art_background || art_cover}" "src={art_cover || art_background}"
    '';
  });

  # Electron and Chromium do not recognise niri or Hyprland and skip the keyring.
  brave-origin = prev.brave-origin.override {
    commandLineArgs = "--password-store=gnome-libsecret";
  };
  element-desktop = final.callPackage ../element-desktop {
    element-desktop = prev.element-desktop;
  };

  # Flaky textual UI test that fails intermittently in the sandbox
  mistral-vibe = prev.mistral-vibe.overrideAttrs (old: {
    disabledTestPaths = (old.disabledTestPaths or [ ]) ++ [
      "tests/cli/textual_ui/test_resume_local_session.py::test_successful_resume_replaces_stale_turn_presentation"
    ];
  });
}
