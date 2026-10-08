# Shared by every host
{
  imports = [
    ./nix.nix
    ./maintenance.nix
    ./locale.nix
    ./networking.nix
    ./users.nix
    ./hardening.nix
    ./privacy.nix
  ];
}
