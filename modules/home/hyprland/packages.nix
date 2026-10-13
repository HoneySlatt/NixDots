{ pkgs, ... }:

{
  home.packages = with pkgs; [
    libnotify
    awww
    grim
    brightnessctl
    imagemagick
    wf-recorder
    wl-clipboard
    hyprpolkitagent
    hyprpicker
    wlsunset
    playerctl
  ];
}
