{ pkgs, ... }:

{
  home.packages = with pkgs; [
    libnotify
    awww
    brightnessctl
    imagemagick
    wf-recorder
    wl-clipboard
    playerctl
    hyprpicker
    wlsunset
    swayosd
  ];
}
