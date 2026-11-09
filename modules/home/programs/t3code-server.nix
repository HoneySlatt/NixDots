{ pkgs, ... }:

{
  # Always-on T3 Code server for the native client (instead of the desktop app's)
  systemd.user.services.t3code-server = {
    Unit.Description = "T3 Code server";

    # It runs AI agents: no display or sound of the owner's (agents/isolation.nix).
    Service = import ./agents/isolation.nix { inherit pkgs; name = "t3code-server"; } // {
      WorkingDirectory = "%h";
      ExecStart = "${pkgs.t3code}/bin/t3 serve --base-dir %h/.t3 --host 127.0.0.1 --port 3773";
      Restart = "always";
      RestartSec = 10;
    };

    Install.WantedBy = [ "default.target" ];
  };
}
