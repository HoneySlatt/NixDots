{ ... }:

{
  services.samba = {
    enable = true;
    openFirewall = true; # opens ports 139 and 445

    settings = {
      global = {
        "workgroup"     = "WORKGROUP";
        "server string" = "NixBTW NAS";
        "security"      = "user";

        # Performance tweaks
        "socket options" = "TCP_NODELAY IPTOS_LOWDELAY";
      };

      "NAS" = {
        "path"        = "/NAS";
        "browseable"  = "yes";
        "read only"   = "no";
        "writable"    = "yes";
        "guest ok"    = "no";
        "valid users" = "honey";
      };
    };
  };
}
