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

  claude-desktop = final.callPackage ./claude-desktop {
    claudeDesktop = inputs.claude-desktop-nix-flake.packages.${system}.default;
  };
  chatgpt = final.callPackage ./chatgpt-desktop {
    chatgptDesktop = prev.chatgpt;
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
  slatty = inputs.slatty.packages.${system}.default;
}
