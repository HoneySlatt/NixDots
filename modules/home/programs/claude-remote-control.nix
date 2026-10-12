{ lib, pkgs, ... }:

let
  # One server per project: spawned sessions start in the server's directory
  projects = {
    slattylauncher = "Projects/SlattyLauncher";
    slimeengine = "Projects/SlimeEngine";
  };
in
{
  # Always-on servers so sessions can be started from the Claude mobile app
  systemd.user.services = lib.mapAttrs'
    (name: dir: lib.nameValuePair "claude-remote-control-${name}" {
      Unit.Description = "Claude Code Remote Control server (${name})";

      Service = {
        WorkingDirectory = "%h/${dir}";
        ExecStart = "${pkgs.claude-code}/bin/claude remote-control --name ${name}";
        Restart = "always";
        RestartSec = 10;
      };

      Install.WantedBy = [ "default.target" ];
    })
    projects;
}
