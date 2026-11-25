{ lib
, appimageTools
, fetchurl
}:

let
  pname = "rootapp";
  version = "0.9.164";
  src = fetchurl {
    # Upstream replaces the AppImage at this URL for each release.
    url = "https://installer.rootapp.com/installer/Linux/X64/Root.AppImage";
    hash = "sha256-rdhCGvBpVsb8LmBktg1Brm4+8MWLFAeIC6ASntyHZD8=";
  };
  contents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # The bundled .NET runtime loads ICU from the host.
  extraPkgs = pkgs: [ pkgs.icu ];

  extraInstallCommands = ''
    grep -Fxq 'X-AppImage-Version=${version}' ${contents}/Root.desktop
    # Root writes a hidden rootapp.desktop in the user profile for its URL handler.
    install -Dm644 ${contents}/Root.desktop "$out/share/applications/rootapp-client.desktop"
    install -Dm644 ${contents}/Root.png "$out/share/icons/hicolor/512x512/apps/rootapp.png"
    substituteInPlace "$out/share/applications/rootapp-client.desktop" \
      --replace-fail 'Exec=Root' 'Exec=rootapp' \
      --replace-fail 'Icon=Root' 'Icon=rootapp' \
      --replace-fail 'Categories=Utility;' 'Categories=Network;Chat;'
  '';

  meta = {
    description = "Voice, video and text chat for communities";
    homepage = "https://www.rootapp.com/";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "rootapp";
  };
}
