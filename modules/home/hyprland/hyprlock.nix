{ ... }:

{
  programs.hyprlock = {
    enable = true;
    extraConfig = ''
      source = /home/honey/.config/hypr/hyprlock-theme.conf

      general {
        hide_cursor = true
      }

      background {
        monitor =
        path = $HOME/.config/background
        blur_passes = 0
        color = rgb($hl_background)
      }

      image {
        monitor = DP-2
        path = /home/honey/Pictures/Others/Honey.png
        size = 100
        border_color = rgb($hl_accent)
        position = 0, 75
        halign = center
        valign = center
      }

      input-field {
        monitor = DP-2
        size = 300, 60
        outline_thickness = 4
        dots_size = 0.2
        dots_spacing = 0.2
        dots_center = true
        outer_color = rgb($hl_accent)
        inner_color = rgb($hl_surface)
        font_color = rgb($hl_text)
        fade_on_empty = false
        placeholder_text = <span foreground="##$hl_text"><i>󰌾</i><span foreground="##$hl_accent"></span></span>
        hide_input = false
        check_color = rgb($hl_accent)
        fail_color = rgb($hl_red)
        fail_text = <i>$FAIL <b>($ATTEMPTS)</b></i>
        capslock_color = rgb($hl_yellow)
        position = 0, -47
        halign = center
        valign = center
      }
    '';
  };
}
