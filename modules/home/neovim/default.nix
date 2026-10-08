{ inputs, ... }:

{
  imports = [
    ./options.nix
    ./keymaps.nix
    ./autocommands.nix
    ./plugins
  ];

  programs.nixvim = {
    enable = true;
    nixpkgs = {
      source = inputs.nixpkgs;
      config.allowUnfree = true;
    };
  };
}
