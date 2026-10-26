{ lib
, stdenv
, stdenvNoCC
, fetchurl
, dpkg
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
  version = "1.1.3";

  src = fetchurl {
    url = "https://code.kimi.ai/kimi-code/desktop/binaries/${version}/KimiCode-${version}-linux-amd64.deb";
    hash = "sha256-tHyxPIPmudE6awH4JlEDGXV/CJOEJ/o+VdjPCZJB7Iw=";
  };

  nativeBuildInputs = [ dpkg autoPatchelfHook makeWrapper wrapGAppsHook3 ];
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
