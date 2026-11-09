#!/usr/bin/env bash
# Tests public-check, provider-check and agent-headless, as installed (on PATH) or as given:
#
#   bash test.sh [<public-check> <agent-headless> [<provider-check>]]
#
# public-check runs in a throwaway repository with a throwaway list of terms. provider-check runs on
# a throwaway folder of marks, a fake credentials file and a fake DeepSeek server on 127.0.0.1: it
# never reaches the network. agent-headless starts its headless compositors, but never touches the
# owner's display: the test checks that the command sees only its own. Prints each failure, and
# exits 1 if there is one.
set -uo pipefail

check=${1:-public-check}
headless=${2:-agent-headless}
provider=${3:-provider-check}
failures=0
secret="" # when set, no command may print it
expect() { # <name> <wanted exit code> <command...>
    local name=$1 want=$2 out got
    shift 2
    out=$("$@" 2>&1)
    got=$?
    [ "$got" = "$want" ] || { echo "FAIL $name: exit $got, wanted $want"; failures=$((failures + 1)); }
    if [ -n "$secret" ] && [[ $out == *"$secret"* ]]; then
        echo "FAIL $name: printed the key"
        failures=$((failures + 1))
    fi
}

repo=$(mktemp -d)
trap 'rm -rf "$repo"' EXIT
cd "$repo" || exit 1
git init -q
git remote add origin git@example.org:Someone/Proj.git
export PUBLIC_TERMS_FILE=$repo/.git/terms
cat >"$PUBLIC_TERMS_FILE" <<'EOF'
# a comment
[*]
secret-word
[* !Someone/Proj]
left-out-word
[Someone/Proj except docs/measurements.md bench/]
game one|game two
[Other/Repo]
only-other
EOF
mkdir -p docs bench src
echo "Game One at 60 fps" >docs/measurements.md
echo "game two" >bench/a.txt
echo "fine" >src/a.rs
git add docs bench src
expect "allowed in the excepted file and folder" 0 "$check" --staged
echo "only-other" >>src/a.rs
git add src
expect "a term of another repository" 0 "$check" --staged
echo "inspired by GAME ONE" >>src/a.rs
git add src
expect "a term in an added line, any case" 1 "$check" --staged
git reset -q src
mkdir secret-word
: >secret-word/empty
git add secret-word
expect "a term in an empty file's path" 1 "$check" --staged
git reset -q secret-word
rm -r secret-word
echo "fine" >src/a.rs
git add src
printf 'Subject\n\nholds secret-word\n' >"$repo/.git/msg"
expect "a term in a commit message" 1 "$check" --message "$repo/.git/msg"
printf 'Subject\n# secret-word in a comment\n# ------------------------ >8 ------------------------\nsecret-word\n' >"$repo/.git/msg"
expect "comments and the diff below the scissors" 0 "$check" --message "$repo/.git/msg"
expect "a text on standard input" 1 "$check" <<<"a secret-word here"
expect "a text for another repository" 0 "$check" --repo Other/Repo <<<"game one"
expect "a repository left out of a section" 0 "$check" <<<"left-out-word"
expect "the same section for another repository" 1 "$check" --repo Other/Repo <<<"left-out-word"
git -c user.name=t -c user.email=t@example.org commit -qm init --no-verify
echo "game two" >untracked.txt
expect "a term in an untracked file since a base" 1 "$check" --diff HEAD
rm untracked.txt
expect "nothing added since a base" 0 "$check" --diff HEAD
PUBLIC_TERMS_FILE=/nonexistent expect "no list: every check passes" 0 "$check" --message "$repo/.git/msg"

# provider-check, with a throwaway HOME, so that it never reads the real key even if the variables
# below are renamed. A fake DeepSeek: it answers what the file "answer" holds (the status, a
# newline, the body), after "delay" seconds, and 401 unless the request carries the fake key.
real_home=$HOME
export HOME=$repo/.git/home
fake=$repo/.git/fake-deepseek
mkdir -p "$HOME" "$fake"
cat >"$fake/server.py" <<'EOF'
import http.server, pathlib, sys, time
root = pathlib.Path(sys.argv[1])
class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        delay = root / "delay"
        time.sleep(float(delay.read_text()) if delay.exists() else 0)
        if self.headers.get("Authorization") != "Bearer " + (root / "key").read_text():
            status, body = "401", '{"error": "auth"}'
        else:
            status, body = (root / "answer").read_text().split("\n", 1)
        self.send_response(int(status))
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(body.encode())
    def log_message(self, *args):
        pass
server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
(root / "port").write_text(str(server.server_port))
server.serve_forever()
EOF
key=sk-fake0123456789abcdef
secret=$key
printf '%s' "$key" >"$fake/key"
python3 -I "$fake/server.py" "$fake" &
server_pid=$!
trap 'kill "$server_pid" 2>/dev/null; rm -rf "$repo"' EXIT
for _ in $(seq 50); do [ -s "$fake/port" ] && break; sleep 0.1; done
export AGENT_PROVIDERS_DIR=$repo/.git/providers
PROVIDER_CHECK_DEEPSEEK_URL=http://127.0.0.1:$(cat "$fake/port")/user/balance
export PROVIDER_CHECK_DEEPSEEK_URL
export PROVIDER_CHECK_DEEPSEEK_CREDENTIALS=$fake/credentials.yaml
cat >"$PROVIDER_CHECK_DEEPSEEK_CREDENTIALS" <<EOF
version: 1
records: {}
refs:
  DEEPSEEK_API_KEY: "$key"
EOF
answer() { printf '%s\n%s' "$1" "$2" >"$fake/answer"; }
mark=$AGENT_PROVIDERS_DIR/deepseek
available='{"is_available": true, "balance_infos": [{"currency": "USD", "total_balance": "1.50", "granted_balance": "0.00", "topped_up_balance": "1.50"}]}'

answer 200 "$available"
"$provider" --down deepseek QUOTA >/dev/null
expect "available: exit 0" 0 "$provider" deepseek
[ ! -e "$mark" ] || { echo "FAIL available: the mark is still there"; failures=$((failures + 1)); }
out=$("$provider" deepseek 2>&1)
[ "$out" = $'is_available: true\nbalance: 1.50 USD' ] ||
    { echo "FAIL available, no mark: printed: $out"; failures=$((failures + 1)); }
answer 200 '{"is_available": false, "balance_infos": [{"currency": "USD", "total_balance": "0.00"}]}'
"$provider" --down deepseek QUOTA >/dev/null
expect "unavailable: exit 1" 1 "$provider" deepseek
[ -e "$mark" ] || { echo "FAIL unavailable: the mark was deleted"; failures=$((failures + 1)); }
answer 200 'not json'
expect "an answer that is not JSON" 3 "$provider" deepseek
answer 200 '{"is_available": "yes"}'
expect "an answer whose is_available is not a boolean" 3 "$provider" deepseek
answer 200 '{"balance_infos": []}'
expect "an answer without is_available" 3 "$provider" deepseek
answer 200 ''
expect "an empty answer" 3 "$provider" deepseek
answer 200 '{"is_available": true} {"is_available": true}'
expect "two answers in one" 3 "$provider" deepseek
answer 500 '{"error": "down"}'
expect "a server error" 3 "$provider" deepseek
[ -e "$mark" ] || { echo "FAIL a failed check deleted the mark"; failures=$((failures + 1)); }
answer 200 "$available"
PROVIDER_CHECK_DEEPSEEK_URL=http://127.0.0.1:1/user/balance expect "no network" 3 "$provider" deepseek
PROVIDER_CHECK_DEEPSEEK_URL=http://0.0.0.0:1/user/balance expect "a URL off the loopback" 2 "$provider" deepseek
# A curlrc must not reach the check: it could trace the header to a file or drop the answer.
mkdir -p "$fake/curl-home"
printf 'output = "/dev/null"\ntrace-ascii = "%s"\n' "$fake/trace" >"$fake/curl-home/.curlrc"
CURL_HOME=$fake/curl-home expect "a curlrc" 0 "$provider" deepseek
[ ! -e "$fake/trace" ] || { echo "FAIL a curlrc traced the request"; failures=$((failures + 1)); }
"$provider" --down deepseek QUOTA >/dev/null
printf '%s' wrong-key >"$fake/key"
expect "a key the server refuses" 3 "$provider" deepseek
printf '%s' "$key" >"$fake/key"
PROVIDER_CHECK_DEEPSEEK_CREDENTIALS=$fake/missing.yaml expect "no credentials file" 3 "$provider" deepseek
printf 'version: 1\nrefs: {}\n' >"$fake/empty.yaml"
PROVIDER_CHECK_DEEPSEEK_CREDENTIALS=$fake/empty.yaml expect "no key in the credentials file" 3 "$provider" deepseek
# An alias to no anchor: yq's error would quote the key.
printf 'refs:\n  DEEPSEEK_API_KEY: *%s\n' "$key" >"$fake/broken.yaml"
PROVIDER_CHECK_DEEPSEEK_CREDENTIALS=$fake/broken.yaml expect "a credentials file yq cannot read" 3 "$provider" deepseek
[ -e "$mark" ] || { echo "FAIL a missing key deleted the mark"; failures=$((failures + 1)); }
# While curl waits on the server, the key must not be on the command line of any process of this
# session (provider-check, curl, the shell between them).
echo 2 >"$fake/delay"
"$provider" deepseek >/dev/null 2>&1 &
sleep 1
pgrep -x curl -s 0 >/dev/null || { echo "FAIL the key test saw no curl waiting"; failures=$((failures + 1)); }
for pid in $(pgrep -s 0); do
    if tr '\0' ' ' <"/proc/$pid/cmdline" 2>/dev/null | grep -qF "$key"; then
        echo "FAIL the key is on the command line of process $pid"
        failures=$((failures + 1))
    fi
done
wait $!
# A lead that marks the provider down while a check waits keeps its mark.
rm -f "$mark"
"$provider" deepseek >/dev/null 2>&1 &
checker=$!
sleep 0.5
"$provider" --down deepseek QUOTA >/dev/null
wait "$checker"
[ -e "$mark" ] || { echo "FAIL a check deleted a mark written while it waited"; failures=$((failures + 1)); }
rm "$fake/delay"
# An available provider whose mark cannot be deleted is an error, never "unavailable".
chmod 555 "$AGENT_PROVIDERS_DIR"
expect "a mark that cannot be deleted" 3 "$provider" deepseek
chmod 755 "$AGENT_PROVIDERS_DIR"
expect "a mark with no check" 4 "$provider" claude
expect "a mark with a bad name" 2 "$provider" ../deepseek
expect "no mark" 2 "$provider"
expect "a code of two words" 2 "$provider" --down deepseek "two words"
expect "a check-after in the past" 2 "$provider" --down deepseek QUOTA "2001-01-01"
expect "a check-after that is not a time" 2 "$provider" --down deepseek QUOTA "someday"
# The whole mark, in the skill's format; the minute may turn during the call.
minute() { date -u -d "$1" +%Y-%m-%dT%H:%MZ; }
early=$(minute now) early_after=$(minute 'now + 3 hours')
"$provider" --down claude USAGE_LIMIT "now + 3 hours" >/dev/null
late=$(minute now) late_after=$(minute 'now + 3 hours')
got=$(cat "$AGENT_PROVIDERS_DIR/claude")
case "$got" in
    "since: $early"$'\n'"code: USAGE_LIMIT"$'\n'"check-after: $early_after" | \
        "since: $late"$'\n'"code: USAGE_LIMIT"$'\n'"check-after: $late_after") ;;
    *) echo "FAIL a mark's format: $got"; failures=$((failures + 1)) ;;
esac
# Each write renames a new file into place: a mark written in place would keep its inode.
inode=$(stat -c %i "$AGENT_PROVIDERS_DIR/claude")
"$provider" --down claude USAGE_LIMIT >/dev/null
[ "$(stat -c %i "$AGENT_PROVIDERS_DIR/claude")" != "$inode" ] ||
    { echo "FAIL a mark was written in place"; failures=$((failures + 1)); }
# A writer waits for the folder's lock.
exec 8>"$AGENT_PROVIDERS_DIR/.lock"
flock 8
"$provider" --down locked QUOTA >/dev/null 8>&- &
writer=$!
sleep 0.5
[ ! -e "$AGENT_PROVIDERS_DIR/locked" ] || { echo "FAIL a writer did not wait for the lock"; failures=$((failures + 1)); }
exec 8>&-
wait "$writer"
[ -e "$AGENT_PROVIDERS_DIR/locked" ] || { echo "FAIL a writer did not write once the lock was free"; failures=$((failures + 1)); }
rm "$AGENT_PROVIDERS_DIR/locked"
TZ=Europe/Paris "$provider" --down claude USAGE_LIMIT "2030-01-01 12:00" >/dev/null
after=$(sed -n 's/^check-after: //p' "$AGENT_PROVIDERS_DIR/claude")
[ "$after" = 2030-01-01T11:00Z ] || { echo "FAIL a local check-after: $after"; failures=$((failures + 1)); }
"$provider" --down claude USAGE_LIMIT "2030-01-01 12:00Z" >/dev/null
after=$(sed -n 's/^check-after: //p' "$AGENT_PROVIDERS_DIR/claude")
[ "$after" = 2030-01-01T12:00Z ] || { echo "FAIL a check-after in UTC: $after"; failures=$((failures + 1)); }
# Many leads marking the same provider at once: a reader meanwhile never sees half a mark, and they
# leave one whole mark and no temporary file.
writers=()
for i in $(seq 20); do
    "$provider" --down deepseek "CODE$i" >/dev/null &
    writers+=($!)
done
torn=0
for _ in $(seq 300); do
    n=$(grep -c . "$mark" 2>/dev/null)
    [ -z "$n" ] || [ "$n" = 3 ] || torn=$((torn + 1))
done
wait "${writers[@]}"
[ "$torn" = 0 ] || { echo "FAIL concurrent marks: $torn reads saw half a mark"; failures=$((failures + 1)); }
lines=$(grep -cE '^(since|code|check-after): ' "$mark")
leftovers=$(find "$AGENT_PROVIDERS_DIR" -name '.deepseek.*' | wc -l)
[ "$lines" = 3 ] && [ "$leftovers" = 0 ] ||
    { echo "FAIL concurrent marks: $lines lines, $leftovers temporary files"; failures=$((failures + 1)); }
# --list deletes what has expired, by its check-after or 24 hours after a mark without one.
printf 'since: 2001-01-01T00:00Z\ncode: QUOTA\ncheck-after: 2001-01-02T00:00Z\n' >"$AGENT_PROVIDERS_DIR/old"
printf 'code: QUOTA\n' >"$AGENT_PROVIDERS_DIR/stale"
touch -d '2 days ago' "$AGENT_PROVIDERS_DIR/stale"
printf 'code: QUOTA\n' >"$AGENT_PROVIDERS_DIR/fresh"
out=$("$provider" --list 2>/dev/null)
listed=$(printf '%s\n' "$out" | cut -d: -f1 | sort | paste -sd ' ')
[ "$listed" = "claude deepseek fresh" ] || { echo "FAIL --list: $listed"; failures=$((failures + 1)); }
[ ! -e "$AGENT_PROVIDERS_DIR/old" ] && [ ! -e "$AGENT_PROVIDERS_DIR/stale" ] ||
    { echo "FAIL --list kept an expired mark"; failures=$((failures + 1)); }
kill "$server_pid"
unset AGENT_PROVIDERS_DIR PROVIDER_CHECK_DEEPSEEK_URL PROVIDER_CHECK_DEEPSEEK_CREDENTIALS
secret=""
export HOME=$real_home

wayland_info=$(command -v wayland-info || echo "$(nix build --no-link --print-out-paths nixpkgs#wayland-utils)/bin/wayland-info")
for compositor in "" --sway; do
    out=$("$headless" $compositor -- bash -c '
        [ -z "${DISPLAY-}" ] || echo "DISPLAY set"
        case "$XDG_RUNTIME_DIR" in /tmp/agent-headless.*) ;; *) echo "runtime dir $XDG_RUNTIME_DIR" ;; esac
        case "$XDG_STATE_HOME" in /tmp/agent-headless.*) ;; *) echo "state dir $XDG_STATE_HOME" ;; esac
        [ -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ] || echo "no compositor socket"
        "$1" >/dev/null 2>&1 || echo "wayland-info failed"
        busctl --user list >/dev/null 2>&1 || echo "no session bus"
        if curl -s -m 3 -o /dev/null https://example.org; then echo "network reachable"; fi
        python3 -c "import socket; s = socket.socket(); s.bind((\"127.0.0.1\", 0)); s.listen(); socket.create_connection(s.getsockname())" ||
            echo "loopback down"
        setsid sleep 4242 &
    ' agent-headless "$wayland_info" 2>&1)
    [ -z "$out" ] || { echo "FAIL agent-headless $compositor: $out"; failures=$((failures + 1)); }
    sleep 0.5
    if pgrep -f 'sleep 424[2]' >/dev/null; then
        echo "FAIL agent-headless $compositor: a process outlived it"
        failures=$((failures + 1))
        pkill -f 'sleep 424[2]'
    fi
done
expect "agent-headless passes the command's exit code" 7 "$headless" -- sh -c 'exit 7'
expect "agent-headless refuses a missing command" 2 "$headless" --

if [ "$failures" -gt 0 ]; then
    echo "$failures failure(s)"
    exit 1
fi
echo "all tests passed"
