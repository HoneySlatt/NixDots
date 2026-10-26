{ pkgs, ... }:

{
  home.packages = with pkgs; [
    libnotify
    awww
    brightnessctl
    imagemagick
    wl-clipboard
    playerctl
    hyprpicker
    wlsunset
  ];
}
