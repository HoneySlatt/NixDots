# Custom packages, exposed in pkgs through an overlay
inputs: final: prev:

let
  inherit (final.stdenv.hostPlatform) system;
in
{
  google-sans = final.callPackage ./google-sans { };
  nuvio = final.callPackage ./nuvio { };
  nym-vpnd = final.callPackage ./nym-vpnd { };
  rqbit-desktop = final.callPackage ./rqbit-desktop { };

  claude-desktop = final.callPackage ./claude-desktop {
    claudeDesktop = inputs.claude-desktop-nix-flake.packages.${system}.default;
  };
  chatgpt-desktop = final.callPackage ./chatgpt-desktop {
    chatgptDesktop = inputs.chatgpt-desktop.packages.${system}.default;
  };
  opencode-desktop = final.callPackage ./opencode-desktop { inherit (prev) opencode-desktop; };

  kopuz = inputs.kopuz.packages.${system}.default;
  serein = inputs.serein.packages.${system}.default;
}
