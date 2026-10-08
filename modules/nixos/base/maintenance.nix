{
  nix = {
    # Deduplicate the store on a schedule instead of during every build
    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Cap the systemd journal on disk
  services.journald.settings.Journal.SystemMaxUse = "500M";
}
