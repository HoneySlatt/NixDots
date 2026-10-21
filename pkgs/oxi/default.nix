{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeWrapper
, copyDesktopItems
, makeDesktopItem
, writeShellScript
, jq
, alsa-lib
, dbus
, gtk3
, openssl
, libGL
, libxkbcommon
, vulkan-loader
, wayland
, xorg
}:

let
  initTheme = writeShellScript "oxi-init-theme" ''
    settings_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/oxi"
    [ -f "$settings_dir/themes/amane.json" ] || exit 0
    settings="$settings_dir/settings.json"
    settings_tmp="$(mktemp "$settings.XXXXXX")" || exit 0
    if [ -f "$settings" ]; then
      # Preserve other settings and leave legacy/malformed configurations to Oxi.
      ${jq}/bin/jq -e 'if type == "object" and has("providers") then .theme_id = "custom:amane" else error("unsupported settings") end' \
        "$settings" > "$settings_tmp" 2>/dev/null || { rm -f "$settings_tmp"; exit 0; }
    else
      printf '%s\n' '{"providers":{},"theme_id":"custom:amane"}' > "$settings_tmp"
    fi
    mv "$settings_tmp" "$settings"
  '';
in
stdenv.mkDerivation rec {
  pname = "oxi";
  version = "1.21.0";

  src = fetchurl {
    url = "https://github.com/maziluiosif/oxi/releases/download/v${version}/oxi-linux-x86_64.tar.gz";
    hash = "sha256-FmnBnts3G3VGW9stB7F3M8hAjfeS6fUkD22ay6Z1L2A=";
  };

  icon = fetchurl {
    url = "https://raw.githubusercontent.com/maziluiosif/oxi/9717ef0ad14b152186b002c79d178e32550b427f/assets/windows/app-icon-256.png";
    hash = "sha256-iXuig1hvq1LQQYI7oJmS7kjEhVmLMVdhAOpMFJF0xeI=";
  };

  sourceRoot = ".";
  dontBuild = true;
  strictDeps = true;

  nativeBuildInputs = [ autoPatchelfHook makeWrapper copyDesktopItems ];
  buildInputs = [ alsa-lib dbus gtk3 openssl stdenv.cc.cc.lib xorg.libxcb ];

  # rfd loads D-Bus dynamically; winit and wgpu do the same for graphics libraries.
  runtimeDependencies = map lib.getLib [
    dbus
    libGL
    libxkbcommon
    vulkan-loader
    wayland
    xorg.libX11
    xorg.libXcursor
    xorg.libXi
    xorg.libXrandr
  ];

  desktopItems = [ (makeDesktopItem {
    name = "oxi";
    desktopName = "oxi";
    comment = "Coding agents and local models in one workspace";
    exec = "oxi";
    icon = "oxi";
    terminal = false;
    categories = [ "Development" "IDE" ];
  }) ];

  installPhase = ''
    runHook preInstall
    install -Dm755 oxi "$out/libexec/oxi"
    install -Dm644 "$icon" "$out/share/icons/hicolor/256x256/apps/oxi.png"
    makeWrapper "$out/libexec/oxi" "$out/bin/oxi" \
      --run 'if [ "''${1-}" = update ]; then echo "oxi is managed by Nix; update its package instead." >&2; exit 1; fi' \
      --run ${lib.escapeShellArg (toString initTheme)}
    runHook postInstall
  '';

  meta = with lib; {
    description = "Native coding agent workspace with ACP and local model support";
    homepage = "https://github.com/maziluiosif/oxi";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "oxi";
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
  };
}
