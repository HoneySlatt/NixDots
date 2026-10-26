{ lib
, stdenv
, stdenvNoCC
, fetchurl
, patchelf
, makeWrapper
, zstd
, bash
, git
, ripgrep
, fd
, xdg-utils
, libxcb
}:

stdenvNoCC.mkDerivation rec {
  pname = "kimi-code";
  version = "2.3.2";

  src = fetchurl {
    url = "https://code.kimi.ai/kimi-code/binaries/${version}/kimi-code-linux-x64.zst";
    hash = "sha256-qfumrvkj1W3LJvLgYyoAA6rqp5CFjHu006shkLhXhs4=";
  };

  nativeBuildInputs = [ patchelf makeWrapper zstd ];
  buildInputs = [ stdenv.cc.cc.lib ];

  dontUnpack = true;
  dontBuild = true;
  # Preserve the Node.js single-executable application payload.
  dontStrip = true;
  # Rewriting this executable's RPATH causes a startup crash.
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    zstd -d $src -o $out/bin/kimi
    chmod 755 $out/bin/kimi
    patchelf --set-interpreter ${stdenv.cc.bintools.dynamicLinker} $out/bin/kimi
    wrapProgram $out/bin/kimi \
      --set KIMI_CODE_NO_AUTO_UPDATE 1 \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ stdenv.cc.cc.lib libxcb ]} \
      --prefix PATH : ${lib.makeBinPath [ bash git ripgrep fd xdg-utils ]}
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    set -o pipefail
    export KIMI_CODE_HOME="$TMPDIR/kimi-code-check"
    export KIMI_CODE_CACHE_DIR="$TMPDIR/kimi-code-cache"
    $out/bin/kimi --version | grep -Fx '${version}'
    KIMI_CODE_NATIVE_ASSET_SMOKE=1 $out/bin/kimi
    runHook postInstallCheck
  '';

  meta = with lib; {
    description = "Kimi coding agent for the terminal";
    homepage = "https://github.com/MoonshotAI/kimi-code";
    license = licenses.mit;
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "kimi";
  };
}
