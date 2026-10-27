{ config, lib, ... }:

# Launch bindings taken from niri's (modules/home/niri/keybindings.nix); window and workspace
# bindings from the former Hyprland session (git 1a7691a, dwindle mode), plus Mod+Shift+F fullscreen

let
  inherit (lib) concatStringsSep escapeShellArgs filterAttrs init last mapAttrsToList splitString stringLength toLower;

  modifiers = {
    Mod = "SUPER";
    Shift = "SHIFT";
    Ctrl = "CTRL";
    Alt = "ALT";
  };

  # "Mod+Shift+E" -> "SUPER+SHIFT,e"; mango binds by keycode, so letters are lowercase
  key =
    combo:
    let
      parts = splitString "+" combo;
      name = last parts;
      mods = map (mod: modifiers.${mod}) (init parts);
    in
    "${if mods == [ ] then "NONE" else concatStringsSep "+" mods},${if stringLength name == 1 then toLower name else name}";

  command = spawn: if builtins.isList spawn then escapeShellArgs spawn else spawn;

  # Saves through niri's own screenshot tool; amane's covers it on mango (Mod+Shift+S below)
  niriOnly = [ "Mod+Shift+S" ];

  spawns = filterAttrs (
    combo: bind: bind.action ? spawn && !(builtins.elem combo niriOnly)
  ) config.programs.niri.settings.binds;

  spawnBinds = locked: mapAttrsToList (combo: bind: "${key combo},spawn,${command bind.action.spawn}") (
    filterAttrs (_: bind: bind.allow-when-locked == locked) spawns
  );

  # Workspaces 1-10 as on Hyprland: odd ones on the main screen, even ones on the side screen,
  # each a tag of its monitor; Mod+0 is workspace 10
  workspaceBinds = lib.concatMap (
    ws:
    let
      key = toString (lib.mod ws 10);
      monitor = if lib.mod ws 2 == 0 then "DP-3" else "DP-2";
      tag = toString ((ws + 1) / 2);
    in
    [
      "SUPER,${key},viewcrossmon,${tag},${monitor}"
      "SUPER+SHIFT,${key},tagcrossmon,${tag},${monitor}"
    ]
  ) (lib.range 1 10);
in
{
  wayland.windowManager.mango.settings = {
    bind =
      spawnBinds false
      ++ [
        # Screenshot or screencast, a second press stops a screencast (amane);
        # as on niri, Mod+S copies and Mod+Shift+S copies and saves
        "SUPER,s,spawn,amane ipc call screenshot"
        "SUPER+SHIFT,s,spawn,amane ipc call screenshot save"

        "SUPER,q,killclient,"
        "SUPER,v,togglefloating,"
        "SUPER,Tab,toggleoverview,"

        # Move focus with HJKL, windows with Shift + HJKL
        "SUPER,h,focusdir,left"
        "SUPER,l,focusdir,right"
        "SUPER,k,focusdir,up"
        "SUPER,j,focusdir,down"
        "SUPER+SHIFT,h,exchange_client,left"
        "SUPER+SHIFT,l,exchange_client,right"
        "SUPER+SHIFT,k,exchange_client,up"
        "SUPER+SHIFT,j,exchange_client,down"

        # Previous / next workspace with windows
        "SUPER+CTRL,k,viewtoleft_have_client,0"
        "SUPER+CTRL,j,viewtoright_have_client,0"

        "SUPER,f,togglemaximizescreen,"
        "SUPER+SHIFT,f,togglefullscreen,"

        "SUPER+SHIFT,Escape,quit"
      ]
      ++ workspaceBinds;

    # Also while locked, and by keysym: Play and Pause share a key
    bindsl = spawnBinds true;

    mousebind = [
      "SUPER,btn_left,moveresize,curmove"
      "SUPER,btn_right,moveresize,curresize"
    ];

    axisbind = [
      "SUPER,UP,viewtoleft_have_client,0"
      "SUPER,DOWN,viewtoright_have_client,0"
    ];
  };
}
