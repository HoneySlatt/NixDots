#!/usr/bin/env bash
# Tests run.sh, brief.sh and guard.sh in a throwaway repository. Usage: bash test.sh
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
failures=0
check() { # <name> <expected exit> <command...>
    local name=$1 want=$2
    shift 2
    "$@" >"$work/last.out" 2>&1
    local got=$?
    if [ "$got" = "$want" ]; then
        echo "ok   $name"
    else
        echo "FAIL $name: exit $got, expected $want"
        sed 's/^/     /' "$work/last.out"
        failures=$((failures + 1))
    fi
}
has() { grep -q -- "$1" "$work/last.out" || { echo "FAIL output lacks: $1"; failures=$((failures + 1)); }; }

cd "$work" || exit 1
git init -q repo && cd repo || exit 1
git config user.email test@example.invalid && git config user.name test
mkdir -p src scripts docs
printf 'fn main() {}\n' >src/main.rs
printf 'echo check\n' >scripts/check.sh
printf '# Guide\n' >docs/guide.md
printf 'test\n' >src/tests.rs
git add -A && git commit -qm base
base=$(git rev-parse HEAD)

# run.sh keeps the proof and returns the command's code.
check "run.sh passes a success through" 0 bash "$here/run.sh" t1 -- sh -c 'echo hello'
has "hello"
check "run.sh passes a failure through" 3 bash "$here/run.sh" t1 -- sh -c 'echo broken; exit 3'
check "run.sh numbers its runs" 0 test -f .delegation/t1/02.exit
check "run.sh records the exit code" 0 grep -qx 3 .delegation/t1/02.exit
check "run.sh records the commit" 0 grep -qx "$base" .delegation/t1/01.commit
check "run.sh excludes its folder from git" 0 grep -qxF .delegation/ .git/info/exclude
check "run.sh refuses a malformed id" 2 bash "$here/run.sh" '../x' -- true
check "run.sh refuses '..' as an id" 2 bash "$here/run.sh" .. -- true
sed -i '/^\.delegation\/$/d' .git/info/exclude
printf '*.log' >>.git/info/exclude
check "run.sh keeps the last exclude pattern apart" 0 bash "$here/run.sh" t2 -- true
check "run.sh adds its folder on a line of its own" 0 grep -qx '\*\.log' .git/info/exclude
check "run.sh runs an exclusive command" 0 bash "$here/run.sh" t1 --exclusive -- true

# brief.sh saves the brief with its base commit, once per task id.
printf 'Goal: count the lines.\n' >"$work/brief.txt"
sed -i '/^\.delegation\/$/d' .git/info/exclude
check "brief.sh saves a brief" 0 bash "$here/brief.sh" b1 "$work/brief.txt"
has ".delegation/b1/brief.md"
check "brief.sh excludes its folder from git" 0 grep -qxF .delegation/ .git/info/exclude
check "brief.sh records the base commit" 0 grep -qx "Base: $base" .delegation/b1/brief.md
check "brief.sh keeps the brief's text" 0 grep -qx 'Goal: count the lines.' .delegation/b1/brief.md
check "brief.sh refuses to overwrite a saved brief" 2 bash "$here/brief.sh" b1 "$work/brief.txt"
check "brief.sh reads standard input" 0 sh -c "cd src && echo 'Goal: from stdin.' | bash '$here/brief.sh' b2 -"
check "brief.sh writes at the repository's root" 0 grep -qx 'Goal: from stdin.' .delegation/b2/brief.md
check "brief.sh refuses an empty brief" 2 sh -c "printf ' \t\n' | bash '$here/brief.sh' b3 -"
check "brief.sh refuses a malformed id" 2 bash "$here/brief.sh" '../x' "$work/brief.txt"
check "brief.sh refuses '..' as an id" 2 bash "$here/brief.sh" .. "$work/brief.txt"
: >.delegation/blocker
check "brief.sh fails when it cannot write" 1 bash "$here/brief.sh" blocker "$work/brief.txt"
rm .delegation/blocker
if [ "$(id -u)" != 0 ]; then
    mkdir -p .delegation/locked && chmod a-w .delegation/locked
    check "brief.sh fails when its file cannot be written" 1 bash "$here/brief.sh" locked "$work/brief.txt"
    check "brief.sh leaves no temporary file" 1 test -e .delegation/locked/brief.md.tmp
    chmod u+w .delegation/locked
fi
printf 'draft\n' >docs/draft.md
check "brief.sh saves a brief over uncommitted changes" 0 bash "$here/brief.sh" b4 "$work/brief.txt"
has "uncommitted changes"
check "brief.sh lists the uncommitted paths" 0 grep -qF '?? docs/draft.md' .delegation/b4/brief.md
check "brief.sh leaves its own folder out of that list" 1 grep -qF '.delegation' .delegation/b4/brief.md
rm docs/draft.md

# guard.sh
check "guard is clean with no change" 0 bash "$here/guard.sh" "$base"
printf 'fn main() { let x = 1; }\n' >src/main.rs
check "guard accepts a plain change" 0 bash "$here/guard.sh" "$base"
printf 'echo skipped\n' >scripts/check.sh
check "guard refuses a change to scripts/" 1 bash "$here/guard.sh" "$base"
has "protected path changed: scripts/check.sh"
git checkout -q scripts/check.sh
printf 'changed\n' >src/tests.rs
check "guard refuses a change to a --protect path" 1 bash "$here/guard.sh" "$base" --protect src/tests.rs
git checkout -q src/tests.rs
printf '#[ignore]\nfn slow() {}\n' >src/new.rs
check "guard refuses #[ignore] in a new file" 1 bash "$here/guard.sh" "$base"
has "forbidden line added: src/new.rs:#\[ignore\]"
rm src/new.rs
printf 'fn main() { let x = Some(1).unwrap(); }\n' >src/main.rs
check "guard refuses unwrap() in a changed file" 1 bash "$here/guard.sh" "$base"
check "guard accepts a line matched by --allow" 0 bash "$here/guard.sh" "$base" --allow 'unwrap\(\)'
git checkout -q src/main.rs
git commit -q --allow-empty -m empty
printf 'unsafe { }\n' >>src/main.rs && git commit -qam unsafe
check "guard sees committed changes since the base" 1 bash "$here/guard.sh" "$base"
git reset -q --hard "$base"
check "guard refuses a listed document left unchanged" 1 bash "$here/guard.sh" "$base" --doc docs/guide.md
printf 'More.\n' >>docs/guide.md
check "guard accepts a listed document that changed" 0 bash "$here/guard.sh" "$base" --doc docs/guide.md
check "guard refuses an unknown base" 2 bash "$here/guard.sh" not-a-commit
git checkout -q -b side && git commit -q --allow-empty -m side && side=$(git rev-parse HEAD)
git checkout -q - && git branch -q -D side
check "guard refuses a base that is not an ancestor" 1 bash "$here/guard.sh" "$side"
has "not an ancestor"

echo
if [ "$failures" -gt 0 ]; then
    echo "$failures failure(s)"
    exit 1
fi
echo "all passed"
