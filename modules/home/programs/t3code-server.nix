{ pkgs, ... }:

{
  # Always-on T3 Code server for the native client (instead of the desktop app's)
  systemd.user.services.t3code-server = {
    Unit.Description = "T3 Code server";

    Service = {
      WorkingDirectory = "%h";
      ExecStart = "${pkgs.t3code}/bin/t3 serve --base-dir %h/.t3 --host 127.0.0.1 --port 3773";
      Restart = "always";
      RestartSec = 10;
    };

    Install.WantedBy = [ "default.target" ];
  };
}
