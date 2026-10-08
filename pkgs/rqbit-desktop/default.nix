{ lib
, stdenv
, fetchurl
, dpkg
, autoPatchelfHook
, wrapGAppsHook3
, webkitgtk_4_1
, gtk3
, libsoup_3
, openssl
, dbus
}:

stdenv.mkDerivation rec {
  pname = "rqbit-desktop";
  version = "9.0.1";

  src = fetchurl {
    url = "https://github.com/ikatson/rqbit/releases/download/v${version}/rqbit-desktop_${version}_amd64.deb";
    hash = "sha256-MU3VUwYBO9e0WVak+7t2EG1fyRdnwZyf+G1+dC0PUmk=";
  };

  nativeBuildInputs = [ dpkg autoPatchelfHook wrapGAppsHook3 ];

  buildInputs = [ webkitgtk_4_1 gtk3 libsoup_3 openssl dbus ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r usr/* $out
    runHook postInstall
  '';

  meta = with lib; {
    description = "Desktop app for the rqbit BitTorrent client";
    homepage = "https://github.com/ikatson/rqbit";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "rqbit-desktop";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
