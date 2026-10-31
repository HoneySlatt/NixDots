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
    umbriel.url = "github:noctalia-dev/umbriel/cachix";
    noctalia.url = "github:noctalia-dev/noctalia/cachix";
    claude-desktop-nix-flake = {
      url = "github:poeck/claude-desktop-nix-flake";
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
      # Keep the local patches compatible; rebase them before updating Amane.
      url = "github:MystiaFin/amane/7cf5fac4a98a13ca7098766b9118806073f57952";
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
    slatty = {
      url = "github:HoneySlatt/Slatty";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pluto server: local fork of T3 Code (see ~/Projects/pluto-server/PLUTO.md)
    pluto-server = {
      url = "git+file:///home/honey/Projects/pluto-server?ref=pluto";
      flake = false;
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
      packages.x86_64-linux.kimi-code = (nixpkgs.legacyPackages.x86_64-linux.extend (import ./pkgs inputs)).kimi-code;
      packages.x86_64-linux.kimi-code-desktop = (nixpkgs.legacyPackages.x86_64-linux.extend (import ./pkgs inputs)).kimi-code-desktop;
      packages.x86_64-linux.kytyps5 = (nixpkgs.legacyPackages.x86_64-linux.extend (import ./pkgs inputs)).kytyps5;
      packages.x86_64-linux.nym-vpnd = (nixpkgs.legacyPackages.x86_64-linux.extend (import ./pkgs inputs)).nym-vpnd;
      packages.x86_64-linux.zcode = (nixpkgs.legacyPackages.x86_64-linux.extend (import ./pkgs inputs)).zcode;

      nixosConfigurations = {
        desktop = mkHost "desktop";
        steamdeck = mkHost "steamdeck";
      };
    };
}
