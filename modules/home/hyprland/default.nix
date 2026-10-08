{ inputs, pkgs, ... }:

let
  scrolloverview = pkgs.hyprlandPlugins.mkHyprlandPlugin {
    inherit (pkgs) hyprland;
    pluginName = "scrolloverview";
    version = inputs.scrolloverview.shortRev or "unstable";
    src = inputs.scrolloverview;
    buildInputs = [ pkgs.lua5_4 ];

    enableParallelBuilding = true;
    dontUseCmakeConfigure = true;

    buildPhase = ''
      runHook preBuild
      export SCROLLOVERVIEW_BUILD_VERSION="${inputs.scrolloverview.shortRev or "unstable"}"
      make all
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib"
      mv scrolloverview.so "$out/lib/libscrolloverview.so"
      runHook postInstall
    '';

    meta = {
      description = "Scrollable workspace overview plugin for Hyprland";
      homepage = "https://github.com/yayuuu/hyprland-scroll-overview";
      license = pkgs.lib.licenses.bsd3;
      platforms = pkgs.lib.platforms.linux;
    };
  };

  hymission = pkgs.hyprlandPlugins.mkHyprlandPlugin {
    inherit (pkgs) hyprland;
    pluginName = "hymission";
    version = "0.5.0";
    src = inputs.hymission;
    nativeBuildInputs = [ pkgs.cmake ];
    buildInputs = [ pkgs.lua5_4 ];

    cmakeFlags = [ "-DBUILD_TESTING=ON" ];
    doCheck = true;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib"
      cp libhymission.so "$out/lib/libhymission.so"
      runHook postInstall
    '';

    meta = {
      description = "Mission Control style overview plugin for Hyprland";
      homepage = "https://github.com/gfhdhytghd/hymission";
      license = pkgs.lib.licenses.gpl3Only;
      platforms = pkgs.lib.platforms.linux;
    };
  };
in
{
  imports = [
    ./packages.nix
    ./monitors.nix
    ./input.nix
    ./settings.nix
    ./overview.nix
    ./autostart.nix
    ./keybindings.nix
    ./windowrules.nix
    ../hyprlock.nix
    ./hypridle.nix
    ../quickshell
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    plugins = [ scrolloverview hymission ];
  };
}
