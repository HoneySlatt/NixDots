let
  # Whichever compositor runs the session answers, the other command fails;
  # mango powers one monitor per call
  mangoMonitors = action: "mmsg get all-monitors | jq -r '.monitors[].name' | xargs -I{} mmsg dispatch ${action}_monitor,{}";
  monitorsOn = "niri msg action power-on-monitors || ${mangoMonitors "wakeup"}";
  monitorsOff = "niri msg action power-off-monitors || ${mangoMonitors "sleep"}";
in
{
  services.hypridle = {
    enable = true;

    settings = {
      general = {
        lock_cmd = "lock-screen";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = monitorsOn;
      };

      listener = [
        {
          timeout = 150;
          on-timeout = "brightnessctl -s set 10%";
          on-resume = "brightnessctl -r";
        }
        {
          timeout = 300;
          on-timeout = monitorsOff;
          on-resume = "(${monitorsOn}) && brightnessctl -r";
        }
      ];
    };
  };
}
