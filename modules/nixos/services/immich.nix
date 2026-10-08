{
  services.immich = {
    enable       = true;
    host         = "0.0.0.0";
    openFirewall = true; # port 2283
    mediaLocation = "/NAS/Photos";
  };
}
