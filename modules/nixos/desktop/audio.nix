{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    jack.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    # Let the graph follow the source's rate instead of resampling everything to
    # 48 kHz (the Scarlett 2i2 runs 44.1 to 192 kHz natively).
    extraConfig.pipewire."92-sample-rates"."context.properties"."default.clock.allowed-rates" = [
      44100
      48000
      88200
      96000
      176400
      192000
    ];
  };
}

