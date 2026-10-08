{ config, pkgs, ... }:

let
  inherit (pkgs) nym-vpnd;
in
{
  environment.systemPackages = [ nym-vpnd ];

  boot.kernelModules = [ "tun" ];

  # Strict reverse path filtering drops traffic coming back through the tunnel
  networking.firewall.checkReversePath = "loose";

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "com.nymvpn.vpnd.unix-access" && subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  systemd.services.nym-vpnd = {
    description = "NymVPN daemon";
    # Started offline, the daemon keeps refusing to pick gateways for ~40s after the network is up
    wants = [ "network-online.target" ];
    after = [ "network-online.target" "NetworkManager.service" "systemd-resolved.service" ];
    wantedBy = [ "multi-user.target" ];
    # The daemon shells out to ip (tunnel IPv6 setup) and resolvconf (DNS)
    path = [ pkgs.iproute2 config.networking.resolvconf.package ];
    startLimitBurst = 6;
    startLimitIntervalSec = 24;
    serviceConfig = {
      ExecStart = "${nym-vpnd}/bin/nym-vpnd -v run-as-service";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # Not a oneshot so a slow connection never holds back the login screen
  systemd.services.nym-vpn-autoconnect = {
    description = "Connect NymVPN at boot";
    wants = [ "network-online.target" ];
    after = [ "nym-vpnd.service" "network-online.target" ];
    requires = [ "nym-vpnd.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ nym-vpnd ];
    serviceConfig = {
      # Runs as the user the polkit rule above authorizes
      User = "honey";
      # Wi-Fi may come up after this service starts
      Restart = "on-failure";
      RestartSec = 10;
    };
    script = ''
      for _ in $(seq 1 30); do
        nym-vpnc status >/dev/null 2>&1 && break
        sleep 1
      done

      timeout 60 nym-vpnc connect --wait || true

      # Leaving the daemon in its error state would keep the kill switch blocking all traffic
      if ! nym-vpnc status | grep -q '^State: Connected'; then
        nym-vpnc disconnect --wait
        exit 1
      fi
    '';
  };
}
