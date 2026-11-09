# Keeps the marks of AI providers that are down, as the delegate skill describes (section "A
# provider that is down"), and checks whether a provider is back. Usage:
#
#   provider-check <mark>                              # is the provider available? If so, delete its mark
#   provider-check --down <mark> <code> [<check-after>]  # write its mark: since now, check again then
#   provider-check --list                              # delete the expired marks, print the others
#
# A mark is a file named after the provider in ~/.local/state/agents/providers/ (the skill's table
# names them: claude, deepseek), holding three lines:
#
#   since: 2026-11-09T14:02Z
#   code: QUOTA
#   check-after: 2026-11-10T14:02Z
#
# Times are written in UTC. <check-after> is any time GNU date reads, in local time unless it names
# a zone ("19:00", "2026-11-10 14:02Z", "now + 3 hours"), 24 hours after now by default. A mark
# is written to a temporary file, then renamed, so that a reader never sees half of one; every
# change takes a lock on the folder, so that deleting an expired mark cannot delete a newer one.
#
# Only deepseek can be checked for now: GET /user/balance on DeepSeek's API, with the key that
# Pluto's DeepSeek Harness uses (read here, sent to curl on its standard input, never printed or
# passed as an argument). It prints is_available and the balance only. Claude's usage windows are
# not exposed yet (Pluto, delegation plan step C): a claude mark expires at its check-after.
#
# Exit codes: 0 available (or --down and --list done), 1 unavailable, 2 usage error, 3 an error (no
# key, network, an answer it cannot read, a folder it cannot change), 4 a mark this command cannot
# check.
set -Eeuo pipefail
# Any other failure exits 3 too, in functions as well (-E): set -e alone would exit 1, which means
# unavailable.
trap 'exit 3' ERR

dir=${AGENT_PROVIDERS_DIR:-$HOME/.local/state/agents/providers}
# Tests point these at a fake server on 127.0.0.1 and a fake credentials file.
balance_url=${PROVIDER_CHECK_DEEPSEEK_URL:-https://api.deepseek.com/user/balance}
credentials=${PROVIDER_CHECK_DEEPSEEK_CREDENTIALS:-$HOME/.pluto/userdata/deepseek-harness/deepseekHarness_deepseek/.credentials.yaml}

usage() {
    echo "usage: provider-check <mark> | --down <mark> <code> [<check-after>] | --list" >&2
    exit 2
}
fail() { # <exit code> <message>
    echo "provider-check: $2" >&2
    exit "$1"
}
valid_mark() {
    [[ $1 =~ ^[a-z0-9][a-z0-9-]*$ ]] || fail 2 "a mark is lower-case letters, digits and '-': $1"
}
utc() { # <time GNU date reads, local unless it names a zone> -> 2026-11-09T14:02Z
    local seconds
    seconds=$(date -d "$1" +%s 2>/dev/null) || return 1
    date -u -d "@$seconds" +%Y-%m-%dT%H:%MZ
}
# Runs the rest of the command under the folder's lock.
lock() {
    mkdir -p "$dir" || fail 3 "cannot create $dir"
    exec 9>"$dir/.lock" || fail 3 "cannot open $dir/.lock"
    flock 9 || fail 3 "cannot lock $dir/.lock"
}
# The time after which a mark expires, in seconds: its check-after, or 24 hours after the file was
# last written when that line is missing or unreadable.
expires() { # <file>
    local after
    after=$(sed -n 's/^check-after: //p' "$1" | head -n 1)
    # An empty string would read as today's midnight.
    { [ -n "$after" ] && date -u -d "$after" +%s 2>/dev/null; } || echo $(($(stat -c %Y "$1") + 86400))
}

write_mark() { # <mark> <code> [<check-after>]
    local mark=$1 code=$2 after since tmp
    valid_mark "$mark"
    [[ $code =~ ^[A-Za-z0-9_.-]+$ ]] || fail 2 "a code is one word: $code"
    since=$(utc now)
    after=$(utc "${3:-now + 24 hours}") || fail 2 "not a time: $3"
    [ "$(date -u -d "$after" +%s)" -gt "$(date -u +%s)" ] || fail 2 "check-after is not in the future: $after"
    lock
    tmp=$(mktemp "$dir/.$mark.XXXXXX")
    printf 'since: %s\ncode: %s\ncheck-after: %s\n' "$since" "$code" "$after" >"$tmp"
    mv -f "$tmp" "$dir/$mark"
    echo "$mark: down since $since ($code), check after $after"
}

list_marks() {
    local now file mark
    lock
    now=$(date -u +%s)
    for file in "$dir"/*; do
        [ -f "$file" ] || continue
        mark=${file##*/}
        if [ "$(expires "$file")" -le "$now" ]; then
            rm -f "$file"
            echo "$mark: expired, deleted" >&2
        else
            printf '%s: %s\n' "$mark" "$(paste -sd ' ' "$file")"
        fi
    done
}

# The mark's inode, or nothing: a mark written again (renamed into place) has a new one.
mark_inode() { # <mark>
    stat -c %i "$dir/$1" 2>/dev/null || true
}

delete_mark() { # <mark> <its inode when the check began>
    lock
    [ -e "$dir/$1" ] || return 0
    if [ "$(mark_inode "$1")" != "$2" ]; then
        echo "$1: a lead marked it down during the check; mark kept" >&2
        return 0
    fi
    rm -f "$dir/$1" || fail 3 "$1: available, but its mark could not be deleted"
    echo "$1: mark deleted"
}

# The API key of Pluto's DeepSeek Harness. Pluto gives each provider instance its own Harness home
# (DSH_HOME) and strips DEEPSEEK_* from its environment, so the Harness reads the key from that
# home's credentials file, under the reference DEEPSEEK_API_KEY (its route's default apiKeyEnv).
deepseek_key() {
    local key
    [ -r "$credentials" ] || fail 3 "deepseek: cannot read DeepSeek Harness's credentials: $credentials"
    # yq's errors are dropped: they could quote the file.
    key=$(yq -e '.refs.DEEPSEEK_API_KEY | select(tag == "!!str")' "$credentials" 2>/dev/null) ||
        fail 3 "deepseek: no key at refs.DEEPSEEK_API_KEY in $credentials"
    [[ $key =~ ^[[:graph:]]+$ ]] || fail 3 "deepseek: the key in $credentials is not one word"
    printf '%s' "$key"
}

check_deepseek() {
    local key answer status body available before
    # The key goes to DeepSeek only, or to a test's fake server.
    case "$balance_url" in
        https://api.deepseek.com/* | http://127.0.0.1:*) ;;
        *) fail 2 "PROVIDER_CHECK_DEEPSEEK_URL is for tests on 127.0.0.1 only: $balance_url" ;;
    esac
    before=$(mark_inode deepseek)
    key=$(deepseek_key) || exit 3
    # Global, for the trap to see it once this function has returned.
    errors=$(mktemp)
    trap 'rm -f "$errors"' EXIT
    # The key reaches curl as a header on its standard input: an argument would show in ps.
    # --disable, first, keeps curl from reading a curlrc, which could trace the header to a file.
    answer=$(printf 'Authorization: Bearer %s\n' "$key" |
        curl --disable --silent --show-error --connect-timeout 5 --max-time 20 \
            -H @- -H 'Accept: application/json' \
            --write-out '\n%{http_code}' "$balance_url" 2>"$errors") ||
        fail 3 "deepseek: no answer from $balance_url: $(head -c 300 "$errors")"
    status=${answer##*$'\n'}
    body=${answer%$'\n'*}
    case "$status" in
        200) ;;
        401) fail 3 "deepseek: HTTP 401, the key in $credentials was refused" ;;
        *) fail 3 "deepseek: HTTP $status from $balance_url" ;;
    esac
    # Not jq -e: it fails on a false value.
    available=$(jq -r 'if (.is_available | type) == "boolean" then .is_available else error end' <<<"$body" 2>/dev/null) ||
        fail 3 "deepseek: an answer without is_available"
    # An empty answer gives jq nothing to run on, and two give two lines: neither is an answer.
    case "$available" in true | false) ;; *) fail 3 "deepseek: an answer without one is_available" ;; esac
    echo "is_available: $available"
    jq -r '.balance_infos[]? | "balance: \(.total_balance) \(.currency)"' <<<"$body" 2>/dev/null || true
    if [ "$available" = true ]; then
        delete_mark deepseek "$before"
    else
        echo "deepseek: unavailable; mark it with: provider-check --down deepseek <code>" >&2
        exit 1
    fi
}

case "${1:-}" in
    --down) [ $# -ge 3 ] && [ $# -le 4 ] || usage; shift; write_mark "$@" ;;
    --list) [ $# -eq 1 ] || usage; list_marks ;;
    "" | -*) usage ;;
    *)
        [ $# -eq 1 ] || usage
        valid_mark "$1"
        case "$1" in
            deepseek) check_deepseek ;;
            *) fail 4 "$1: no check for this provider yet; its mark expires at its check-after" ;;
        esac
        ;;
esac
