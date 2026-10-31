{ lib
, stdenv
, stdenvNoCC
, fetchurl
, dpkg
, nodejs
, autoPatchelfHook
, makeWrapper
, wrapGAppsHook3
, alsa-lib
, at-spi2-atk
, at-spi2-core
, cairo
, cups
, dbus
, expat
, glib
, gtk3
, libgbm
, libnotify
, libsecret
, libx11
, libxcb
, libxcomposite
, libxdamage
, libxext
, libxfixes
, libxkbcommon
, libxrandr
, nspr
, nss
, pango
, systemdLibs
, libGL
, pipewire
, vulkan-loader
, bash
, git
, ripgrep
, fd
, xdg-utils
}:

stdenvNoCC.mkDerivation rec {
  pname = "kimi-code-desktop";
  version = "1.2.0";

  src = fetchurl {
    url = "https://code.kimi.ai/kimi-code/desktop/binaries/${version}/KimiCode-${version}-linux-amd64.deb";
    hash = "sha256-zl3E0QwBt8BtdQ0NLNeWgXHN5EgK3D5BM16HlQVaoBM=";
  };

  nativeBuildInputs = [ dpkg nodejs autoPatchelfHook makeWrapper wrapGAppsHook3 ];
  buildInputs = [
    alsa-lib at-spi2-atk at-spi2-core cairo cups dbus expat glib gtk3
    libgbm libx11 libxcb libxcomposite libxdamage libxext libxfixes
    libxkbcommon libxrandr nspr nss pango systemdLibs stdenv.cc.cc.lib
  ];
  runtimeDependencies = [ libGL libnotify libsecret pipewire vulkan-loader ];

  dontBuild = true;
  dontStrip = true;
  dontWrapGApps = true;

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib $out/share
    cp -r "opt/Kimi Code" $out/lib/kimi-code-desktop
    cp -r usr/share/applications usr/share/icons usr/share/metainfo $out/share/
    substituteInPlace $out/share/applications/kimi-code.desktop \
      --replace-fail 'Exec="/opt/Kimi Code/kimi-code"' "Exec=$out/bin/kimi-code-desktop"
    runHook postInstall
  '';

  postInstall = ''
    asarPath="$out/lib/kimi-code-desktop/resources/app.asar"
    chmod u+w "$asarPath"

    node - "$asarPath" ${./kimi-code-desktop-theme.cjs} <<'JS'
    const crypto = require('crypto');
    const fs = require('fs');
    const [asarPath, themePath] = process.argv.slice(2);

    const asar = fs.readFileSync(asarPath);
    const header = JSON.parse(asar.toString('utf8', 16, 16 + asar.readUInt32LE(12)));
    const data = asar.subarray(8 + asar.readUInt32LE(4));
    const chunks = [data];
    let end = data.length;

    function entry(file) {
      let node = header;
      for (const part of file.split('/')) node = node && node.files && node.files[part];
      return node;
    }

    function read(file) {
      const e = entry(file);
      return data.subarray(Number(e.offset), Number(e.offset) + e.size).toString();
    }

    function integrity(buf) {
      const sha = b => crypto.createHash('sha256').update(b).digest('hex');
      const blockSize = 4 * 1024 * 1024;
      const blocks = [];
      for (let i = 0; i < buf.length; i += blockSize) blocks.push(sha(buf.subarray(i, i + blockSize)));
      return { algorithm: 'SHA256', hash: sha(buf), blockSize, blocks };
    }

    function add(file, content) {
      const buf = Buffer.from(content);
      header.files[file] = { size: buf.length, offset: String(end), integrity: integrity(buf) };
      chunks.push(buf);
      end += buf.length;
    }

    const manifest = JSON.parse(read('package.json'));
    if (!manifest.main || !entry(manifest.main)) {
      throw new Error('Kimi Code Desktop entry point not found');
    }
    add('amane-theme.cjs', fs.readFileSync(themePath));
    add('amane-entry.cjs', 'require("./amane-theme.cjs");\nrequire(' +
      JSON.stringify('./' + manifest.main) + ');\n');
    manifest.main = 'amane-entry.cjs';
    add('package.json', JSON.stringify(manifest));

    const json = Buffer.from(JSON.stringify(header));
    const padded = (json.length + 3) & ~3;
    const head = Buffer.alloc(16 + padded);
    head.writeUInt32LE(4, 0);
    head.writeUInt32LE(8 + padded, 4);
    head.writeUInt32LE(4 + padded, 8);
    head.writeUInt32LE(json.length, 12);
    json.copy(head, 16);
    fs.writeFileSync(asarPath, Buffer.concat([head, ...chunks]));
    JS

    chmod u-w "$asarPath"
  '';

  postFixup = ''
    makeWrapper $out/lib/kimi-code-desktop/kimi-code $out/bin/kimi-code-desktop \
      "''${gappsWrapperArgs[@]}" \
      --prefix PATH : ${lib.makeBinPath [ bash git ripgrep fd xdg-utils ]}
  '';

  meta = with lib; {
    description = "Kimi Code desktop coding workspace";
    homepage = "https://www.kimi.ai/code";
    license = licenses.unfree;
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "kimi-code-desktop";
  };
}
