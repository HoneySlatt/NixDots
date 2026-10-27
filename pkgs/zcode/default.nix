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
  pname = "zcode";
  version = "3.16.3";

  src = fetchurl {
    url = "https://cdn-zcode.z.ai/zcode/electron/releases/${version}/linux-x64/ZCode-${version}-linux-x64.deb";
    hash = "sha256-EoEysZWXf9CoyKbClc9C/hWSItelxe/v2LXwDviKuLY=";
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
    cp -r opt/ZCode $out/lib/zcode
    cp -r usr/share/applications usr/share/icons $out/share/
    substituteInPlace $out/share/applications/zcode.desktop \
      --replace-fail 'Exec=/opt/ZCode/zcode %U' "Exec=$out/bin/zcode %U"
    runHook postInstall
  '';

  postInstall = ''
    asarPath="$out/lib/zcode/resources/app.asar"
    chmod u+w "$asarPath"

    node - "$asarPath" ${./zcode-theme.cjs} <<'JS'
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
      throw new Error('ZCode entry point not found');
    }
    add('amane-theme.cjs', fs.readFileSync(themePath));
    add('amane-entry.mjs', 'import "./amane-theme.cjs";\nimport ' +
      JSON.stringify('./' + manifest.main) + ';\n');
    manifest.main = 'amane-entry.mjs';
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
    makeWrapper $out/lib/zcode/zcode $out/bin/zcode \
      "''${gappsWrapperArgs[@]}" \
      --prefix PATH : ${lib.makeBinPath [ bash git ripgrep fd xdg-utils ]}
  '';

  meta = with lib; {
    description = "ZCode desktop coding workspace";
    homepage = "https://zcode.z.ai";
    license = licenses.unfree;
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "zcode";
  };
}
