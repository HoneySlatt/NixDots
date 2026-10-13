# Custom packages, exposed in pkgs through an overlay
inputs: final: prev:

let
  inherit (final.stdenv.hostPlatform) system;
in
{
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

  # Rio picks the variable Geist Mono for regular and italic and fails to load it;
  # the static files cover every weight
  geist-font = prev.geist-font.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      rm $out/share/fonts/truetype/GeistMono*\[wght\].ttf
    '';
  });

  kopuz = inputs.kopuz.packages.${system}.default;
  serein = inputs.serein.packages.${system}.default;
}
