{ lib
, stdenv
, fetchurl
, dpkg
, pkg-config
, bash
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

  nativeBuildInputs = [ dpkg pkg-config autoPatchelfHook wrapGAppsHook3 ];

  buildInputs = [ webkitgtk_4_1 gtk3 libsoup_3 openssl dbus ];

  buildPhase = ''
    runHook preBuild
    $CC -shared -fPIC -O2 -Wall -Wextra ${./rqbit-theme.c} \
      -o librqbit-theme.so $(pkg-config --cflags --libs webkit2gtk-4.1) -ldl
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r usr/* $out
    mkdir -p $out/lib $out/libexec $out/share/rqbit-desktop
    mv $out/bin/rqbit-desktop $out/libexec/rqbit-desktop
    install -m755 librqbit-theme.so $out/lib/librqbit-theme.so
    install -m644 ${../../modules/home/amane/config/themes/apps/rqbit.sh} $out/share/rqbit-desktop/rqbit.sh
    substitute ${./rqbit-desktop.sh} $out/bin/rqbit-desktop \
      --subst-var-by shell ${bash}/bin/bash --subst-var-by out "$out"
    chmod +x $out/bin/rqbit-desktop
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
