# Refuses text that holds a term the owner keeps out of a public repository. The terms live in a
# local file that no repository holds (it cannot: the file would publish them), by default
# ~/.config/agents/public-terms. Without that file, every check passes. Usage:
#
#   public-check --staged              # git's pre-commit hook: the lines the commit adds
#   public-check --message <file>      # git's commit-msg hook: the commit's message
#   public-check --diff <base>         # the lines added since <base>, untracked files included
#   public-check [--repo <owner/name>] [<file>...]   # a text, from files or standard input:
#                                      # an issue, a pull request, a release note before it is sent
#
# The file holds sections. A section's header names the repositories it applies to, by their
# origin's "owner/name" ("*" for all, "!owner/name" to leave one out), then optionally "except" and
# the paths where its terms are allowed: a file, or a folder when the path ends with "/". Each line
# below a header is a case-insensitive extended regular expression. Lines starting with "#" are
# comments. For example:
#
#   [* !Someone/Dotfiles]
#   an-e-mail@example\.org
#   [HoneySlatt/SomeEngine except docs/measurements.md docs/ROADMAP.md]
#   some game|another game
#
# A file's path counts as part of each of its lines. Prints each line that matches, and exits 1 if
# one does, 0 otherwise, 2 on a usage error.
set -euo pipefail

terms=${PUBLIC_TERMS_FILE:-$HOME/.config/agents/public-terms}
[ -r "$terms" ] || exit 0

usage() {
    echo "usage: public-check --staged | --message <file> | --diff <base> | [--repo <owner/name>] [<file>...]" >&2
    exit 2
}

mode="text"
arg=""
repo=""
case "${1:-}" in
    --staged) mode="staged"; shift ;;
    --message) [ $# -ge 2 ] || usage; mode="message"; arg=$2; shift 2 ;;
    --diff) [ $# -ge 2 ] || usage; mode="diff"; arg=$2; shift 2 ;;
    --repo) [ $# -ge 2 ] || usage; repo=$2; shift 2 ;;
esac

if [ -z "$repo" ]; then
    url=$(git remote get-url origin 2>/dev/null || git remote get-url "$(git remote 2>/dev/null | head -n 1)" 2>/dev/null || true)
    url=${url%.git}
    url=${url%/}
    repo=$(printf '%s\n' "$url" | sed -E 's#^.*[:/]([^/:]+/[^/:]+)$#\1#')
fi

# Each line to check, as "<path><TAB><text>".
candidates=$(mktemp)
trap 'rm -f "$candidates"' EXIT
# Each line of a file, or of standard input when the file is "-", after its path and a tab.
prefixed() {
    local label=$1 file=$2
    awk -v label="$label" '{ print label "\t" $0 }' "$file"
}
added_lines() {
    awk '
        /^\+\+\+ / { file = substr($0, 7); next }
        /^\+/ && file != "" { print file "\t" substr($0, 2) }'
}
case "$mode" in
    staged)
        {
            git diff --cached --name-only --diff-filter=d | awk '{ print $0 "\t" }'
            git diff --cached -U0 --no-color --no-ext-diff | added_lines
        } >"$candidates"
        ;;
    message)
        sed -n '/^# -* >8 -*$/q; /^#/!p' "$arg" | prefixed "commit message" - >"$candidates"
        ;;
    diff)
        {
            git diff --name-only --diff-filter=d "$arg" -- | awk '{ print $0 "\t" }'
            git diff -U0 --no-color --no-ext-diff "$arg" -- | added_lines
            git ls-files --others --exclude-standard -z | while IFS= read -r -d '' f; do
                printf '%s\t\n' "$f"
                if grep -Iq '' -- "$f" 2>/dev/null; then prefixed "$f" "./$f"; fi
            done
        } >"$candidates"
        ;;
    text)
        if [ $# -eq 0 ]; then
            prefixed text - >"$candidates"
        else
            for f in "$@"; do prefixed "$f" "$f"; done >"$candidates"
        fi
        ;;
esac

applies=false
excepts=()
found=0
while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
        "" | "#"*) continue ;;
        "["*"]")
            read -r -a words <<<"${line:1:${#line}-2}"
            applies=false
            left_out=false
            excepts=()
            in_except=false
            for w in "${words[@]}"; do
                if [ "$w" = except ]; then
                    in_except=true
                elif $in_except; then
                    excepts+=("$w")
                elif [ "$w" = "!$repo" ]; then
                    left_out=true
                elif [ "$w" = "*" ] || [ "$w" = "$repo" ]; then
                    applies=true
                fi
            done
            if $left_out; then applies=false; fi
            continue
            ;;
    esac
    $applies || continue
    while IFS= read -r hit; do
        path=${hit%%$'\t'*}
        allowed=false
        for e in "${excepts[@]}"; do
            if [ "$path" = "$e" ] || { [ "${e%/}" != "$e" ] && [ "${path#"$e"}" != "$path" ]; }; then
                allowed=true
                break
            fi
        done
        $allowed && continue
        echo "public-check: $path: a term kept out of public repositories ($terms): ${hit#*$'\t'}" | cut -c1-300
        found=$((found + 1))
    done < <(grep -iE -- "$line" "$candidates" || true)
done <"$terms"

if [ "$found" -gt 0 ]; then
    echo "public-check: $found line(s) refused; the terms are in $terms" >&2
    exit 1
fi
