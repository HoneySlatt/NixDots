# Custom packages, exposed in pkgs through an overlay
inputs: final: prev:

let
  inherit (final.stdenv.hostPlatform) system;
in
{
  kimi-code = final.callPackage ./kimi-code { };
  kytyps5 = final.callPackage ./kytyps5 { };
  nuvio = final.callPackage ./nuvio { };
  nym-vpnd = final.callPackage ./nym-vpnd { };
  rootapp = final.callPackage ./rootapp { };
  rqbit-desktop = final.callPackage ./rqbit-desktop { };
  zcode = final.callPackage ./zcode { };
  pluto-server = final.callPackage "${inputs.pluto-server}/nix/package.nix" {
    src = inputs.pluto-server;
  };

  claude-desktop = inputs.claude-desktop-nix-flake.packages.${system}.default;

  kopuz = inputs.kopuz.packages.${system}.default;
  serein = inputs.serein.packages.${system}.default;
  slatty = inputs.slatty.packages.${system}.default.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [
      final.aws-lc
      final.sqlite
    ];
  });
}
