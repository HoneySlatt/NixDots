{ element-desktop, nodejs }:

(element-desktop.override {
  # Electron skips the keyring on niri and Hyprland. The wrapper only adds the
  # Wayland flags when NIXOS_OZONE_WL is set, which Hyprland does not export.
  commandLineArgs = "--password-store=gnome-libsecret --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true";
}).overrideAttrs (old: {
  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ nodejs ];

  # Element's main process is ESM. Prepend the theme watcher without repacking
  # the native seshat module that lives outside the archive.
  postInstall = (old.postInstall or "") + ''
    asarPath="$out/share/element/app.asar"
    chmod u+w "$asarPath"

    node - "$asarPath" ${./element-desktop-theme.mjs} <<'JS'
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
      if (!e) throw new Error('missing asar entry ' + file);
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
      const parts = file.split('/');
      const name = parts.pop();
      const dir = parts.length ? entry(parts.join('/')) : header;
      dir.files[name] = { size: buf.length, offset: String(end), integrity: integrity(buf) };
      chunks.push(buf);
      end += buf.length;
    }

    const manifest = JSON.parse(read('package.json'));
    if (!manifest.main || manifest.main === 'amane-entry.mjs') {
      throw new Error('unexpected Element entry point: ' + manifest.main);
    }
    const main = manifest.main.replace(/^\.\//, "");
    add('amane-theme.mjs', fs.readFileSync(themePath));
    add('amane-entry.mjs', 'import "./amane-theme.mjs";\nimport "./' + main + '";\n');
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
})
