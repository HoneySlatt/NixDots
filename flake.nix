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
    millennium.url = "github:SteamClientHomebrew/Millennium?dir=packages/nix";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    scrolloverview = {
      url = "github:yayuuu/hyprland-scroll-overview";
      flake = false;
    };
    hymission = {
      url = "github:gfhdhytghd/hymission/v0.5.0-v0.56.0";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    packages.x86_64-linux.nym-vpnd = nixpkgs.legacyPackages.x86_64-linux.callPackage ./modules/home/pkgs/nym-vpnd.nix { };

    nixosConfigurations = {

      desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/desktop
          inputs.niri.nixosModules.niri
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupCommand = ''rm -f "$1"'';
            home-manager.sharedModules = [ inputs.nixvim.homeModules.nixvim ];
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.honey = import ./modules/home/desktop.nix;
          }
        ];
      };

      laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/laptop
          inputs.niri.nixosModules.niri
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupCommand = ''rm -f "$1"'';
            home-manager.sharedModules = [ inputs.nixvim.homeModules.nixvim ];
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.honey = import ./modules/home/laptop.nix;
          }
        ];
      };

      steamdeck = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/steamdeck
          inputs.niri.nixosModules.niri
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupCommand = ''rm -f "$1"'';
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.honey = import ./modules/home/deck.nix;
          }
        ];
      };
    };
  };
}
