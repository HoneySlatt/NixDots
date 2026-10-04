{ stdenv
, fetchurl
, autoPatchelfHook
, dbus
, libmnl
, libnftnl
}:

stdenv.mkDerivation rec {
  pname = "nym-vpnd";
  version = "2026.12.4";

  src = fetchurl {
    url = "https://github.com/nymtech/nym-vpn-client/releases/download/nym-vpn-v${version}/nym-vpn-core-v${version}_linux_x86_64.tar.gz";
    hash = "sha256-F+x8HUE5Uyiq2mpxYzuhHJoVKWDYNvALpql5L7CqdqQ=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ dbus libmnl libnftnl stdenv.cc.cc.lib ];

  installPhase = ''
    install -Dm755 -t $out/bin nym-vpnd nym-vpnc
  '';

  meta.mainProgram = "nym-vpnc";
}
