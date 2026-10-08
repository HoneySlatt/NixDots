{ config, ... }:

{
  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";

  virtualisation.oci-containers.containers.materialious = {
    image = "docker.io/wardpearce/materialious-full:1.18.7";

    extraOptions = [ "--network=host" ];

    volumes = [
      "/NAS/Materialious:/materialious-data"
    ];

    environment = {
      PORT = "3001";
      ORIGIN = "http://localhost:3001";
      DATABASE_CONNECTION_URI = "sqlite:///materialious-data/materialious.db";

      COOKIE_SECRET = "RLKxQiYJm48izKyl1nE2gkDWJL7Pu7IZefGpDFIkmG4=";
      PUBLIC_INTERNAL_AUTH = "true";
      PUBLIC_REQUIRE_AUTH = "false";
      PUBLIC_REGISTRATION_ALLOWED = "true";
      PUBLIC_CAPTCHA_DISABLED = "true";

      PUBLIC_DEFAULT_INVIDIOUS_INSTANCE = "http://localhost:${toString config.services.invidious.port}";
      PUBLIC_DEFAULT_RETURNYTDISLIKES_INSTANCE = "https://returnyoutubedislikeapi.com";
      PUBLIC_DEFAULT_SPONSERBLOCK_INSTANCE = "https://sponsor.ajay.app";
      PUBLIC_DEFAULT_DEARROW_INSTANCE = "https://sponsor.ajay.app";
      PUBLIC_DEFAULT_DEARROW_THUMBNAIL_INSTANCE = "https://dearrow-thumb.ajay.app";

      PUBLIC_DEFAULT_SETTINGS = ''{"themeColor":"#2596be","region":"FR"}'';
    };
  };
}
