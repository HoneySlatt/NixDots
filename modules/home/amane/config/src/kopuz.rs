// Client of the running Kopuz app, through grpcurl on the daemon socket it serves

use std::collections::HashSet;
use std::io::Write;
use std::process::{Command, Stdio};
use std::thread;
use std::time::{Duration, Instant};

use amane::Service;

use crate::popups::{self, Popup};

#[derive(Clone, Copy, PartialEq)]
pub enum Kind {
    Playlist,
    Album,
    Artist,
    Song,
}

#[derive(Clone, PartialEq)]
pub struct Item {
    pub kind: Kind,
    // playlist or album id, artist key, or track key
    pub id: String,
    pub title: String,
    pub subtitle: String,
    // "kopuz:<entity>:<id>#<version>" for art::path, empty without a picture
    pub art: String,
    // title and subtitle in lowercase, what the launcher search looks in
    pub search: String,
}

// Turns an optional ArtworkRef into an art url
const ART: &str = r##"(.artwork // null | if . then "kopuz:" + (.target | to_entries[0] | .key + ":" + .value) + "#" + (.version // "0" | tostring) else "" end)"##;

fn socket() -> String {
    format!("{}/kopuz/kopuzd.sock", std::env::var("XDG_RUNTIME_DIR").unwrap_or_default())
}

// One call; `filter` is a jq program turning the JSON reply into text. None when Kopuz is not running.
fn call(method: &str, request: &str, filter: &str) -> Option<String> {
    let mut grpcurl = Command::new("grpcurl")
        .args(["-unix", "-plaintext", "-connect-timeout", "1", "-d", "@", &socket(), &format!("kopuz.v1.Kopuz/{method}")])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .ok()?;

    // closed once written, so grpcurl knows the request is complete
    grpcurl.stdin.take()?.write_all(request.as_bytes()).ok()?;

    let output = Command::new("jq").args(["-r", filter]).stdin(grpcurl.stdout.take()?).stderr(Stdio::null()).output().ok()?;
    let status = grpcurl.wait().ok()?;

    (status.success() && output.status.success()).then(|| String::from_utf8_lossy(&output.stdout).into_owned())
}

fn quote(text: &str) -> String {
    format!("\"{}\"", text.replace('\\', "\\\\").replace('"', "\\\""))
}

fn items(method: &str, request: &str, filter: &str, kind: Kind) -> Option<Vec<Item>> {
    let output = call(method, request, filter)?;

    Some(
        output
            .lines()
            .filter_map(|line| {
                let fields: Vec<&str> = line.split('\t').collect();
                let [id, title, subtitle, art] = fields[..] else {
                    return None;
                };
                let search = format!("{title} {subtitle}").to_lowercase();
                Some(Item { kind, id: id.into(), title: title.into(), subtitle: subtitle.into(), art: art.into(), search })
            })
            .collect(),
    )
}

fn songs(filter: &str) -> Option<Vec<Item>> {
    let request = format!(r#"{{"filter": {{{filter}}}, "page": {{"limit": 1000000}}}}"#);
    let jq = format!(
        r#".items[]? | [.key, (.title // "Unknown"), ([.artist, .album] | map(select(. != null and . != "")) | join(" - ")), {ART}] | @tsv"#
    );
    items("GetTracks", &request, &jq, Kind::Song)
}

// Playlists, albums, artists, songs and favorites, read again each time the launcher opens
#[derive(Default, PartialEq)]
pub struct Library {
    pub connected: bool,
    pub sections: [Vec<Item>; 5],
    // keys of the favorite songs, checked on every frame for the playing one
    favorites: HashSet<String>,
}

impl Library {
    fn read_now() -> Self {
        let playlists = items(
            "GetPlaylists",
            "{}",
            &format!(r#".playlists[]? | [.id, (.name // "Unknown"), "\(.trackKeys // [] | length) tracks", {ART}] | @tsv"#),
            Kind::Playlist,
        );
        let Some(playlists) = playlists else {
            return Self::default();
        };

        let albums = items(
            "GetAlbums",
            r#"{"limit": 1000000}"#,
            &format!(r#".albums[]? | [.id, (.title // "Unknown"), (.artist // "Album"), {ART}] | @tsv"#),
            Kind::Album,
        );
        let artists = items(
            "GetArtists",
            r#"{"limit": 1000000}"#,
            &format!(r#".artists[]? | [.key, (.name // "Unknown"), "\(.trackCount // 0) tracks", {ART}] | @tsv"#),
            Kind::Artist,
        );

        let favorites = songs(r#""favorite": true"#).unwrap_or_default();

        Self {
            connected: true,
            favorites: keys(&favorites),
            sections: [playlists, albums.unwrap_or_default(), artists.unwrap_or_default(), songs("").unwrap_or_default(), favorites],
        }
    }

    pub fn is_favorite(&self, key: &str) -> bool {
        self.favorites.contains(key)
    }
}

impl Service for Library {
    fn new() -> Self {
        Self::default()
    }

    fn listen() {}
}

fn keys(items: &[Item]) -> HashSet<String> {
    items.iter().map(|item| item.id.clone()).collect()
}

pub fn refresh_library() {
    let library = Library::read_now();

    if library != *Library::read() {
        *Library::write() = library;
    }
}

fn refresh_favorites() {
    let favorites = songs(r#""favorite": true"#);

    if let Some(favorites) = favorites {
        let mut library = Library::write();
        library.favorites = keys(&favorites);
        library.sections[4] = favorites;
    }
}

#[derive(Clone, Default, PartialEq)]
pub struct Track {
    pub key: String,
    pub title: String,
    pub artist: String,
    pub album: String,
    pub art: String,
}

// Playback state, polled while the music launcher is open
#[derive(Clone, Default, PartialEq)]
pub struct Player {
    pub connected: bool,
    pub track: Option<Track>,
    pub playing: bool,
    pub shuffle: bool,
    pub volume: f32,
    position: Duration,
    pub length: Duration,
    // when the position was read, to move it forward while playing
    read_at: Option<Instant>,
}

impl Player {
    fn read_now() -> Self {
        let filter = format!(
            r#"[.phase // "", (.queue.shuffle // false | tostring), (.volume // 0 | tostring),
               ((.position.ms // "0" | tonumber) + (if .position.playing then (.nowMs // "0" | tonumber) - (.position.atMs // "0" | tonumber) else 0 end) | tostring),
               (.row.durationMs // "0"), (.row.key // ""), (.row.title // ""), (.row.artist // ""), (.row.album // ""),
               (.row // {{}} | {ART})] | @tsv"#
        );
        let Some(output) = call("GetPlayerState", "{}", &filter) else {
            return Self::default();
        };

        let fields: Vec<&str> = output.trim_end_matches('\n').split('\t').collect();
        let [phase, shuffle, volume, position, length, key, title, artist, album, art] = fields[..] else {
            return Self { connected: true, ..Self::default() };
        };

        let milliseconds = |text: &str| Duration::from_millis(text.parse::<f64>().unwrap_or_default().max(0.0) as u64);

        Self {
            connected: true,
            track: (!key.is_empty()).then(|| Track {
                key: key.into(),
                title: title.into(),
                artist: artist.into(),
                album: album.into(),
                art: art.into(),
            }),
            playing: phase == "PHASE_PLAYING",
            shuffle: shuffle == "true",
            volume: volume.parse().unwrap_or_default(),
            position: milliseconds(position),
            length: milliseconds(length),
            read_at: Some(Instant::now()),
        }
    }

    pub fn position(&self) -> Duration {
        let moved = if self.playing { self.read_at.map(|at| at.elapsed()).unwrap_or_default() } else { Duration::ZERO };
        (self.position + moved).min(self.length)
    }
}

impl Service for Player {
    fn new() -> Self {
        Self::default()
    }

    fn listen() {
        loop {
            if popups::is_open(Popup::MusicLauncher) {
                refresh_player();
            }
            thread::sleep(Duration::from_secs(1));
        }
    }
}

fn refresh_player() {
    let player = Player::read_now();

    // the position always differs, so compare what is shown besides it
    let current = Player::read().clone();
    let changed = Player { position: Duration::ZERO, read_at: None, ..player.clone() }
        != Player { position: Duration::ZERO, read_at: None, ..current.clone() }
        || player.position.abs_diff(current.position()) > Duration::from_secs(2);

    if changed {
        *Player::write() = player;
    }
}

// Sends a command without blocking the caller, then shows its effect
fn command(method: &'static str, request: String) {
    thread::spawn(move || {
        call(method, &request, ".");
        refresh_player();
    });
}

pub fn toggle() {
    command("Toggle", String::from("{}"));
}

pub fn next() {
    command("Next", String::from("{}"));
}

pub fn previous() {
    command("Previous", String::from("{}"));
}

pub fn adjust_volume(delta: f32) {
    let volume = (Player::read().volume + delta).clamp(0.0, 1.0);
    // kept right away, so quick presses add up before Kopuz answers
    Player::write().volume = volume;
    command("SetVolume", format!(r#"{{"volume": {volume}}}"#));
}

pub fn toggle_shuffle() {
    let shuffle = !Player::read().shuffle;
    command("SetMode", format!(r#"{{"shuffle": {shuffle}}}"#));
}

pub fn toggle_favorite() {
    let Some(key) = Player::read().track.as_ref().map(|track| track.key.clone()) else {
        return;
    };
    let favorite = !Library::read().is_favorite(&key);

    thread::spawn(move || {
        call("SetFavorite", &format!(r#"{{"key": {}, "favorite": {favorite}}}"#, quote(&key)), ".");
        refresh_favorites();
    });
}

// Plays these songs in shuffle, starting with the one at `start`
pub fn play_songs(keys: &[String], start: usize) {
    let keys = keys.iter().map(|key| quote(key)).collect::<Vec<_>>().join(",");
    command(
        "SetQueue",
        format!(r#"{{"mode": "QUEUE_MODE_REPLACE", "context": {{"tracks": {{"keys": [{keys}]}}}}, "startIndex": {start}, "shuffle": true}}"#),
    );
}

// Plays a whole playlist, album or artist in shuffle
pub fn play_collection(item: &Item) {
    let context = match item.kind {
        Kind::Playlist => format!(r#"{{"playlist": {{"id": {}}}}}"#, quote(&item.id)),
        Kind::Album => format!(r#"{{"album": {{"id": {}}}}}"#, quote(&item.id)),
        Kind::Artist => format!(r#"{{"artistKey": {}}}"#, quote(&item.id)),
        Kind::Song => return,
    };
    command("SetQueue", format!(r#"{{"mode": "QUEUE_MODE_REPLACE", "context": {context}, "shuffle": true}}"#));
}

// Picture bytes for an art url without its "kopuz:" scheme ("album:<id>#<version>")
pub fn artwork(target: &str) -> Option<Vec<u8>> {
    let (entity, id) = target.split('#').next()?.split_once(':')?;
    let output = call("GetArtwork", &format!("{{{}: {}}}", quote(entity), quote(id)), ".data // empty")?;

    let bytes: Vec<u8> = output.lines().flat_map(decode_base64).collect();
    (!bytes.is_empty()).then_some(bytes)
}

// Each streamed chunk is its own padded base64 string
fn decode_base64(text: &str) -> Vec<u8> {
    let mut bytes = Vec::with_capacity(text.len() * 3 / 4);
    let (mut buffer, mut bits) = (0u32, 0);

    for character in text.bytes() {
        let value = match character {
            b'A'..=b'Z' => character - b'A',
            b'a'..=b'z' => character - b'a' + 26,
            b'0'..=b'9' => character - b'0' + 52,
            b'+' => 62,
            b'/' => 63,
            _ => continue,
        };

        buffer = (buffer << 6) | u32::from(value);
        bits += 6;

        if bits >= 8 {
            bits -= 8;
            bytes.push((buffer >> bits) as u8);
        }
    }

    bytes
}
