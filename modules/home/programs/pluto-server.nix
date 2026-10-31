{ pkgs, ... }:

{
  # Pluto server (fork of T3 Code) for the native Pluto client. Runs alongside
  # t3code-server with its own home and port. Listens on every interface so
  # the phone app can reach it; the firewall opens the port on Wi-Fi only.
  home.packages = [ pkgs.pluto-server ];

  systemd.user.services.pluto-server = {
    Unit.Description = "Pluto server";

    Service = {
      WorkingDirectory = "%h";
      ExecStart = "${pkgs.pluto-server}/bin/pluto-server serve --base-dir %h/.pluto --host 0.0.0.0 --port 3774";
      Restart = "always";
      RestartSec = 10;
    };

    Install.WantedBy = [ "default.target" ];
  };
}
