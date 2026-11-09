# The part of agent-headless that runs inside its systemd scope, in the environment that
# agent-headless.sh prepared: it starts the private session bus and the headless compositor, waits
# for the compositor's socket, then runs the command, off the network unless asked.
set -euo pipefail

# The second step, in the new network namespace. Raising the loopback needs root in the namespace;
# a nested namespace then maps the user back, so that the command runs as the owner's user.
if [ "${1:-}" = --in-netns ]; then
    uid=$2 gid=$3
    shift 3
    ip link set lo up
    exec unshare --user --map-user="$uid" --map-group="$gid" -- "$@"
fi

run=$XDG_RUNTIME_DIR
root=$(dirname "$run")

# No <servicedir>: the bus activates no service, so no keyring, portal or daemon of the owner's.
cat >"$root/session-bus.conf" <<EOF
<!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-Bus Bus Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>
  <type>session</type>
  <listen>unix:path=$run/bus</listen>
  <auth>EXTERNAL</auth>
  <policy context="default">
    <allow send_destination="*" eavesdrop="true"/>
    <allow eavesdrop="true"/>
    <allow own="*"/>
  </policy>
</busconfig>
EOF
dbus-daemon --config-file="$root/session-bus.conf" --fork
export DBUS_SESSION_BUS_ADDRESS="unix:path=$run/bus"

case "$AGENT_HEADLESS_COMPOSITOR" in
    weston)
        weston --backend=headless --renderer=pixman --width=3840 --height=2160 \
            --socket=wayland-1 --idle-time=0 --no-config >"$root/compositor.log" 2>&1 &
        ;;
    sway)
        printf 'output HEADLESS-1 resolution 3840x2160\n' >"$root/sway.conf"
        WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 WLR_RENDERER=pixman \
            sway -c "$root/sway.conf" >"$root/compositor.log" 2>&1 &
        ;;
esac
compositor_pid=$!

socket=""
for _ in $(seq 100); do
    for s in "$run"/wayland-*; do
        [ -S "$s" ] && { socket=${s##*/}; break 2; }
    done
    kill -0 "$compositor_pid" 2>/dev/null || break
    sleep 0.1
done
if [ -z "$socket" ]; then
    echo "agent-headless: the $AGENT_HEADLESS_COMPOSITOR compositor did not start; its log:" >&2
    cat "$root/compositor.log" >&2
    exit 1
fi
export WAYLAND_DISPLAY=$socket
if [ "$AGENT_HEADLESS_COMPOSITOR" = sway ]; then
    for s in "$run"/sway-ipc.*.sock; do
        [ -S "$s" ] && export SWAYSOCK=$s
    done
fi
unset AGENT_HEADLESS_COMPOSITOR

if [ "$AGENT_HEADLESS_NET" = true ]; then
    unset AGENT_HEADLESS_NET
    exec "$@"
fi
unset AGENT_HEADLESS_NET
# A network namespace of its own, with only the loopback up, so that local test servers still work:
# the second step, at the top of this script.
exec unshare --user --map-root-user --net -- "$0" --in-netns "$(id -u)" "$(id -g)" "$@"
