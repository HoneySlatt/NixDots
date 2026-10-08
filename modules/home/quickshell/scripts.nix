{ lib, pkgs, ... }:

let
  # Script name -> IpcHandler target in material/shell.qml (amane handles the script name itself)
  ipcToggles = {
    toggle-bar-position = "togglePosition";
    toggle-launcher = "toggleLauncher";
    toggle-theme-launcher = "toggleThemeLauncher";
    toggle-wallpaper-launcher = "toggleWallpaperLauncher";
    toggle-game-launcher = "toggleSteamLauncher";
    toggle-music-launcher = "toggleMusicLauncher";
    toggle-vpn-launcher = "toggleVpnLauncher";
    toggle-power-launcher = "togglePowerMenu";
  };

  # Script whose body lives in ./bin/<name>.sh
  fromFile = name: args: pkgs.writeShellApplication ({
    inherit name;
    text = builtins.readFile ./bin/${name}.sh;
  } // args);
in
{
  home.packages =
    lib.mapAttrsToList (name: target: pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [ pkgs.procps ];
      # Goes to the amane shell while it runs, to Quickshell otherwise
      text = ''
        if pgrep -x amane-shell >/dev/null && command -v amane >/dev/null; then
          exec amane ipc call ${name}
        fi
        quickshell ipc -c material call ${target} call
      '';
    }) ipcToggles
    ++ [ (fromFile "start-quickshell" { }) ];
}
