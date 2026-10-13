let
  # Whichever compositor runs the session answers, the other command fails
  monitorsOn = "niri msg action power-on-monitors || hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'";
  monitorsOff = "niri msg action power-off-monitors || hyprctl dispatch 'hl.dsp.dpms({ action = \"disable\" })'";
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
