{ config, ... }:

{
  programs.ghostty = {
    enable = true;
    settings = {
      font-family = "Geist Mono";
      font-size = 11;
      adjust-cell-height = "18%";

      config-file = [ "?${config.xdg.configHome}/ghostty/themes/current.conf" ];

      shell-integration = "zsh";
      confirm-close-surface = false;
      gtk-single-instance = true;
      quit-after-last-window-closed = false;

      mouse-scroll-multiplier = 0.3;

      window-decoration = true;
    };
  };

  xdg.configFile."systemd/user/graphical-session.target.wants/app-com.mitchellh.ghostty.service".source =
    "${config.programs.ghostty.package}/share/systemd/user/app-com.mitchellh.ghostty.service";
}
