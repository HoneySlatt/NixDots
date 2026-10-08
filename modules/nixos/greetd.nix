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

  systemd.services.greetd.serviceConfig = {
    StandardInput = "tty";
    StandardOutput = "tty";
    TTYPath = "/dev/tty1";
  };
}

