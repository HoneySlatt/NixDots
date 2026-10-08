# The login screen, built inside the patched amane source tree: its example crate is
# already a workspace member pinned by Cargo.lock, so the greeter takes its place
{ amane, lib, vulkan-loader, wayland }:

let
  # Theme, login card, Material 3 components and animations shared with the shell
  shared = [ "anim" "icons" "login_screen" "m3" "theme" ];
in
amane.overrideAttrs (old: {
  pname = "amane-greeter";

  postPatch = (old.postPatch or "") + ''
    example=cli/template/example/src
    rm -r $example
    mkdir $example
    cp ${./src}/*.rs $example/
    ${lib.concatMapStrings (name: ''
      cp ${../../../home/amane/config/src/${name}.rs} $example/${name}.rs
    '') shared}
  '';

  cargoBuildFlags = [ "-p" "amane-example" ];

  postInstall = ''
    mv $out/bin/amane-example $out/bin/amane-greeter
  '';

  # vulkan and wayland are loaded at runtime
  postFixup = ''
    wrapProgram $out/bin/amane-greeter \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ vulkan-loader wayland ]}
  '';
})
