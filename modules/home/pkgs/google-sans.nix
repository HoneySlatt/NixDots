{ lib
, stdenvNoCC
, fetchurl
, python3Packages
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

  nativeBuildInputs = [ python3Packages.fonttools ];

  # Google Sans Code ships as a variable font, which Rio cannot load: split it into static weights
  installPhase = ''
    dest="$out/share/fonts/truetype"
    for src in $srcs; do
      name="$(stripHash "$src")"
      case "$name" in
        GoogleSansCode*)
          mkdir -p "$dest"
          for weight in 300:Light 400:Regular 500:Medium 600:SemiBold 700:Bold 800:ExtraBold; do
            style="''${weight#*:}"
            case "$name" in *Italic*) style="''${style%Regular}Italic" ;; esac
            fonttools varLib.instancer --update-name-table -q \
              -o "$dest/GoogleSansCode-$style.ttf" "$src" "wght=''${weight%%:*}"
          done
          ;;
        *)
          install -Dm444 "$src" "$dest/$name"
          ;;
      esac
    done
  '';

  meta = {
    description = "Google Sans Flex and Google Sans Code fonts";
    homepage = "https://github.com/google/fonts";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
}
