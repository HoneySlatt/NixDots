{ inputs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs = {
    config.allowUnfree = true;
    overlays = [ (import ../../../pkgs inputs) ];
  };
}
