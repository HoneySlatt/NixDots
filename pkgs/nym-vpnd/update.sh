#!/usr/bin/env bash
set -euo pipefail

file="$HOME/NixOS/pkgs/nym-vpnd/default.nix"

current=$(sed -n 's/^  version = "\(.*\)";$/\1/p' "$file")

# Skip prereleases and Android-only releases that ship no Linux core
latest=$(curl -fsSL "https://api.github.com/repos/nymtech/nym-vpn-client/releases?per_page=30" | jq -r '
  [.[] | select(.prerelease | not)
       | select(any(.assets[]; .name | test("^nym-vpn-core-.*_linux_x86_64\\.tar\\.gz$")))]
  | first | .tag_name | ltrimstr("nym-vpn-v")')

if [[ "$current" == "$latest" ]]; then
  echo "nym-vpnd is up to date ($current)"
  exit 0
fi

echo "Updating nym-vpnd: $current -> $latest"

url="https://github.com/nymtech/nym-vpn-client/releases/download/nym-vpn-v$latest/nym-vpn-core-v${latest}_linux_x86_64.tar.gz"
hash=$(nix store prefetch-file --json "$url" | jq -r .hash)

sed -i \
  -e "s|^  version = \".*\";$|  version = \"$latest\";|" \
  -e "s|^    hash = \".*\";$|    hash = \"$hash\";|" \
  "$file"

nix build "$HOME/NixOS#nym-vpnd" --no-link

echo "nym-vpnd $latest built, run nixos-rebuild switch to apply"
