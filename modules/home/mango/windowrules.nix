{
  # The same rules as on niri (modules/home/niri/windowrules.nix)
  wayland.windowManager.mango.settings.window_rule = [
    "is_floating:1,app_id:^xdg-desktop-portal$"
    "is_floating:1,width:1500,height:750,app_id:^org.pulseaudio.pavucontrol$"
    "is_fullscreen:1,app_id:^mpv$"
    "is_floating:1,app_id:^org\\.prismlauncher\\.PrismLauncher$"
  ];
}
