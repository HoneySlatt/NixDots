# Custom packages, exposed in pkgs through an overlay
inputs: final: prev:

let
  inherit (final.stdenv.hostPlatform) system;
in
{
  kimi-code = final.callPackage ./kimi-code { };
  kimi-code-desktop = final.callPackage ./kimi-code-desktop { };
  kytyps5 = final.callPackage ./kytyps5 { };
  nuvio = final.callPackage ./nuvio { };
  nym-vpnd = final.callPackage ./nym-vpnd { };
  rqbit-desktop = final.callPackage ./rqbit-desktop { };
  zcode = final.callPackage ./zcode { };

  claude-desktop = final.callPackage ./claude-desktop {
    claudeDesktop = inputs.claude-desktop-nix-flake.packages.${system}.default;
  };
  chatgpt = final.callPackage ./chatgpt-desktop {
    chatgptDesktop = prev.chatgpt;
  };

  kopuz = inputs.kopuz.packages.${system}.default;
  serein = inputs.serein.packages.${system}.default;
  slatty = inputs.slatty.packages.${system}.default;
}
