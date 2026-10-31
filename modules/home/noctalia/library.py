"""Small JSON/argv bridge for Noctalia's Slatty and Kopuz panels."""
import base64
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time

CACHE = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "noctalia/library"


def run(args, data=None, timeout=20):
    result = subprocess.run(args, input=data, text=True, capture_output=True, timeout=timeout)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or "The application did not respond.")
    return result.stdout


def rpc(method, request=None, stream=False):
    socket = Path(os.environ.get("XDG_RUNTIME_DIR", "/run/user/" + str(os.getuid()))) / "kopuz/kopuzd.sock"
    raw = run(["grpcurl", "-unix", "-plaintext", "-connect-timeout", "2", "-max-time", "15",
               "-d", "@", str(socket), "kopuz.v1.Kopuz/" + method], json.dumps(request or {}))
    if stream:
        decoder, values = json.JSONDecoder(), []
        while raw.strip():
            value, end = decoder.raw_decode(raw.lstrip())
            values.append(value)
            raw = raw.lstrip()[end:]
        return values
    return json.loads(raw or "{}")


def save(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as output:
        output.write(data)
        temporary = output.name
    os.replace(temporary, path)


def art_ref(record):
    art = record.get("artwork") or {}
    target = art.get("target") or {}
    return {"target": target, "version": art.get("version", "0")} if target else None


def entries(section, refresh=False):
    cache = CACHE / (section + ".json")
    if not refresh and cache.exists() and time.time() - cache.stat().st_mtime < 60:
        return json.loads(cache.read_text())
    if section == "games":
        records = json.loads(run(["slatty", "installs", "--json"]))
        items = [{"id": str(r["id"]), "title": r["title"], "subtitle": "Steam" if r.get("steam_app") else "Slatty",
                  "art": r.get("cover") or "", "steam_app": r.get("steam_app")} for r in records]
    else:
        methods = {"playlists": ("GetPlaylists", {}, "playlists"),
                   "albums": ("GetAlbums", {"limit": 1000000}, "albums"),
                   "artists": ("GetArtists", {"limit": 1000000}, "artists"),
                   "songs": ("GetTracks", {"filter": {}, "page": {"limit": 1000000}}, "items"),
                   "favorites": ("GetTracks", {"filter": {"favorite": True}, "page": {"limit": 1000000}}, "items")}
        method, request, key = methods[section]
        records = rpc(method, request).get(key, [])
        items = [{"id": str(r.get("id", r.get("key", ""))),
                  "title": r.get("title") or r.get("name") or "Unknown",
                  "subtitle": r.get("artist") or r.get("album") or "",
                  "art": art_ref(r)} for r in records]
    save(cache, json.dumps(items).encode())
    return items


def matching(section, query, refresh=False):
    query = query.casefold()
    return [item for item in entries(section, refresh) if query in (item["title"] + " " + item["subtitle"]).casefold()]


def listing(section, query, page, refresh=False):
    items = matching(section, query, refresh)
    pages = max(1, (len(items) + 11) // 12)
    page = min(max(0, int(page)), pages - 1)
    return {"items": items[page * 12:(page + 1) * 12], "page": page, "pages": pages, "total": len(items)}


def artwork(reference):
    if not reference:
        return {"path": ""}
    if isinstance(reference, str) and not reference.startswith(("https://", "http://")):
        return {"path": reference.removeprefix("file://")}
    name = hashlib.sha256(json.dumps(reference, sort_keys=True).encode()).hexdigest()
    path = CACHE / "art" / name
    if not path.exists():
        if isinstance(reference, dict):
            chunks = rpc("GetArtwork", reference["target"], stream=True)
            data = b"".join(base64.b64decode(chunk.get("data", "")) for chunk in chunks)
            if not data:
                return {"path": ""}
            save(path, data)
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            with tempfile.NamedTemporaryFile(dir=path.parent) as temporary:
                run(["curl", "-fsSL", "--proto", "=http,https", "--max-time", "10", "--max-filesize", "10M",
                     "-o", temporary.name, reference])
                save(path, Path(temporary.name).read_bytes())
        files = sorted(path.parent.iterdir(), key=lambda p: p.stat().st_mtime)
        for old in files[:-128]:
            if old != path:
                old.unlink()
    return {"path": str(path)}


def play(section, identifier, query=""):
    # Resolve game metadata locally; never execute commands supplied by a title.
    if section == "games":
        game = next(item for item in entries(section) if item["id"] == identifier)
        args = ["xdg-open", "steam://rungameid/" + str(game["steam_app"])] if game.get("steam_app") else ["slatty", "launch", identifier]
        subprocess.Popen(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
        return {}
    if section in ("songs", "favorites"):
        keys = [item["id"] for item in matching(section, query)]
        return rpc("SetQueue", {"mode": "QUEUE_MODE_REPLACE", "context": {"tracks": {"keys": keys}},
                                "startIndex": keys.index(identifier), "shuffle": True})
    context = {"playlists": {"playlist": {"id": identifier}}, "albums": {"album": {"id": identifier}},
               "artists": {"artistKey": identifier}}[section]
    return rpc("SetQueue", {"mode": "QUEUE_MODE_REPLACE", "context": context, "shuffle": True})


def main():
    command, *args = sys.argv[1:]
    if command == "list":
        return listing(args[0], args[1], args[2], len(args) > 3 and args[3] == "refresh")
    if command == "art":
        return artwork(json.loads(args[0]))
    if command == "play":
        return play(*args)
    if command == "player":
        player = rpc("GetPlayerState")
        key = (player.get("row") or {}).get("key")
        player["favorite"] = any(item["id"] == key for item in entries("favorites")) if key else False
        return player
    if command == "control":
        method = {"toggle": "Toggle", "next": "Next", "previous": "Previous"}[args[0]]
        return rpc(method)
    if command == "volume":
        return rpc("SetVolume", {"volume": max(0, min(1, float(args[0])))})
    if command == "shuffle":
        return rpc("SetMode", {"shuffle": args[0] == "true"})
    if command == "favorite":
        result = rpc("SetFavorite", {"key": args[0], "favorite": args[1] == "true"})
        (CACHE / "favorites.json").unlink(missing_ok=True)
        return result
    raise ValueError("Unknown library action")


if __name__ == "__main__":
    try:
        print(json.dumps(main()))
    except (RuntimeError, ValueError, KeyError, OSError, StopIteration, subprocess.TimeoutExpired) as error:
        print(json.dumps({"error": str(error) or "This item is no longer available."}))
        sys.exit(1)
