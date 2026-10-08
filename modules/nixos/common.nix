{ inputs, pkgs, ... }:

{
  nix = {
    settings.experimental-features = [ "nix-command" "flakes" ];
    # Deduplicate the store on a schedule instead of during every build
    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [ (import ../../pkgs inputs) ];

  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "cf";

  networking.networkmanager = {
    enable = true;
    # Random MAC per Wi-Fi network (stable for each one), random per Ethernet profile
    wifi.macAddress = "stable-ssid";
    ethernet.macAddress = "stable";
    # Keep the hostname out of DHCP requests on every network
    settings.connection = {
      "ipv4.dhcp-send-hostname" = false;
      "ipv6.dhcp-send-hostname" = false;
    };
  };

  users.users.honey = {
    isNormalUser = true;
    description = "Honey";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "jackaudio" ];
    shell = pkgs.zsh;
  };

  programs.nano.enable = false;
  programs.zsh.enable = true;
  programs.dconf.enable = true;

  environment.variables = {
    EDITOR = "nvim";
    BROWSER = "brave-origin";
  };

  # Telemetry opt-outs read by CLI tools (gh, and any tool honouring DO_NOT_TRACK)
  environment.sessionVariables = {
    DO_NOT_TRACK = "1";
    GH_TELEMETRY = "0";
  };

  # Applies to every Claude Code launch, terminal or Claude Desktop: no telemetry,
  # error reporting, bug reports or update checks
  environment.etc."claude-code/managed-settings.json".text = builtins.toJSON {
    env.CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
  };
}
