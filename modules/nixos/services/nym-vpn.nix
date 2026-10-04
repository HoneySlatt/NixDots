{ pkgs, ... }:

let
  nym-vpnd = pkgs.callPackage ../../home/pkgs/nym-vpnd.nix { };
in
{
  environment.systemPackages = [ nym-vpnd ];

  boot.kernelModules = [ "tun" ];

  # Strict reverse path filtering drops traffic coming back through the tunnel
  networking.firewall.checkReversePath = "loose";

  systemd.services.nym-vpnd = {
    description = "NymVPN daemon";
    wants = [ "network-pre.target" ];
    after = [ "network-pre.target" "NetworkManager.service" "systemd-resolved.service" ];
    wantedBy = [ "multi-user.target" ];
    startLimitBurst = 6;
    startLimitIntervalSec = 24;
    serviceConfig = {
      ExecStart = "${nym-vpnd}/bin/nym-vpnd -v run-as-service";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
