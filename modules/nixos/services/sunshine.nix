{
  services.sunshine = {
    enable = true;
    openFirewall = true;
    capSysAdmin = true;
  };

  # No mDNS broadcast of the hostname; Moonlight adds this PC by IP instead
  services.avahi.enable = false;
}
