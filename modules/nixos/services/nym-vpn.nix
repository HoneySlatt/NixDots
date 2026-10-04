{ config, pkgs, ... }:

let
  nym-vpnd = pkgs.callPackage ../../home/pkgs/nym-vpnd.nix { };
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
    wants = [ "network-pre.target" ];
    after = [ "network-pre.target" "NetworkManager.service" "systemd-resolved.service" ];
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
}
