{ config, lib, pkgs, ... }:

let
  /*
   * mango powers one monitor per call, and lights again a monitor that reconnects
   * while asleep (as DP-3 does after a few minutes without signal), so "off" also keeps
   * putting lit monitors back to sleep until "on"; the kernel says which ones are lit
   */
  mangoMonitors = pkgs.writeShellApplication {
    name = "mango-monitors";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      flag="''${XDG_RUNTIME_DIR:-/tmp}/mango-monitors-off"

      names() {
        mmsg get all-monitors | jq -r '.monitors[].name'
      }

      sleep_lit() {
        for name in $(names); do
          for state in /sys/class/drm/card*-"$name"/enabled; do
            if [ -r "$state" ] && [ "$(< "$state")" = enabled ]; then
              mmsg dispatch "sleep_monitor,$name" > /dev/null
            fi
          done
        done
      }

      # Fails outside mango, for the next command
      mmsg get all-monitors > /dev/null

      case "''${1:-}" in
        off)
          touch "$flag"
          sleep_lit
          # every change of monitors is an event; the first one after "on" ends the watch
          mmsg watch all-monitors | while read -r _; do
            [ -e "$flag" ] || break
            sleep_lit
          done &
          ;;
        on)
          rm -f "$flag"
          for name in $(names); do
            mmsg dispatch "wakeup_monitor,$name" > /dev/null
          done
          ;;
      esac
    '';
  };

  # Whichever compositor runs the session answers, the others fail; dwl is left to wlopm
  monitorsOn = "niri msg action power-on-monitors || ${mangoMonitors}/bin/mango-monitors on || ${lib.getExe pkgs.wlopm} --on '*'";
  monitorsOff = "niri msg action power-off-monitors || ${mangoMonitors}/bin/mango-monitors off || ${lib.getExe pkgs.wlopm} --off '*'";
in
{
  services.swayidle = {
    enable = true;

    events = {
      before-sleep = "loginctl lock-session";
      lock = "lock-screen";
      after-resume = monitorsOn;
    };

    timeouts = [
      {
        timeout = 150;
        command = "brightnessctl -s set 10%";
        resumeCommand = "brightnessctl -r";
      }
      {
        timeout = 300;
        command = monitorsOff;
        resumeCommand = "(${monitorsOn}) && brightnessctl -r";
      }
    ];
  };

  # The module's service only finds bash; the commands above come from the profiles
  systemd.user.services.swayidle.Service.Environment = lib.mkForce [
    "PATH=${lib.makeBinPath [ pkgs.bash ]}:${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
  ];
}
