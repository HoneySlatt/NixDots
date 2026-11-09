#!/usr/bin/env bash
# Saves a delegated task's brief with the commit it starts from, so that the task can be checked and
# replayed later. Usage, from the repository the task works in, before launching it:
#
#   bash <skill>/brief.sh <task-id> <brief-file>     (or - to read the brief from standard input)
#
# It writes .delegation/<task-id>/brief.md at the repository's root: the task id, the base commit,
# the time, the paths that differed from that commit, then the brief. It refuses to overwrite a
# saved brief: a correction round is a new task with its own id. It warns when the checkout holds
# uncommitted changes, which a task in its own worktree will not see. .delegation/ is added to the
# repository's local exclude file.
set -uo pipefail

[ $# -eq 2 ] || { echo "usage: bash brief.sh <task-id> <brief-file|->" >&2; exit 2; }
task=$1
source=$2
case "$task" in
    "" | . | .. | *[!A-Za-z0-9._-]*) echo "brief.sh: the task id may hold only letters, digits, '.', '_' and '-', and is not '.' or '..'" >&2; exit 2 ;;
esac
if [ "$source" = - ]; then
    brief=$(cat)
else
    brief=$(cat -- "$source") || exit 2
fi
[ -n "${brief//[[:space:]]/}" ] || { echo "brief.sh: the brief is empty" >&2; exit 2; }

root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "brief.sh: not inside a git repository" >&2; exit 2; }
base=$(git rev-parse --verify --quiet HEAD) || { echo "brief.sh: the repository has no commit to start from" >&2; exit 2; }
exclude="$(git rev-parse --git-common-dir)/info/exclude"
mkdir -p "$(dirname "$exclude")"
if ! grep -qxF '.delegation/' "$exclude" 2>/dev/null; then
    # A file without a final newline would merge its last pattern with this one.
    [ ! -s "$exclude" ] || [ -z "$(tail -c 1 "$exclude")" ] || echo >>"$exclude"
    echo '.delegation/' >>"$exclude"
fi

dir="$root/.delegation/$task"
file="$dir/brief.md"
[ ! -e "$file" ] || { echo "brief.sh: ${file#"$root"/} exists; a new round takes a new task id" >&2; exit 2; }
mkdir -p "$dir" || exit 1
dirty=$(git status --porcelain --untracked-files=all -- ':(top)')

write_brief() {
    echo "Task: $task"
    echo "Base: $base"
    echo "Saved: $(date -u +%Y-%m-%dT%H:%MZ)"
    if [ -n "$dirty" ]; then
        echo "Uncommitted at saving:"
        printf '%s\n' "$dirty" | sed 's/^/    /'
    fi
    echo
    printf '%s\n' "$brief"
}
if ! write_brief >"$file.tmp" || ! mv "$file.tmp" "$file"; then
    rm -f "$file.tmp"
    echo "brief.sh: could not save ${file#"$root"/}" >&2
    exit 1
fi

[ -z "$dirty" ] || echo "brief.sh: uncommitted changes: a task in its own worktree starts from $base without them" >&2
echo "${file#"$root"/}"
