{ config, pkgs, ... }:

let
  forge = config.services.forgejo;
  runnerToken = "/etc/forgejo-runner/project.env";
in
{
  # Make the matching CLI available for local account administration.
  environment.systemPackages = [ forge.package ];

  services.forgejo = {
    enable = true;
    database.type = "sqlite3";
    lfs.enable = true;
    settings = {
      server = {
        DOMAIN = "127.0.0.1";
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = 8929;
        DISABLE_SSH = true;
      };
      service = {
        DISABLE_REGISTRATION = true;
        REQUIRE_SIGNIN_VIEW = true;
      };
      repository.DEFAULT_PRIVATE = "private";
      actions.ENABLED = true;
    };
    dump = {
      enable = true;
      interval = "04:15";
      age = "7d";
    };
  };

  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances.forgejo = {
      enable = true;
      name = "local-linux";
      url = forge.settings.server.ROOT_URL;
      tokenFile = runnerToken;
      labels = [ "debian-bookworm:docker://docker.io/library/node:22-bookworm" ];
      settings = {
        runner.capacity = 1;
        container = {
          # Jobs need loopback access to the forge for checkout and artifacts.
          network = "host";
          docker_host = "-";
          privileged = false;
        };
      };
    };
  };

  systemd.tmpfiles.rules = [ "d /etc/forgejo-runner 0700 root root -" ];
  systemd.services.gitea-runner-forgejo = {
    after = [ "forgejo.service" ];
    unitConfig.ConditionFileNotEmpty = runnerToken;
  };
}
