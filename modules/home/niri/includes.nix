{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.programs.niri;
  niriDir = "${config.xdg.configHome}/niri";
in
{
  # Raw KDL for what niri-flake settings cannot express.
  xdg.configFile.niri-config.source = lib.mkForce (
    inputs.niri.lib.internal.validated-config-for pkgs cfg.package (
      cfg.finalConfig
      + ''

        window-rule {
            open-maximized-to-edges false
        }

        include optional=true "${niriDir}/theme.kdl"
        include optional=true "${niriDir}/bar-mode.kdl"
      ''
    )
  );
}
