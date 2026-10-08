{ chatgptDesktop, nodejs }:

chatgptDesktop.overrideAttrs (old: {
  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ nodejs ];

  # Append files to app.asar by rewriting its header only, so the patchelf'd
  # app.asar.unpacked native modules stay untouched.
  postInstall = (old.postInstall or "") + ''
    asarPath="$out/lib/chatgpt/resources/app.asar"
    chmod u+w "$asarPath"

    node - "$asarPath" ${./chatgpt-desktop-theme.cjs} <<'JS'
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
      const parts = file.split('/');
      const name = parts.pop();
      const dir = parts.length ? entry(parts.join('/')) : header;
      dir.files[name] = { size: buf.length, offset: String(end), integrity: integrity(buf) };
      chunks.push(buf);
      end += buf.length;
    }

    // Drop the native min/max/close overlay (unneeded under a tiling WM)
    const overlay = /(titleBarStyle:`hidden`,titleBarOverlay:)[A-Za-z_$][\w$]*\([A-Za-z_$][\w$]*\)/g;
    const setter = /[A-Za-z_$][\w$]*\.setTitleBarOverlay\(/g;
    let patched = 0;
    for (const name of Object.keys(entry('.vite/build').files)) {
      if (!name.endsWith('.js')) continue;
      const file = '.vite/build/' + name;
      const src = read(file);
      const out = src
        .replace(overlay, (_, prefix) => { patched++; return prefix + '!1'; })
        .replace(setter, 'void(');
      if (out !== src) add(file, out);
    }
    if (!patched) throw new Error('titleBarOverlay pattern not found');

    const manifest = JSON.parse(read('package.json'));
    if (!manifest.main || !entry(manifest.main)) {
      throw new Error('ChatGPT Desktop entry point not found');
    }
    add('quickshell-theme.cjs', fs.readFileSync(themePath));
    add('quickshell-entry.cjs', 'require("./quickshell-theme.cjs");\nrequire(' +
      JSON.stringify('./' + manifest.main) + ');\n');
    manifest.main = 'quickshell-entry.cjs';
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
