pragma Singleton

import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property string configPath: "/home/honey/.config/quickshell/navidrome.json"
    property string socketPath: "/tmp/quickshell-music.sock"
    property string server: "http://localhost:4533"
    property string username: ""
    property string salt: ""
    property string token: ""
    property string apiVersion: "1.16.1"
    property string clientName: "quickshell"

    property bool ready: false
    property bool loading: false
    property string errorMessage: ""
    property string statusText: "Loading Navidrome..."

    property var playlists: []
    property var albums: []
    property var artists: []
    property var songs: []
    property var tracks: []
    property var favorites: []

    property int songPageSize: 500
    property int songOffset: 0

    property string currentCollectionTitle: ""
    property var queue: []
    property int currentIndex: -1
    property var currentTrack: null
    property bool playing: false
    property bool shuffleEnabled: true
    property real position: 0
    property real duration: 0
    property bool currentTrackFavorite: currentTrack !== null && favorites.some(item => item.id === currentTrack.id)

    function normalizeArray(value) {
        if (value === undefined || value === null) return [];
        return Array.isArray(value) ? value : [value];
    }

    function decorate(items, type) {
        return normalizeArray(items).map(item => {
            item.itemType = type;
            return item;
        });
    }

    function authQuery() {
        return "u=" + encodeURIComponent(username)
            + "&t=" + encodeURIComponent(token)
            + "&s=" + encodeURIComponent(salt)
            + "&v=" + encodeURIComponent(apiVersion)
            + "&c=" + encodeURIComponent(clientName)
            + "&f=json";
    }

    function endpoint(name, params) {
        let query = authQuery();
        for (const key in params) {
            query += "&" + encodeURIComponent(key) + "=" + encodeURIComponent(params[key]);
        }
        return server.replace(/\/$/, "") + "/rest/" + name + ".view?" + query;
    }

    function coverUrl(id) {
        if (!ready || id === undefined || id === null || String(id).length === 0) return "";
        return endpoint("getCoverArt", { id: id, size: 420 });
    }

    function streamUrl(id) {
        return endpoint("stream", { id: id });
    }

    function refresh() {
        if (!ready) return;
        loading = true;
        statusText = "Refreshing library...";
        fetchProc(playlistsProc, endpoint("getPlaylists", {}));
        fetchProc(albumsProc, endpoint("getAlbumList2", { type: "recent", size: 36 }));
        fetchProc(artistsProc, endpoint("getArtists", {}));
        fetchProc(favoritesProc, endpoint("getStarred2", {}));
        loadSongs();
    }

    function loadSongs() {
        songs = [];
        songOffset = 0;
        fetchSongsPage();
    }

    function fetchSongsPage() {
        fetchProc(songsProc, endpoint("search3", { query: "", songCount: songPageSize, songOffset: songOffset, albumCount: 0, artistCount: 0 }));
    }

    function openPlaylist(id, title) {
        if (!ready) return;
        currentCollectionTitle = title;
        contentProc.requestType = "playlist";
        fetchProc(contentProc, endpoint("getPlaylist", { id: id }));
    }

    function openAlbum(id, title) {
        if (!ready) return;
        currentCollectionTitle = title;
        contentProc.requestType = "album";
        fetchProc(contentProc, endpoint("getAlbum", { id: id }));
    }

    function openArtist(id, title) {
        if (!ready) return;
        currentCollectionTitle = title;
        contentProc.requestType = "artist";
        fetchProc(contentProc, endpoint("getArtist", { id: id }));
    }

    function playCurrentTracks(index) {
        if (tracks.length === 0) return;
        playTracks(tracks, currentCollectionTitle, index ?? 0);
    }

    function playTracks(trackList, title, index) {
        const normalized = normalizeArray(trackList);
        const startIndex = Math.max(0, Math.min(normalized.length - 1, index ?? 0));

        let orderedQueue = [];
        if (shuffleEnabled) {
            const selected = normalized[startIndex];
            const rest = normalized.filter((_, i) => i !== startIndex);
            for (let i = rest.length - 1; i > 0; i--) {
                const j = Math.floor(Math.random() * (i + 1));
                [rest[i], rest[j]] = [rest[j], rest[i]];
            }
            orderedQueue = [selected].concat(rest);
        } else {
            orderedQueue = normalized.slice(startIndex);
        }

        queue = orderedQueue.slice(0, 200);
        currentCollectionTitle = title;

        if (queue.length === 0) return;

        playTrack(queue[0]);
        ensureMpv();

        let batch = "";
        for (let i = 0; i < queue.length; i++) {
            const mode = i === 0 ? "replace" : "append";
            batch += "{\"command\":[\"loadfile\",\"" + jsonEscape(streamUrl(queue[i].id)) + "\",\"" + mode + "\"]}";
            if (i < queue.length - 1) batch += "\n";
        }

        pendingIpcCommand = batch;
        mpvReadyTimer.restart();
    }

    function playTrack(track) {
        if (!track || !track.id) return;
        currentTrack = track;
        currentIndex = queue.findIndex(t => t.id === track.id);
        duration = Number(track.duration) || 0;
        position = 0;
        playing = true;
    }

    function togglePause() {
        if (!currentTrack) return;
        sendIpc("{\"command\":[\"cycle\",\"pause\"]}");
        playing = !playing;
    }

    function stop() {
        sendIpc("{\"command\":[\"stop\"]}\n{\"command\":[\"playlist-clear\"]}");
        currentTrack = null;
        playing = false;
        position = 0;
    }

    function next() {
        if (queue.length === 0) return;
        sendIpc("{\"command\":[\"playlist-next\",\"force\"]}");
    }

    function adjustVolume(delta) {
        sendIpc("{\"command\":[\"add\",\"volume\"," + delta + "]}");
    }

    function toggleShuffle() {
        shuffleEnabled = !shuffleEnabled;
    }

    function toggleCurrentFavorite() {
        if (!ready || !currentTrack || !currentTrack.id || favoriteProc.running) return;
        fetchProc(favoriteProc, endpoint(currentTrackFavorite ? "unstar" : "star", { id: currentTrack.id }));
    }

    function previous() {
        if (queue.length === 0) return;
        if (position > 4) {
            sendIpc("{\"command\":[\"seek\",0,\"absolute\"]}");
            position = 0;
            return;
        }
        if (currentIndex <= 0) return;
        sendIpc("{\"command\":[\"playlist-prev\",\"force\"]}");
    }

    function ensureMpv() {
        if (!mpvProc.running) mpvProc.running = true;
    }

    property string pendingIpcCommand: ""

    function jsonEscape(value) {
        return String(value).replace(/\\/g, "\\\\").replace(/\"/g, "\\\"");
    }

    function sendIpc(payload) {
        if (payload.length === 0) return;
        if (!mpvProc.running) mpvProc.running = true;
        ipcProc.command = ["bash", "-lc", "printf '%s\\n' \"$1\" | timeout 1s nc -U \"$2\" >/dev/null 2>&1", "mpvipc", payload, socketPath];
        ipcProc.running = true;
    }

    function fetchProc(proc, url) {
        proc.command = ["curl", "-fsS", url];
        proc.running = true;
    }

    function responseObject(text) {
        const parsed = JSON.parse(text);
        return parsed["subsonic-response"] ?? {};
    }

    readonly property var _configProc: Process {
        id: configProc
        command: ["cat", root.configPath]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const cfg = JSON.parse(this.text.trim());
                    root.server = cfg.server ?? root.server;
                    root.username = cfg.username ?? "";
                    root.salt = cfg.salt ?? "";
                    root.token = cfg.token ?? "";
                    root.ready = root.username.length > 0 && root.salt.length > 0 && root.token.length > 0;
                    root.errorMessage = root.ready ? "" : "Missing Navidrome credentials";
                    root.statusText = root.ready ? "Connected to Navidrome" : root.errorMessage;
                    if (root.ready) root.refresh();
                } catch (e) {
                    root.ready = false;
                    root.errorMessage = "Invalid Navidrome config";
                    root.statusText = root.errorMessage;
                }
            }
        }
    }

    readonly property var _playlistsProc: Process {
        id: playlistsProc
        running: false
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const response = root.responseObject(this.text);
                    root.playlists = root.decorate(response.playlists?.playlist, "playlist");
                } catch (e) {
                    root.errorMessage = "Could not load playlists";
                }
            }
        }
    }

    readonly property var _albumsProc: Process {
        id: albumsProc
        running: false
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const response = root.responseObject(this.text);
                    root.albums = root.decorate(response.albumList2?.album, "album");
                } catch (e) {
                    root.errorMessage = "Could not load albums";
                }
            }
        }
    }

    readonly property var _artistsProc: Process {
        id: artistsProc
        running: false
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const response = root.responseObject(this.text);
                    let result = [];
                    for (const index of root.normalizeArray(response.artists?.index)) {
                        result = result.concat(root.normalizeArray(index.artist));
                    }
                    root.artists = root.decorate(result, "artist");
                    root.loading = false;
                    root.statusText = "Library ready";
                } catch (e) {
                    root.errorMessage = "Could not load artists";
                }
            }
        }
    }

    readonly property var _contentProc: Process {
        id: contentProc
        property string requestType: ""
        running: false
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const response = root.responseObject(this.text);
                    if (contentProc.requestType === "playlist") {
                        root.tracks = root.decorate(response.playlist?.entry, "song");
                    } else if (contentProc.requestType === "album") {
                        root.tracks = root.decorate(response.album?.song, "song");
                    } else if (contentProc.requestType === "artist") {
                        const artistAlbums = root.normalizeArray(response.artist?.album);
                        if (artistAlbums.length > 0) root.openAlbum(artistAlbums[0].id, root.currentCollectionTitle + " - " + artistAlbums[0].name);
                        else root.tracks = [];
                    }
                    if (contentProc.requestType !== "artist") root.statusText = root.tracks.length + " tracks loaded";
                } catch (e) {
                    root.errorMessage = "Could not load selection";
                }
            }
        }
    }

    readonly property var _favoritesProc: Process {
        id: favoritesProc
        running: false
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const response = root.responseObject(this.text);
                    root.favorites = root.decorate(response.starred2?.song, "song");
                } catch (e) {
                    root.errorMessage = "Could not load favorites";
                }
            }
        }
    }

    readonly property var _favoriteProc: Process {
        id: favoriteProc
        running: false
        command: []
        onExited: fetchProc(favoritesProc, endpoint("getStarred2", {}))
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const response = root.responseObject(this.text);
                    if (response.status === "failed") root.errorMessage = response.error?.message ?? "Could not update favorite";
                } catch (e) {
                    root.errorMessage = "Could not update favorite";
                }
            }
        }
    }

    readonly property var _songsProc: Process {
        id: songsProc
        property var lastPage: []
        running: false
        command: []
        onExited: {
            if (lastPage.length === root.songPageSize) {
                root.songOffset += root.songPageSize;
                root.fetchSongsPage();
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const response = root.responseObject(this.text);
                    const page = root.decorate(response.searchResult3?.song, "song");
                    songsProc.lastPage = page;
                    root.songs = root.songs.concat(page);
                } catch (e) {
                    songsProc.lastPage = [];
                    root.errorMessage = "Could not load songs";
                }
            }
        }
    }

    readonly property var _mpvProc: Process {
        id: mpvProc
        command: ["bash", "-lc", "rm -f \"$1\"; exec mpv --no-video --force-window=no --idle=yes --input-ipc-server=\"$1\" --no-terminal", "mpv", root.socketPath]
        running: false
        onExited: root.playing = false
    }

    readonly property var _ipcProc: Process {
        id: ipcProc
        running: false
        command: []
    }

    readonly property var _statusProc: Process {
        id: statusProc
        running: false
        command: ["bash", "-lc", "printf '%s\\n%s\\n%s\\n%s\\n' '{\"command\":[\"get_property\",\"time-pos\"],\"request_id\":\"position\"}' '{\"command\":[\"get_property\",\"duration\"],\"request_id\":\"duration\"}' '{\"command\":[\"get_property\",\"pause\"],\"request_id\":\"pause\"}' '{\"command\":[\"get_property\",\"playlist-pos\"],\"request_id\":\"playlist\"}' | timeout 1s nc -U \"$1\" 2>/dev/null", "mpvstatus", root.socketPath]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                try {
                    const response = JSON.parse(data.trim());
                    if (response.request_id === "position" && typeof response.data === "number") root.position = response.data;
                    if (response.request_id === "duration" && typeof response.data === "number") root.duration = response.data;
                    if (response.request_id === "pause" && typeof response.data === "boolean") root.playing = !response.data;
                    if (response.request_id === "playlist" && typeof response.data === "number") {
                        if (response.data >= 0 && response.data < root.queue.length) {
                            root.currentIndex = response.data;
                            root.currentTrack = root.queue[response.data];
                            root.duration = Number(root.currentTrack.duration) || 0;
                        }
                    }
                } catch (e) {}
            }
        }
    }

    readonly property var _mpvReadyTimer: Timer {
        id: mpvReadyTimer
        interval: 500
        repeat: false
        onTriggered: {
            root.sendIpc(root.pendingIpcCommand);
            root.pendingIpcCommand = "";
        }
    }

    readonly property var _statusTimer: Timer {
        interval: 1000
        running: root.currentTrack !== null
        repeat: true
        onTriggered: if (!statusProc.running) statusProc.running = true
    }

    Component.onCompleted: configProc.running = true
}
