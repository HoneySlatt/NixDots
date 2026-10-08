{
  services.jellyfin = {
    enable = true;
    openFirewall = true; # opens port 8096 (HTTP) and 8920 (HTTPS) locally
  };

  # Allow Jellyfin to use the AMD GPU for hardware transcoding
  users.users.jellyfin.extraGroups = [ "render" "video" ];
}
