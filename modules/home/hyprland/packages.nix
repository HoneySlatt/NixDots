{ pkgs, ... }:

{
  home.packages = with pkgs; [
    quickshell
    libnotify
    awww
    grim
    swaynotificationcenter
    brightnessctl
    imagemagick
    wf-recorder
    wl-clipboard
    hyprpolkitagent
    hyprpicker
    wlsunset
    playerctl
    swayosd
    (writeShellApplication {
      name = "hyprquickshot-toggle";
      runtimeInputs = [ quickshell procps coreutils ];
      text = ''
        if pgrep -x wf-recorder > /dev/null; then
          pkill --signal SIGINT wf-recorder
        else
          quickshell -c hyprquickshot -n
        fi
      '';
    })
  ];
}
