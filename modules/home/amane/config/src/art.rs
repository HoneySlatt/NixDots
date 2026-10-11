// Local path for an image url: remote images are downloaded once into the cache

use std::collections::hash_map::DefaultHasher;
use std::collections::{HashMap, HashSet};
use std::fs;
use std::hash::{Hash, Hasher};
use std::process::Command;
use std::sync::{LazyLock, Mutex, PoisonError};
use std::thread;

use amane::Service;

use crate::theme;

// oldest downloads are removed past this count
const KEEP: usize = 64;

static REQUESTED: LazyLock<Mutex<HashSet<String>>> = LazyLock::new(|| Mutex::new(HashSet::new()));

// Remote url -> downloaded file; a finished download redraws the windows that asked
#[derive(Default)]
pub struct Art {
    files: HashMap<String, String>,
}

impl Service for Art {
    fn new() -> Self {
        Self::default()
    }

    fn listen() {}
}

// None while a remote image is downloading or when it can't be fetched
pub fn path(url: &str) -> Option<String> {
    if let Some(path) = url.strip_prefix("file://") {
        return Some(String::from(path));
    }

    if !url.starts_with("https://") && !url.starts_with("http://") {
        return (!url.is_empty()).then(|| String::from(url));
    }

    if let Some(file) = Art::read().files.get(url) {
        return Some(file.clone());
    }

    if REQUESTED.lock().unwrap_or_else(PoisonError::into_inner).insert(String::from(url)) {
        let url = String::from(url);
        thread::spawn(move || {
            if let Some(file) = download(&url) {
                Art::write().files.insert(url, file);
            }
        });
    }

    None
}

fn download(url: &str) -> Option<String> {
    let dir = format!("{}/.cache/amane/art", theme::home());
    let mut hasher = DefaultHasher::new();
    url.hash(&mut hasher);
    let file = format!("{dir}/{:016x}", hasher.finish());

    if fs::metadata(&file).is_ok() {
        return Some(file);
    }

    fs::create_dir_all(&dir).ok()?;
    prune(&dir);

    // written aside first, so a half downloaded file is never shown
    let partial = format!("{file}.part");
    let fetched = Command::new("curl")
        .args(["-fsSL", "--proto", "=http,https", "--max-time", "20", "--max-filesize", "10M", "-o", &partial, url])
        .status()
        .is_ok_and(|status| status.success());

    if !fetched {
        let _ = fs::remove_file(&partial);
        return None;
    }

    fs::rename(&partial, &file).ok()?;
    Some(file)
}

fn prune(dir: &str) {
    let Ok(entries) = fs::read_dir(dir) else {
        return;
    };

    let mut files: Vec<_> = entries
        .flatten()
        .filter_map(|entry| Some((entry.metadata().ok()?.modified().ok()?, entry.path())))
        .collect();

    if files.len() < KEEP {
        return;
    }

    files.sort();
    for (_, path) in &files[..=files.len() - KEEP] {
        let _ = fs::remove_file(path);
    }
}
