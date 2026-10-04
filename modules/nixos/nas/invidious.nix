{ lib, pkgs, ... }:

let
  companionKey = "z98YxWj0MDvXLzJs";
in
{
  users.users.invidious = {
    isSystemUser = true;
    group = "invidious";
  };
  users.groups.invidious = { };

  services.invidious = {
    enable = true;
    database.createLocally = true;
    port = 3000;
    domain = "localhost";

    settings = {
      external_port = 3000;
      https_only = false;
      registration_enabled = true;
      invidious_companion = [ { private_url = "http://127.0.0.1:8282/companion"; } ];
      invidious_companion_key = companionKey;
    };
  };

  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";

  virtualisation.oci-containers.containers.invidious-companion = {
    image = "quay.io/invidious/invidious-companion:latest";
    # Bridge network is IPv4-only: YouTube bot-flags the host's IPv6 prefix
    ports = [ "127.0.0.1:8282:8282" ];
    volumes = [ "invidious-companion-cache:/var/tmp/youtubei.js" ];
    environment.SERVER_SECRET_KEY = companionKey;
  };

  # NymVPN's kill switch rejects the companion's DNS and YouTube bot-flags Nym exits, so tag the
  # podman bridge with Nym's split tunnel marks (ct 0xf42, fwmark 0x14d) to bypass the tunnel.
  # Should bridge traffic ever go through the tunnel, its MTU (1340) is below the bridge's (1500),
  # so TCP MSS is clamped both ways.
  systemd.services.nym-exclude-podman = {
    description = "Route podman bridge traffic outside NymVPN";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.nftables}/bin/nft -f ${pkgs.writeText "nym-exclude-podman.nft" ''
        destroy table inet nym-exclude-podman
        table inet nym-exclude-podman {
          chain prerouting {
            type filter hook prerouting priority mangle; policy accept;
            ip saddr 10.88.0.0/16 ip daddr != 10.88.0.0/16 ct mark set 0xf42 meta mark set 0x14d
          }
          chain forward {
            type filter hook forward priority mangle; policy accept;
            oifname "tun*" ip saddr 10.88.0.0/16 tcp flags syn tcp option maxseg size > 1300 tcp option maxseg size set 1300
            iifname "tun*" ip daddr 10.88.0.0/16 tcp flags syn tcp option maxseg size > 1300 tcp option maxseg size set 1300
          }
        }
      ''}";
      ExecStop = "${pkgs.nftables}/bin/nft destroy table inet nym-exclude-podman";
    };
  };

  systemd.services.invidious.after = [ "podman-invidious-companion.service" ];

  systemd.services.invidious.serviceConfig = {
    DynamicUser = lib.mkForce false;
    PrivateUsers = lib.mkForce false;
  };

  networking.firewall.allowedTCPPorts = [ 3000 ];
}
