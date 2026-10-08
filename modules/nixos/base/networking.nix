{
  networking.networkmanager = {
    enable = true;
    # Random MAC per Wi-Fi network (stable for each one), random per Ethernet profile
    wifi.macAddress = "stable-ssid";
    ethernet.macAddress = "stable";
    # Keep the hostname out of DHCP requests on every network
    settings.connection = {
      "ipv4.dhcp-send-hostname" = false;
      "ipv6.dhcp-send-hostname" = false;
    };
  };
}
