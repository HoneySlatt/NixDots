#!/usr/bin/env python3
"""Update locally pinned packages, then build before keeping the new pin."""

import argparse
import json
from pathlib import Path
import re
import subprocess
import sys


PACKAGES = (
    "nym-vpnd", "nuvio", "rqbit-desktop", "kimi-code",
    "kimi-code-desktop", "zcode", "kytyps5",
)


def output(*args):
    return subprocess.check_output(args, text=True).strip()


def fetch(url):
    return output("curl", "--fail", "--silent", "--show-error", "--location",
                  "--connect-timeout", "15", "--max-time", "60", url)


def version(value):
    if not re.fullmatch(r"[0-9][0-9A-Za-z.+-]*", value):
        raise ValueError(f"Invalid upstream version: {value!r}")
    return value


def field(text, name):
    matches = re.findall(rf'^\s+{name} = "([^"]+)";$', text, re.MULTILINE)
    if len(matches) != 1:
        raise ValueError(f"Expected exactly one {name} in the package definition")
    return matches[0]


def replace_field(text, name, value):
    field(text, name)
    return re.sub(rf'^(\s+{name} = ")[^"]+(";)$',
                  lambda m: m[1] + value + m[2], text, flags=re.MULTILINE)


def github_release(package):
    repo, prefix, asset_template = {
        "nym-vpnd": ("nymtech/nym-vpn-client", "nym-vpn-v",
                     "nym-vpn-core-v{version}_linux_x86_64.tar.gz"),
        "nuvio": ("NuvioMedia/NuvioDesktop", "",
                  "Nuvio-Linux-x86_64-{version}.AppImage"),
        "rqbit-desktop": ("ikatson/rqbit", "v",
                          "rqbit-desktop_{version}_amd64.deb"),
    }[package]
    releases = json.loads(fetch(f"https://api.github.com/repos/{repo}/releases?per_page=30"))
    for release in releases:
        tag = release["tag_name"]
        if release["draft"] or release["prerelease"] or not tag.startswith(prefix):
            continue
        latest = tag[len(prefix):]
        asset = asset_template.format(version=latest)
        if any(item["name"] == asset for item in release["assets"]):
            return version(latest), None
    raise ValueError(f"No release with a matching Linux asset for {package}")


def kimi_latest(package):
    suffix = "/desktop/latest-linux.yml" if package == "kimi-code-desktop" else "/latest"
    try:
        manifest = fetch("https://code.kimi.ai/kimi-code" + suffix)
    except subprocess.CalledProcessError:
        manifest = fetch("https://code.kimi.com/kimi-code" + suffix)
    if package == "kimi-code-desktop":
        match = re.search(r"^version:\s*([0-9][0-9A-Za-z.+-]*)\s*$", manifest, re.MULTILINE)
        if not match:
            raise ValueError("Kimi Desktop manifest has no version")
        manifest = match[1]
    return version(manifest.strip()), None


def latest_pin(package):
    if package in ("nym-vpnd", "nuvio", "rqbit-desktop"):
        return github_release(package)
    if package.startswith("kimi-code"):
        return kimi_latest(package)
    if package == "zcode":
        # The site also lists older releases and macOS-only downloads.
        versions = re.findall(
            r"https://cdn-zcode\.z\.ai/zcode/electron/releases/([0-9]+\.[0-9]+\.[0-9]+)/linux-x64/",
            fetch("https://zcode.z.ai/en"),
        )
        if not versions:
            raise ValueError("No ZCode Linux release on the download page")
        return max(versions, key=lambda v: tuple(map(int, v.split(".")))), None
    commit = json.loads(fetch("https://api.github.com/repos/KytyPS5/KytyPS5/commits?per_page=1"))[0]
    revision = commit["sha"]
    if not re.fullmatch(r"[0-9a-f]{40}", revision):
        raise ValueError("Invalid KytyPS5 commit")
    return "0-unstable-" + commit["commit"]["committer"]["date"][:10], revision


def prefetch(text, latest, revision):
    if revision:
        result = json.loads(output(
            "nix-prefetch-git", "--url", "https://github.com/KytyPS5/KytyPS5.git",
            "--rev", revision, "--fetch-submodules",
        ))
        return result["hash"]
    url = field(text, "url").replace("${version}", latest)
    return json.loads(output("nix", "store", "prefetch-file", "--json", url))["hash"]


def update(root, package):
    file = root / "pkgs" / package / "default.nix"
    original = file.read_text()
    current = field(original, "version")
    latest, revision = latest_pin(package)
    if latest == current and (not revision or revision == field(original, "rev")):
        print(f"{package} is up to date ({current})")
        return
    print(f"Updating {package}: {current} -> {latest}", flush=True)
    digest = prefetch(original, latest, revision)
    if not re.fullmatch(r"sha256-[A-Za-z0-9+/]{43}=", digest):
        raise ValueError("Prefetch returned an invalid SHA-256 hash")
    candidate = replace_field(replace_field(original, "version", latest), "hash", digest)
    if revision:
        candidate = replace_field(candidate, "rev", revision)
    try:
        file.write_text(candidate)
        # path: includes local package files without requiring git staging.
        subprocess.run([
            "nix", "build", f"path:{root}#nixosConfigurations.desktop.pkgs.{package}",
            "--no-link", "--no-write-lock-file",
        ], check=True)
    except BaseException:
        if file.read_text() == candidate:
            file.write_text(original)
            print("Build interrupted or failed; previous pin restored.", file=sys.stderr)
        else:
            print(f"{file} changed during the build; leaving it untouched.", file=sys.stderr)
        raise
    print(f"{package} {latest} built; run nixos-rebuild switch to apply.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("package", choices=(*PACKAGES, "all"))
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    packages = PACKAGES if args.package == "all" else (args.package,)
    failed = []
    for package in packages:
        try:
            update(root, package)
        except (ValueError, OSError, subprocess.CalledProcessError) as error:
            print(f"Update failed for {package}: {error}", file=sys.stderr)
            failed.append(package)
    if failed:
        print(f"Failed packages: {', '.join(failed)}", file=sys.stderr)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
