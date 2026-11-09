# Runs one command away from the owner's desktop, data and network: the way for an agent to run a
# program with a window. Usage:
#
#   agent-headless [--sway] [--net] [--keep] -- <command> [args...]
#
# The command gets:
# - its own headless compositor, at 3840x2160: Weston by default, Sway with --sway (for layer-shell
#   clients such as a desktop shell); pixman renders, so the GPU is never the owner's;
# - a private XDG_RUNTIME_DIR, so that a toolkit that falls back on "wayland-0" (GTK, libwayland)
#   finds only this compositor; DISPLAY stays unset;
# - a private session bus that starts no service, and a system bus that points nowhere;
# - throwaway XDG_CONFIG_HOME, XDG_DATA_HOME, XDG_STATE_HOME and XDG_CACHE_HOME, so that no
#   program writes the owner's settings, saves or journals; HOME stays, for cargo, rustup and nix;
# - no network (a new network namespace) unless --net is given.
# Everything runs in a transient systemd scope, stopped at the end with every process it holds,
# even those that left their process group; a scope still running after an hour is stopped too.
# --keep leaves the throwaway folder in place and prints its path, to see what the command wrote.
# Build first: without --net, cargo cannot fetch anything. Run it inside `nix develop`, not around
# it: nix's caches live in XDG_CACHE_HOME. Exits with the command's code.
set -euo pipefail

usage() {
    echo "usage: agent-headless [--sway] [--net] [--keep] -- <command> [args...]" >&2
    exit 2
}

compositor=weston
net=false
keep=false
while [ $# -gt 0 ]; do
    case "$1" in
        --sway) compositor=sway; shift ;;
        --net) net=true; shift ;;
        --keep) keep=true; shift ;;
        --) shift; break ;;
        *) usage ;;
    esac
done
[ $# -ge 1 ] || usage

# The folder holds the sockets: its path stays short, as a socket's path is limited to 108 bytes.
root=$(mktemp -d /tmp/agent-headless.XXXXXX)
run="$root/run"
mkdir -m 700 "$run"
mkdir "$root/config" "$root/data" "$root/state" "$root/cache"

unit="agent-headless-${root##*.}"
code=0
systemd-run --user --scope --quiet --collect --expand-environment=no --unit="$unit" \
    -p RuntimeMaxSec=3600 -- \
    env -u WAYLAND_DISPLAY -u WAYLAND_SOCKET -u DISPLAY -u SWAYSOCK -u NIRI_SOCKET \
    -u HYPRLAND_INSTANCE_SIGNATURE -u PULSE_SERVER -u PIPEWIRE_REMOTE \
    XDG_RUNTIME_DIR="$run" \
    XDG_CONFIG_HOME="$root/config" XDG_DATA_HOME="$root/data" \
    XDG_STATE_HOME="$root/state" XDG_CACHE_HOME="$root/cache" \
    DBUS_SYSTEM_BUS_ADDRESS="unix:path=$run/no-system-bus" \
    AGENT_HEADLESS_COMPOSITOR="$compositor" AGENT_HEADLESS_NET="$net" \
    agent-headless-inner "$@" || code=$?
systemctl --user stop "$unit.scope" 2>/dev/null || true

if $keep; then
    echo "agent-headless: kept $root" >&2
else
    rm -rf "$root"
fi
exit "$code"
