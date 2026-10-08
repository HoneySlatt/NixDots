# Custom packages, exposed in pkgs through an overlay
inputs: final: prev:

let
  inherit (final.stdenv.hostPlatform) system;
in
{
  google-sans = final.callPackage ./google-sans.nix { };
  nuvio = final.callPackage ./nuvio.nix { };
  nym-vpnd = final.callPackage ./nym-vpnd.nix { };
  steam-metadata-editor = final.callPackage ./steam-metadata-editor.nix { };

  claude-desktop = final.callPackage ./claude-desktop.nix {
    claudeDesktop = inputs.claude-desktop-nix-flake.packages.${system}.default;
  };
  chatgpt-desktop = final.callPackage ./chatgpt-desktop.nix {
    chatgptDesktop = inputs.chatgpt-desktop.packages.${system}.default;
  };
  opencode-desktop = final.callPackage ./opencode-desktop.nix { inherit (prev) opencode-desktop; };
}
