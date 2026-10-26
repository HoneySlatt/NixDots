{ pkgs, ... }:

let
  navidromeLyricsPlugin = pkgs.stdenvNoCC.mkDerivation {
    pname = "nd-lyrics";
    version = "6.1.3";

    src = pkgs.fetchurl {
      url = "https://github.com/J0R6IT0/navidrome-lyrics-plugin/releases/download/v6.1.3/nd-lyrics.ndp";
      hash = "sha256-U54KfULuMBDkJYzn4nuV8oKdaqJU20MMhnDv43rB9dY=";
    };

    dontUnpack = true;

    installPhase = ''
      install -Dm644 $src $out/share/plugins/$pname.ndp
    '';

    passthru.isNavidromePlugin = true;
  };
in
{
  services.navidrome = {
    enable = true;
    openFirewall = true;
    withPlugins = _: [ navidromeLyricsPlugin ];
    settings = {
      Address = "0.0.0.0";
      MusicFolder = "/NAS/Music";
      DataFolder = "/NAS/Navidrome";
      ScanSchedule = "@hourly";
      LyricsPriority = ".lrc,nd-lyrics,.txt,embedded";
    };
  };

  systemd.tmpfiles.rules = [
    "d /NAS/Navidrome 0755 navidrome navidrome -"
  ];
}
