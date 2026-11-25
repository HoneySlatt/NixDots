{ pkgs, ... }:

{
  # Pluto server (fork of T3 Code) for the native Pluto client. Runs alongside
  # t3code-server with its own home and port. Listens on every interface so
  # the phone app can reach it; the firewall opens the port on Wi-Fi only.
  home.packages = [ pkgs.pluto-server ];

  systemd.user.services.pluto-server = let
    # It runs AI agents: no display or sound of the owner's (agents/isolation.nix).
    isolation = import ./agents/isolation.nix { inherit pkgs; name = "pluto-server"; };
  in {
    Unit.Description = "Pluto server";

    Service = isolation // {
      # The fork inherits T3 Code's product analytics, on by default and sent to T3's PostHog
      # with an id read from ~/.codex or ~/.claude.json; nothing of Pluto's leaves on its own.
      Environment = isolation.Environment ++ [ "T3CODE_TELEMETRY_ENABLED=false" ];
      WorkingDirectory = "%h";
      ExecStart = "${pkgs.pluto-server}/bin/pluto-server serve --base-dir %h/.pluto --host 0.0.0.0 --port 3774";
      Restart = "always";
      RestartSec = 10;
    };

    Install.WantedBy = [ "default.target" ];
  };
}
