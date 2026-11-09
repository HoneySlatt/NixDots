# Runs one command on the owner's desktop, from an agent's service that has no display of its own
# (agents.nix, agentIsolation). For what needs the real compositor or GPU, and only where the
# project's rules allow it: never to inject input, never to take a screenshot of the desktop.
# Usage:
#
#   owner-desktop -- <command> [args...]
#
# It restores the owner's XDG_RUNTIME_DIR, and WAYLAND_DISPLAY and DISPLAY as the user's systemd
# manager knows them, so that the command finds the compositor, PipeWire and the rest.
set -euo pipefail

[ "${1:-}" = -- ] || { echo "usage: owner-desktop -- <command> [args...]" >&2; exit 2; }
shift
[ $# -ge 1 ] || { echo "usage: owner-desktop -- <command> [args...]" >&2; exit 2; }

runtime=${OWNER_RUNTIME_DIR:-/run/user/$(id -u)}
manager=$(XDG_RUNTIME_DIR=$runtime systemctl --user show-environment)
wayland=$(sed -n 's/^WAYLAND_DISPLAY=//p' <<<"$manager")
x11=$(sed -n 's/^DISPLAY=//p' <<<"$manager")
[ -n "$wayland" ] || { echo "owner-desktop: the owner's session exports no WAYLAND_DISPLAY" >&2; exit 1; }

exec env XDG_RUNTIME_DIR="$runtime" WAYLAND_DISPLAY="$wayland" ${x11:+DISPLAY="$x11"} "$@"
