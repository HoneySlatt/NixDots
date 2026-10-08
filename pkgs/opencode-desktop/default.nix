{ opencode-desktop }:

opencode-desktop.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [ ./opencode-desktop-theme.patch ];

  postPatch = (old.postPatch or "") + ''
    cp ${./opencode-desktop-theme.mjs} packages/desktop/src/main/amane-theme.mjs
  '';
})
