{
  services.samba = {
    enable = true;
    # Standalone server over SMB3 only: no NetBIOS name service, no domain membership
    nmbd.enable = false;
    winbindd.enable = false;

    settings = {
      global = {
        "workgroup"     = "WORKGROUP";
        "server string" = "NixBTW NAS";
        "security"      = "user";

        "server min protocol" = "SMB3";
        "server smb encrypt"  = "required";
        "disable netbios"     = "yes";
        "smb ports"           = "445";
        "restrict anonymous"  = "2";

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

  networking.firewall.allowedTCPPorts = [ 445 ];
}
