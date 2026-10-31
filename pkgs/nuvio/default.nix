{ lib
, appimageTools
, fetchurl
}:

let
  pname = "nuvio";
  version = "0.1.33-alpha";

  src = fetchurl {
    url = "https://github.com/NuvioMedia/NuvioDesktop/releases/download/${version}/Nuvio-Linux-x86_64-${version}.AppImage";
    hash = "sha256-Nfu41NEGCu0Wn2ID26PWVe1VT9JeOEqut8Tk4PdftOA=";
  };

  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # Native player bridge is extracted from the jar at runtime
  extraPkgs = pkgs: with pkgs; [
    mpv-unwrapped
    webkitgtk_4_1
    gtk3
    libxcomposite
  ];

  extraInstallCommands = ''
    install -Dm644 ${appimageContents}/Nuvio.desktop $out/share/applications/nuvio.desktop
    install -Dm644 ${appimageContents}/Nuvio.png $out/share/icons/hicolor/256x256/apps/nuvio.png
    substituteInPlace $out/share/applications/nuvio.desktop \
      --replace-fail "Exec=AppRun" "Exec=nuvio" \
      --replace-fail "Icon=Nuvio" "Icon=nuvio"
  '';

  meta = with lib; {
    description = "Media player for Stremio-compatible addons";
    homepage = "https://github.com/NuvioMedia/NuvioDesktop";
    license = licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "nuvio";
    sourceProvenance = with sourceTypes; [ binaryNativeCode binaryBytecode ];
  };
}
