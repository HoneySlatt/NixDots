{ inputs, ... }:

{
  imports = [
    inputs.noctalia.homeModules.default
    ./settings.nix
    ./integration.nix
  ];

  programs.noctalia.enable = true;
}
