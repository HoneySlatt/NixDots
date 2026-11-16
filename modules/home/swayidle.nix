{ config, lib, pkgs, ... }:

let
  monitorsOn = "niri msg action power-on-monitors";
  monitorsOff = "niri msg action power-off-monitors";
in
{
  services.swayidle = {
    enable = true;
    systemdTargets = [
      "niri.service"
    ];

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
