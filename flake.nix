{
  description = "Honey NixOS Config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-desktop-nix-flake = {
      url = "github:poeck/claude-desktop-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    chatgpt-desktop = {
      url = "github:stslex/chatgpt-desktop-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    millennium = {
      url = "github:SteamClientHomebrew/Millennium?dir=packages/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    amane = {
      url = "github:MystiaFin/amane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    kopuz = {
      url = "github:Kopuz-org/kopuz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    serein = {
      url = "github:ViceVerse-cz/Serein";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }@inputs:
    let
      mkHost = host: nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/${host}
          inputs.niri.nixosModules.niri
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupCommand = ''rm -f "$1"'';
              sharedModules = [ inputs.nixvim.homeModules.nixvim ];
              extraSpecialArgs = { inherit inputs; };
              users.honey = import ./hosts/${host}/home.nix;
            };
          }
        ];
      };
    in
    {
      packages.x86_64-linux.nym-vpnd = (nixpkgs.legacyPackages.x86_64-linux.extend (import ./pkgs inputs)).nym-vpnd;

      nixosConfigurations = {
        desktop = mkHost "desktop";
        steamdeck = mkHost "steamdeck";
      };
    };
}
