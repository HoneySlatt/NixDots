{ ... }:

{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "niri-session";
        user = "honey";
      };
    };
  };

  systemd.services.greetd.serviceConfig.StandardInput = "tty";
  systemd.services.greetd.serviceConfig.StandardOutput = "tty";
  systemd.services.greetd.serviceConfig.TTYPath = "/dev/tty1";
}

