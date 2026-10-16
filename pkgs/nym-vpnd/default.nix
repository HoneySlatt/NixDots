{ stdenv
, fetchurl
, autoPatchelfHook
, dbus
, libmnl
, libnftnl
}:

stdenv.mkDerivation rec {
  pname = "nym-vpnd";
  version = "2026.13.0";

  src = fetchurl {
    url = "https://github.com/nymtech/nym-vpn-client/releases/download/nym-vpn-v${version}/nym-vpn-core-v${version}_linux_x86_64.tar.gz";
    hash = "sha256-sRisxcWx3knAeVWNJ2dPa+p1GhPgDoHmgx0MLZXM1b4=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ dbus libmnl libnftnl stdenv.cc.cc.lib ];

  installPhase = ''
    install -Dm755 -t $out/bin nym-vpnd nym-vpnc

    # Upstream polkit action guarding the daemon socket (not shipped in the tarball)
    install -Dm644 /dev/stdin $out/share/polkit-1/actions/com.nymvpn.vpnd.unix-access.policy <<EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <policyconfig>
      <action id="com.nymvpn.vpnd.unix-access">
        <description>Connect via unix socket</description>
        <message>Authentication is required to connect to the daemon</message>
        <defaults>
          <allow_any>auth_admin</allow_any>
          <allow_inactive>auth_admin</allow_inactive>
          <allow_active>auth_self</allow_active>
        </defaults>
      </action>
    </policyconfig>
    EOF
  '';

  meta.mainProgram = "nym-vpnc";
}
