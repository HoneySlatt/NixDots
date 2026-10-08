{ claudeDesktop, nodejs, makeWrapper }:

claudeDesktop.overrideAttrs (old: {
  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ nodejs makeWrapper ];

  postInstall = (old.postInstall or "") + ''
    themeRoot="$TMPDIR/claude-amane"
    asar extract "$out/lib/claude-desktop/resources/app.asar" "$themeRoot"
    cp ${./claude-desktop-theme.cjs} "$themeRoot/amane-theme.cjs"

    node - "$themeRoot" <<'JS'
    const fs = require('fs');
    const path = require('path');
    const root = process.argv[2];
    const manifestPath = path.join(root, 'package.json');
    const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
    if (!manifest.main || !fs.existsSync(path.join(root, manifest.main))) {
      throw new Error('Claude Desktop entry point not found');
    }
    fs.writeFileSync(path.join(root, 'amane-entry.cjs'),
      'require("./amane-theme.cjs");\nrequire(' +
      JSON.stringify('./' + manifest.main) + ');\n');
    manifest.main = 'amane-entry.cjs';
    fs.writeFileSync(manifestPath, JSON.stringify(manifest));
    JS

    # Drop the native min/max/close overlay (unneeded under a tiling WM)
    node - "$themeRoot" <<'JS'
    const fs = require('fs');
    const path = require('path');
    const re = /titleBarOverlay:(?:!0|[A-Za-z_$][\w$]*)(?=,trafficLightPosition)/g;
    let patched = 0;
    (function walk(dir) {
      for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
        const p = path.join(dir, e.name);
        if (e.isDirectory()) { if (e.name !== 'node_modules') walk(p); continue; }
        if (!p.endsWith('.js')) continue;
        const src = fs.readFileSync(p, 'utf8');
        const out = src.replace(re, () => { patched++; return 'titleBarOverlay:!1'; });
        if (out !== src) fs.writeFileSync(p, out);
      }
    })(process.argv[2]);
    if (!patched) throw new Error('titleBarOverlay pattern not found');
    JS

    asar pack --unpack "*.node" "$themeRoot" "$out/lib/claude-desktop/resources/app.asar"
  '';

  postFixup = (old.postFixup or "") + ''
    wrapProgram "$out/bin/claude-desktop" \
      --set FONTCONFIG_FILE ${./google-sans-code-fonts.conf}
  '';
})
