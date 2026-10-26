{ lib
, stdenv
, clangStdenv
, fetchFromGitHub
, fetchurl
, cmake
, ninja
, pkg-config
, python3
, glslang
, lld
, unzip
, makeWrapper
, makeDesktopItem
, copyDesktopItems
, autoPatchelfHook
, bash
, qt6
, alsa-lib
, libpulseaudio
, systemd
, dbus
, libglvnd
, libX11
, libXcursor
, libXext
, libXfixes
, libXi
, libXrandr
, libXScrnSaver
, libXtst
, libxkbcommon
, wayland
, wayland-protocols
, libdecor
, vulkan-loader
}:

let
  sources = import ./sources.nix { inherit fetchFromGitHub fetchurl; };
  runtimeLibraries = [
    alsa-lib libpulseaudio systemd dbus libglvnd
    libX11 libXcursor libXext libXfixes libXi libXrandr libXScrnSaver libXtst
    libxkbcommon wayland libdecor vulkan-loader
  ];
in
clangStdenv.mkDerivation rec {
  pname = "kytyps5";
  version = "0-unstable-2026-10-22";

  src = fetchFromGitHub {
    owner = "KytyPS5";
    repo = "KytyPS5";
    rev = "79837b423dd035b34b2dc476e1d2dce8ae0d18bf";
    fetchSubmodules = true;
    hash = "sha256-tBB9l8s8Ayt3iK7pjIHP21/S421e7Zw4qrz2B3Ratio=";
  };

  nativeBuildInputs = [
    cmake ninja pkg-config python3 glslang lld unzip
    makeWrapper copyDesktopItems autoPatchelfHook qt6.wrapQtAppsHook
  ];
  buildInputs = runtimeLibraries ++ [ stdenv.cc.cc.lib qt6.qtbase qt6.qtsvg qt6.qtwayland wayland-protocols ];

  # SDL probes these optional libraries; neither is a linked dependency.
  autoPatchelfIgnoreMissingDeps = [ "libGLES_CM.so.1" "libsteam_api.so" ];

  patches = [ ./writable-runtime.patch ];

  postPatch = ''
    substituteInPlace src/kytyGitVersion.h.in \
      --replace-fail '@KYTY_GIT_VERSION@' '${version}' \
      --replace-fail '@KYTY_GIT_HASH@' '${builtins.substring 0 7 src.rev}' \
      --replace-fail '@KYTY_GIT_REVISION@' '${src.rev}'

    # FETCHCONTENT_SOURCE_DIR skips upstream's PATCH_COMMAND.
    cp -r ${sources.zarchive} zarchive
    chmod -R u+w zarchive
    sed -i 's/\r$//' zarchive/include/zarchive/zarchivecommon.h zarchive/src/zarchivereader.cpp
    patch -d zarchive -p1 < 3rdparty/patches/zarchive-reader.patch

    # Use the matching upstream FFmpeg build, without a configure-time download.
    unzip -q ${sources.ffmpeg} -d ffmpeg
  '';

  preConfigure = ''
    cmakeFlagsArray+=("-DFETCHCONTENT_SOURCE_DIR_ZARCHIVE_SOURCE=$PWD/zarchive")
    cmakeFlagsArray+=("-DFFMPEG_PREBUILT_DIR=$PWD/ffmpeg")
  '';

  cmakeFlags = [
    "-DBUILD_TESTING=OFF"
    "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
    "-DFETCHCONTENT_SOURCE_DIR_OPUS=${sources.opus}"
    "-DFETCHCONTENT_SOURCE_DIR_OPENXR=${sources.openxr}"
    "-DFETCHCONTENT_SOURCE_DIR_XBYAK=${sources.xbyak}"
    "-DFETCHCONTENT_SOURCE_DIR_ZYDIS=${sources.zydis}"
    "-DFETCHCONTENT_SOURCE_DIR_ZSTD=${sources.zstd}"
    "-DSDL_ALSA=ON"
    "-DSDL_PULSEAUDIO=ON"
    "-DSDL_WAYLAND=ON"
    "-DSDL_X11=ON"
    "-DSDL_HIDAPI=ON"
  ];
  ninjaFlags = [ "launcher" ];

  # Keep helpers beside the launcher, without upstream's bundled Qt libraries.
  dontWrapQtApps = true;
  installPhase = ''
    runHook preInstall
    install -Dm755 kyty_emulator "$out/libexec/kytyps5/kyty_emulator"
    install -Dm755 launcher/kyty_launcher "$out/libexec/kytyps5/kyty_launcher"
    install -Dm755 launcher/kyty_updater "$out/libexec/kytyps5/kyty_updater"
    cp -r ../assets "$out/libexec/kytyps5/assets"
    install -Dm644 ../src/launcher/icons/kyty.svg \
      "$out/share/icons/hicolor/scalable/apps/kytyps5.svg"
    mkdir -p "$out/share/licenses/kytyps5"
    cp -r ../LICENSE ../LICENSES ../ffmpeg/share/ffmpeg "$out/share/licenses/kytyps5/"

    wrapProgram "$out/libexec/kytyps5/kyty_emulator" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibraries}"
    wrapProgramShell "$out/libexec/kytyps5/kyty_launcher" "''${qtWrapperArgs[@]}" \
      --prefix PATH : "${lib.makeBinPath [ bash ]}" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibraries}" \
      --run 'mkdir -p "''${XDG_DATA_HOME:-$HOME/.local/share}/kytyps5" && cd "''${XDG_DATA_HOME:-$HOME/.local/share}/kytyps5"'
    mkdir -p "$out/bin"
    ln -s "$out/libexec/kytyps5/kyty_launcher" "$out/bin/kytyps5"
    ln -s "$out/libexec/kytyps5/kyty_emulator" "$out/bin/kyty_emulator"
    runHook postInstall
  '';

  desktopItems = [ (makeDesktopItem {
    name = "kytyps5";
    desktopName = "KytyPS5";
    comment = "PlayStation 5 translation layer";
    exec = "kytyps5";
    icon = "kytyps5";
    categories = [ "Game" "Emulator" ];
  }) ];

  meta = with lib; {
    description = "PlayStation 5 translation layer";
    homepage = "https://github.com/KytyPS5/KytyPS5";
    license = licenses.gpl2Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "kytyps5";
    sourceProvenance = with sourceTypes; [ fromSource binaryNativeCode ];
  };
}
