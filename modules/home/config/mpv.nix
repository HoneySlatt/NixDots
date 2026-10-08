{ pkgs, ... }:

{
  programs.mpv = {
    enable = true;

    config = {
      vo              = "gpu-next";
      gpu-api         = "vulkan";
      gpu-context     = "waylandvk";
      hwdec           = "vaapi-copy";
      video-sync      = "display-resample";
      swapchain-depth = 1;

      save-position-on-quit = "yes";
      keep-open             = "yes";
      cursor-autohide       = 1000;

      # Required when using a custom OSC script
      osc = "no";

      # Keep mpv output SDR; HDR sources are tone-mapped instead of triggering HDR.
      target-colorspace-hint      = "no";
      target-trc                  = "srgb";
      target-prim                 = "bt.709";
      tone-mapping                = "bt.2446a";
      hdr-compute-peak            = "yes";
      gamut-mapping-mode          = "perceptual";

      scale               = "ewa_lanczossharp";
      cscale              = "spline36";
      dscale              = "mitchell";
      scale-antiring      = 0.6;
      cscale-antiring     = 0.6;
      dscale-antiring     = 0.6;
      sigmoid-upscaling   = "yes";
      correct-downscaling = "yes";
      linear-downscaling  = "yes";
      linear-upscaling    = "yes";
      dither              = "fruit";
      dither-depth        = "auto";
      deband              = "yes";
      deband-iterations   = 1;
      deband-threshold    = 32;
      deband-range        = 16;
      deband-grain        = 24;
    };

    bindings = {
      "-" = "add volume -2";
      "=" = "add volume 2";
    };

    scripts = with pkgs.mpvScripts; [
      modernz
      thumbfast
    ];

    scriptOpts = {
      modernz = {
        layout          = "modern-compact";
        icon_theme      = "fluent";
        icon_style      = "mixed";
        scalewindowed   = "0.5";
        scalefullscreen = "0.5";

        osc_color                  = "#000000";
        seekbarfg_color            = "#FFFFFF";
        seekbarbg_color            = "#666666";
        seek_handle_color          = "#FFFFFF";
        seek_handle_border_color   = "#FFFFFF";
        title_color                = "#FFFFFF";
        time_color                 = "#FFFFFF";
        side_buttons_color         = "#FFFFFF";
        middle_buttons_color       = "#FFFFFF";
        playpause_color            = "#FFFFFF";
        hover_effect_color         = "#FFFFFF";
        nibble_color               = "#FFFFFF";
        nibble_current_color       = "#FFFFFF";
        window_title_color         = "#FFFFFF";
        window_controls_color      = "#FFFFFF";
        cache_info_color           = "#FFFFFF";
        chapter_title_color        = "#FFFFFF";
        seekbar_cache_color        = "#555555";
        thumbnail_box_outline      = "#888888";
        volumebar_match_seek_color = true;
        osc_fade_strength          = 100;
      };
      thumbfast = {
        network = "yes";
        hwdec   = "yes";
      };
    };
  };
}
