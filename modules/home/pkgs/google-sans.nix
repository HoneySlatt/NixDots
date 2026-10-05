{ lib
, stdenvNoCC
, fetchurl
}:

# Google Sans Flex (Material 3 Expressive UI font) and Google Sans Code,
# taken from google/fonts until nixpkgs' google-fonts catches up.
let
  rev = "a0e3dbcdc3a3ecfafff3f071159ae0221628922d";
  font = name: path: hash: fetchurl {
    inherit name hash;
    url = "https://raw.githubusercontent.com/google/fonts/${rev}/ofl/${path}";
  };
in
stdenvNoCC.mkDerivation {
  pname = "google-sans";
  version = "0-unstable-2026-09-04";

  srcs = [
    (font "GoogleSansFlex.ttf" "googlesansflex/GoogleSansFlex%5BGRAD%2CROND%2Copsz%2Cslnt%2Cwdth%2Cwght%5D.ttf"
      "sha256-wxpIL77L8uB+aJATTSAHhyOq33Msm5xsmkT4b4Jltv4=")
    (font "GoogleSansCode.ttf" "googlesanscode/GoogleSansCode%5Bwght%5D.ttf"
      "sha256-yWSVc6/Nlm9hCWsenDwxFee1QxXKKt+YOcb4sX1fjh8=")
    (font "GoogleSansCode-Italic.ttf" "googlesanscode/GoogleSansCode-Italic%5Bwght%5D.ttf"
      "sha256-vfEWKS8nrKFuKu+1U0BCol8kTTqRh6Uhzpf8IRekqEQ=")
  ];

  dontUnpack = true;

  installPhase = ''
    for src in $srcs; do
      install -Dm444 "$src" "$out/share/fonts/truetype/$(stripHash "$src")"
    done
  '';

  meta = {
    description = "Google Sans Flex and Google Sans Code fonts";
    homepage = "https://github.com/google/fonts";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
}
