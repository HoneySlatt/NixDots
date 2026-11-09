# What a systemd user service that runs AI agents adds to its Service section, so that nothing they
# start reaches the owner's display or sound by accident. Without a display, GTK and libwayland fall
# back on "wayland-0" in XDG_RUNTIME_DIR: the service gets a runtime folder of its own, which holds
# only the links to the session bus, systemd and the SSH and secret agents. PipeWire, the
# compositor and the shell's sockets stay out of reach. An agent runs a program with a window
# through agent-headless, and reaches the desktop on purpose through owner-desktop, which restores
# the owner's folder from OWNER_RUNTIME_DIR. This guards against accidents, not against a program
# set on escaping: the session bus can still start one.
{ pkgs, name }:
{
  UnsetEnvironment = [
    "WAYLAND_DISPLAY"
    "WAYLAND_SOCKET"
    "DISPLAY"
    "SWAYSOCK"
    "NIRI_SOCKET"
    "HYPRLAND_INSTANCE_SIGNATURE"
    "PULSE_SERVER"
    "PIPEWIRE_REMOTE"
  ];
  RuntimeDirectory = "agents-${name}";
  Environment = [
    "XDG_RUNTIME_DIR=%t/agents-${name}"
    "OWNER_RUNTIME_DIR=%t"
  ];
  ExecStartPre = "${pkgs.writeShellScript "agents-${name}-runtime" ''
    for entry in bus systemd gcr keyring; do
      ln -sfn "$OWNER_RUNTIME_DIR/$entry" "$XDG_RUNTIME_DIR/$entry"
    done
  ''}";
}
