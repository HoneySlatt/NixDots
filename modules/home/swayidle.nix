{ config, lib, pkgs, ... }:

let
  monitorsOn = "umbriel msg dpms-on";
  monitorsOff = "umbriel msg dpms-off";
in
{
  services.swayidle = {
    enable = true;
    systemdTargets = [
      "umbriel-session.target"
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
