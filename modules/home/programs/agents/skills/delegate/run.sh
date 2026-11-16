#!/usr/bin/env bash
# Runs one command for a delegated task and keeps its proof, so that the delegator reads files
# rather than trusting a report. Usage, from the repository the task works in:
#
#   bash <skill>/run.sh <task-id> [--exclusive] -- <command> [args...]
#
# Each run writes .delegation/<task-id>/NN.{cmd,out,exit,commit} at the repository's root: the
# command, its output (stdout and stderr), its exit code, and the commit it ran on with the paths
# that differed from it. It prints the last 30 lines and the exit code, and exits with the
# command's code. --exclusive waits for any other exclusive run on this machine, for measurements
# that another build would disturb. .delegation/ is added to the repository's local exclude file.
set -uo pipefail

usage() {
    echo "usage: bash run.sh <task-id> [--exclusive] -- <command> [args...]" >&2
    exit 2
}

[ $# -ge 3 ] || usage
task=$1
shift
case "$task" in
    "" | . | .. | *[!A-Za-z0-9._-]*) echo "run.sh: the task id may hold only letters, digits, '.', '_' and '-', and is not '.' or '..'" >&2; exit 2 ;;
esac
exclusive=false
if [ "$1" = --exclusive ]; then
    exclusive=true
    shift
fi
[ "$1" = -- ] || usage
shift
[ $# -ge 1 ] || usage

root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "run.sh: not inside a git repository" >&2; exit 2; }
exclude="$(git rev-parse --git-common-dir)/info/exclude"
mkdir -p "$(dirname "$exclude")"
if ! grep -qxF '.delegation/' "$exclude" 2>/dev/null; then
    # A file without a final newline would merge its last pattern with this one.
    [ ! -s "$exclude" ] || [ -z "$(tail -c 1 "$exclude")" ] || echo >>"$exclude"
    echo '.delegation/' >>"$exclude"
fi

dir="$root/.delegation/$task"
mkdir -p "$dir"
n=1
while [ -e "$(printf '%s/%02d.cmd' "$dir" "$n")" ]; do n=$((n + 1)); done
base=$(printf '%s/%02d' "$dir" "$n")

printf '%q ' "$@" >"$base.cmd"
echo >>"$base.cmd"
{
    git rev-parse HEAD 2>/dev/null || echo "no commit"
    git status --porcelain --untracked-files=all -- . ':(exclude).delegation'
} >"$base.commit"

if $exclusive; then
    # The owner's runtime folder, not the agents' service's own, so that every agent shares the lock.
    lock="${OWNER_RUNTIME_DIR:-/run/user/$(id -u)}/agents-exclusive-run.lock"
    exec 9>"$lock"
    flock 9
fi
"$@" >"$base.out" 2>&1
code=$?
echo "$code" >"$base.exit"

tail -n 30 "$base.out"
echo "--- exit $code; full output: ${base#"$root"/}.out"
exit "$code"
