#!/usr/bin/env bash
# Checks a delegated task's changes against its brief, before the delegator reads the diff.
# Usage, from the repository the task worked in:
#
#   bash <skill>/guard.sh <base> [--protect <path>]... [--doc <path>]... [--allow <regex>]...
#
# <base> is the commit the task started from. The changes are the working tree and any commits
# since <base>, untracked files included. It fails when <base> is not an ancestor of HEAD (the task
# started elsewhere, so its changes cannot be told apart), and when the changes:
# - touch a protected path: scripts/, .github/, CI and lint configuration, toolchains, lock files,
#   and every --protect path (the brief's tests, budgets, benchmarks);
# - add a line that silences a check or hides a failure (#[allow, #[ignore, unsafe, unwrap(),
#   todo!, eslint-disable, @ts-ignore, noqa, .skip(...), unless an --allow regex matches the line;
# - leave a --doc path unchanged;
# - add a term that the owner keeps out of public repositories, when public-check is installed.
# It prints every violation, and exits 1 if there is one, 0 otherwise.
set -uo pipefail

[ $# -ge 1 ] || { echo "usage: bash guard.sh <base> [--protect <path>]... [--doc <path>]... [--allow <regex>]..." >&2; exit 2; }
base=$1
shift
protect=(scripts/ .github/ .gitlab-ci.yml rust-toolchain rust-toolchain.toml clippy.toml .clippy.toml
    rustfmt.toml .rustfmt.toml deny.toml Cargo.lock flake.lock package-lock.json pnpm-lock.yaml
    .eslintrc eslint.config biome.json tsconfig .oxlintrc vite.config vitest.config)
docs=()
allow=()
while [ $# -gt 0 ]; do
    case "$1" in
        --protect) protect+=("$2"); shift 2 ;;
        --doc) docs+=("$2"); shift 2 ;;
        --allow) allow+=("$2"); shift 2 ;;
        *) echo "guard.sh: unknown option $1" >&2; exit 2 ;;
    esac
done

git rev-parse --verify --quiet "$base^{commit}" >/dev/null || { echo "guard.sh: unknown base $base" >&2; exit 2; }
cd "$(git rev-parse --show-toplevel)" || exit 2

changed=$({
    git diff --name-only "$base" --
    git ls-files --others --exclude-standard
} | grep -v '^\.delegation/' | sort -u)
violations=0
fail() {
    echo "guard: $1"
    violations=$((violations + 1))
}

git merge-base --is-ancestor "$base" HEAD || fail "the base $base is not an ancestor of HEAD: the task did not start from it"

while IFS= read -r path; do
    [ -n "$path" ] || continue
    for p in "${protect[@]}"; do
        case "$path" in
            "$p" | "$p"/* | "$p"* ) fail "protected path changed: $path (rule: $p)"; break ;;
        esac
    done
done <<<"$changed"

# Added lines of tracked files, then every line of new files, each as "path:line".
added=$({
    git diff -U0 --no-color "$base" -- | awk '
        /^\+\+\+ / { file = substr($0, 7); next }
        /^\+/ && file != "" && file !~ /^\.delegation\// { print file ":" substr($0, 2) }'
    git ls-files --others --exclude-standard -z | grep -zv '^\.delegation/' |
        xargs -0 -r grep -IH '' --
})
pattern='#!?\[allow|#\[ignore|\bunsafe\b|\.unwrap\(\)|\btodo!|\bunimplemented!|eslint-disable|@ts-ignore|@ts-nocheck|# *noqa|\b(it|test|describe)\.skip\(|\.only\('
while IFS= read -r line; do
    [ -n "$line" ] || continue
    printf '%s\n' "$line" | grep -qE "$pattern" || continue
    allowed=false
    for a in "${allow[@]}"; do
        printf '%s\n' "$line" | grep -qE -- "$a" && { allowed=true; break; }
    done
    $allowed || fail "forbidden line added: $line"
done <<<"$added"

for d in "${docs[@]}"; do
    grep -qxF -- "$d" <<<"$changed" || fail "document left unchanged: $d"
done

# The terms the owner keeps out of public repositories (agents/public-check.sh), where it is
# installed.
if command -v public-check >/dev/null; then
    while IFS= read -r line; do
        fail "${line#public-check: }"
    done < <(public-check --diff "$base" 2>/dev/null | grep '^public-check: ' || true)
fi

if [ "$violations" -gt 0 ]; then
    echo "guard: $violations violation(s)"
    exit 1
fi
echo "guard: clean ($(grep -c . <<<"$changed") path(s) changed)"
