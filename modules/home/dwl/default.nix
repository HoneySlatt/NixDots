{ config, lib, pkgs, ... }:

# Minimal third session beside niri and mango: dwl with its default bindings and dwm's bar,
# configured at build time by ./config.h (dwl's config.def.h with the screens, the
# keyboard, the mouse and the terminal of the other sessions)

let
  dwl = (pkgs.dwl.override { configH = ./config.h; }).overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      # dwm's bar, from dwl-patches (patches/bar), rebased onto dwl 0.9
      ./bar.patch
    ];
    buildInputs = old.buildInputs ++ [
      pkgs.fcft
      pkgs.libdrm
    ];
  });
in
{
  # The session entry (modules/nixos/desktop/dwl.nix) runs this build
  home.packages = [
    dwl
    # Launcher of the default Mod+P binding
    pkgs.wmenu
  ];

  # dwl's monitor rules take no mode, and it picks the preferred one; started once dwl has
  # handed the session environment to systemd
  systemd.user.services.dwl-autostart = {
    Unit = {
      Description = "Monitor modes and login screen preselection for dwl";
      PartOf = [ "dwl-session.target" ];
      After = [ "dwl-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = [
        # Preselected on the login screen next time (modules/home/amane/greeter.nix)
        "${config.home.profileDirectory}/bin/remember-session dwl"
        "${lib.getExe pkgs.wlr-randr} --output DP-2 --mode 3840x2160@240.016Hz --output DP-3 --mode 1920x1080@179.999Hz"
      ];
    };
    Install.WantedBy = [ "dwl-session.target" ];
  };
}
