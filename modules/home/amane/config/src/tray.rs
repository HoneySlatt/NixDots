// System tray: amane is the StatusNotifierWatcher, and the host that shows the items

use std::collections::HashMap;
use std::fs;
use std::path::PathBuf;
use std::sync::LazyLock;
use std::thread;

use amane::{Argument, Bus, Service, Value, arguments};

const WATCHER: &str = "org.kde.StatusNotifierWatcher";
const WATCHER_PATH: &str = "/StatusNotifierWatcher";
const ITEM: &str = "org.kde.StatusNotifierItem";
const PROPERTIES: &str = "org.freedesktop.DBus.Properties";
const INTROSPECTABLE: &str = "org.freedesktop.DBus.Introspectable";

// Tray icons use the kora icon theme
const ICON_THEMES: [&str; 2] = ["kora", "hicolor"];

const INTROSPECTION: &str = r#"<node>
  <interface name="org.kde.StatusNotifierWatcher">
    <method name="RegisterStatusNotifierItem"><arg name="service" type="s" direction="in"/></method>
    <method name="RegisterStatusNotifierHost"><arg name="service" type="s" direction="in"/></method>
    <property name="RegisteredStatusNotifierItems" type="as" access="read"/>
    <property name="IsStatusNotifierHostRegistered" type="b" access="read"/>
    <property name="ProtocolVersion" type="i" access="read"/>
    <signal name="StatusNotifierItemRegistered"><arg type="s"/></signal>
    <signal name="StatusNotifierItemUnregistered"><arg type="s"/></signal>
    <signal name="StatusNotifierHostRegistered"/>
  </interface>
</node>"#;

#[derive(Clone, PartialEq)]
pub struct TrayItem {
    // bus name and object path, as listed by the watcher
    pub key: String,
    pub bus: String,
    pub path: String,
    // the unique name the item's signals come from
    owner: String,
    pub icon: Option<String>,
    pub menu: Option<String>,
}

#[derive(Default)]
pub struct Tray {
    pub items: Vec<TrayItem>,
}

impl TrayItem {
    pub fn activate(&self) {
        self.call("Activate");
    }

    pub fn secondary_activate(&self) {
        self.call("SecondaryActivate");
    }

    fn call(&self, method: &'static str) {
        let (bus, path) = (self.bus.clone(), self.path.clone());
        thread::spawn(move || {
            Bus::session().call(&bus, &path, ITEM, method, &arguments![0, 0]);
        });
    }
}

fn read_item(bus: &str, path: &str) -> Option<TrayItem> {
    let session = Bus::session();
    let properties = session.call(bus, path, PROPERTIES, "GetAll", &arguments![ITEM]);

    if properties == Value::Nothing {
        return None;
    }

    let owner = if bus.starts_with(':') {
        String::from(bus)
    } else {
        String::from(session.call("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus", "GetNameOwner", &arguments![bus]).text())
    };

    let attention = properties.get("Status").text() == "NeedsAttention";
    let (name, pixmaps) = if attention && !properties.get("AttentionIconName").text().is_empty() {
        ("AttentionIconName", "AttentionIconPixmap")
    } else {
        ("IconName", "IconPixmap")
    };

    let icon = icon_file(properties.get(name).text(), properties.get("IconThemePath").text())
        .or_else(|| pixmap_file(properties.get(pixmaps).list()));

    let menu = properties.get("Menu").text();

    Some(TrayItem {
        key: format!("{bus}{path}"),
        bus: String::from(bus),
        path: String::from(path),
        owner,
        icon,
        menu: (!menu.is_empty() && menu != "/").then(|| String::from(menu)),
    })
}

// Adds or refreshes an item, keeping the registration order
fn store(item: TrayItem) {
    let mut tray = Tray::write();

    match tray.items.iter_mut().find(|known| known.key == item.key) {
        Some(known) if *known == item => {}
        Some(known) => *known = item,
        None => tray.items.push(item),
    }
}

fn add(bus: String, path: String) {
    thread::spawn(move || {
        if let Some(item) = read_item(&bus, &path) {
            store(item);
        }
    });
}

impl Service for Tray {
    fn new() -> Self {
        Self::default()
    }

    fn listen() {
        let session = Bus::session();

        // watched before taking the name, so the first registrations are not missed
        let calls = session.methods(WATCHER_PATH, WATCHER);
        let properties = session.methods(WATCHER_PATH, PROPERTIES);
        let introspection = session.methods(WATCHER_PATH, INTROSPECTABLE);

        // another tray already runs
        if !session.own(WATCHER) {
            return;
        }
        session.own(&format!("org.kde.StatusNotifierHost-{}", std::process::id()));

        thread::spawn(move || answer_properties(properties));
        thread::spawn(move || {
            for method in introspection {
                method.reply(&arguments![INTROSPECTION]);
            }
        });
        thread::spawn(follow_owners);
        for signal in ["NewIcon", "NewAttentionIcon", "NewStatus", "NewMenu"] {
            thread::spawn(move || follow_changes(signal));
        }

        for method in calls {
            let service = String::from(method.arguments().first().map(Value::text).unwrap_or_default());
            method.reply(&[]);

            match method.name() {
                "RegisterStatusNotifierItem" => {
                    // ayatana items register an object path, the others a bus name
                    let (bus, path) = if service.starts_with('/') {
                        (method.sender(), service)
                    } else {
                        (service, String::from("/StatusNotifierItem"))
                    };

                    session.emit(WATCHER_PATH, WATCHER, "StatusNotifierItemRegistered", &arguments![format!("{bus}{path}")]);
                    add(bus, path);
                }
                "RegisterStatusNotifierHost" => session.emit(WATCHER_PATH, WATCHER, "StatusNotifierHostRegistered", &[]),
                _ => {}
            }
        }
    }
}

fn registered() -> Vec<String> {
    Tray::read().items.iter().map(|item| item.key.clone()).collect()
}

fn answer_properties(calls: impl Iterator<Item = amane::Method>) {
    for method in calls {
        let value = |name: &str| match name {
            "RegisteredStatusNotifierItems" => Some(Argument::TextList(registered())),
            "IsStatusNotifierHostRegistered" => Some(Argument::Bool(true)),
            "ProtocolVersion" => Some(Argument::Int(0)),
            _ => None,
        };

        match method.name() {
            "Get" => {
                let name = method.arguments().get(1).map(Value::text).unwrap_or_default();
                match value(name) {
                    Some(value) => method.reply(&[Argument::Variant(Box::new(value))]),
                    None => method.reply(&[]),
                }
            }
            "GetAll" => {
                let all = ["RegisteredStatusNotifierItems", "IsStatusNotifierHostRegistered", "ProtocolVersion"]
                    .into_iter()
                    .filter_map(|name| Some((String::from(name), value(name)?)))
                    .collect();
                method.reply(&[Argument::Map(all)]);
            }
            _ => method.reply(&[]),
        }
    }
}

// Items leave with their program
fn follow_owners() {
    let session = Bus::session();

    for signal in session.signals("org.freedesktop.DBus", "NameOwnerChanged") {
        let arguments = signal.arguments();
        let (name, owner) = (arguments.first().map(Value::text).unwrap_or_default(), arguments.get(2).map(Value::text).unwrap_or_default());

        if !owner.is_empty() {
            continue;
        }

        let gone: Vec<String> = Tray::read()
            .items
            .iter()
            .filter(|item| item.bus == name || item.owner == name)
            .map(|item| item.key.clone())
            .collect();

        if gone.is_empty() {
            continue;
        }

        Tray::write().items.retain(|item| !gone.contains(&item.key));
        for key in gone {
            session.emit(WATCHER_PATH, WATCHER, "StatusNotifierItemUnregistered", &arguments![key]);
        }
    }
}

// Reads an item again when it announces a new icon, status or menu
fn follow_changes(signal: &'static str) {
    for change in Bus::session().signals(ITEM, signal) {
        let changed: Vec<(String, String)> = Tray::read()
            .items
            .iter()
            .filter(|item| item.owner == change.sender() && item.path == change.path())
            .map(|item| (item.bus.clone(), item.path.clone()))
            .collect();

        for (bus, path) in changed {
            if let Some(item) = read_item(&bus, &path) {
                store(item);
            }
        }
    }
}

// Every icon of the themes, by name, best file first: scalable, then the largest
static ICONS: LazyLock<HashMap<String, PathBuf>> = LazyLock::new(|| {
    let home = std::env::var("HOME").unwrap_or_default();
    let data_dirs = std::env::var("XDG_DATA_DIRS").unwrap_or_default();
    let roots: Vec<PathBuf> =
        std::iter::once(format!("{home}/.local/share")).chain(data_dirs.split(':').map(String::from)).map(PathBuf::from).collect();

    let mut icons: HashMap<String, (u32, u32, PathBuf)> = HashMap::new();

    for (rank, theme) in ICON_THEMES.iter().enumerate() {
        for root in &roots {
            walk(&root.join("icons").join(theme), &mut |path| {
                let Some((name, score)) = icon_entry(path) else {
                    return;
                };
                let entry = icons.entry(name).or_insert((u32::MAX, 0, PathBuf::new()));
                if (rank as u32, u32::MAX - score) < (entry.0, u32::MAX - entry.1) {
                    *entry = (rank as u32, score, path.to_path_buf());
                }
            });
        }
    }

    for root in &roots {
        walk(&root.join("pixmaps"), &mut |path| {
            if let Some((name, _)) = icon_entry(path) {
                icons.entry(name).or_insert((u32::MAX, 0, path.to_path_buf()));
            }
        });
    }

    icons.into_iter().map(|(name, (_, _, path))| (name, path)).collect()
});

fn walk(dir: &std::path::Path, visit: &mut dyn FnMut(&std::path::Path)) {
    let Ok(entries) = fs::read_dir(dir) else {
        return;
    };

    for entry in entries.flatten() {
        let path = entry.path();
        if path.is_dir() {
            walk(&path, visit);
        } else {
            visit(&path);
        }
    }
}

// The icon's name and how good the file is: svg first, then by pixel size
fn icon_entry(path: &std::path::Path) -> Option<(String, u32)> {
    let name = path.file_stem()?.to_str()?;
    let score = match path.extension()?.to_str()? {
        "svg" => 10_000,
        "png" => path
            .components()
            .filter_map(|part| part.as_os_str().to_str()?.split(['x', '@']).next()?.parse::<u32>().ok())
            .max()
            .unwrap_or(1),
        _ => return None,
    };

    Some((String::from(name), score))
}

fn icon_file(name: &str, theme_path: &str) -> Option<String> {
    if name.is_empty() {
        return None;
    }

    if name.starts_with('/') {
        return fs::metadata(name).is_ok().then(|| String::from(name));
    }

    // an icon shipped by the program itself
    if !theme_path.is_empty() {
        let mut found = None;
        walk(std::path::Path::new(theme_path), &mut |path| {
            if found.is_none() && icon_entry(path).is_some_and(|(stem, _)| stem == name) {
                found = Some(path.to_string_lossy().into_owned());
            }
        });
        if found.is_some() {
            return found;
        }
    }

    ICONS.get(name).map(|path| path.to_string_lossy().into_owned())
}

// The largest pixmap, written as a PNG that amane can show
fn pixmap_file(pixmaps: &[Value]) -> Option<String> {
    let pixmap = pixmaps.iter().max_by_key(|pixmap| {
        let fields = pixmap.list();
        fields.first().map_or(0.0, Value::number) as u64 * fields.get(1).map_or(0.0, Value::number) as u64
    })?;

    let fields = pixmap.list();
    let (width, height) = (fields.first()?.number() as u32, fields.get(1)?.number() as u32);
    let argb: Vec<u8> = fields.get(2)?.list().iter().map(|byte| byte.number() as u8).collect();

    if width == 0 || height == 0 || argb.len() < (width * height * 4) as usize {
        return None;
    }

    // network byte order ARGB to RGBA
    let rgba: Vec<u8> = argb.chunks_exact(4).flat_map(|pixel| [pixel[1], pixel[2], pixel[3], pixel[0]]).collect();

    let hash = rgba.iter().fold(0xcbf2_9ce4_8422_2325_u64, |hash, byte| (hash ^ u64::from(*byte)).wrapping_mul(0x100_0000_01b3));
    let dir = format!("{}/amane-tray", std::env::var("XDG_RUNTIME_DIR").unwrap_or_else(|_| String::from("/tmp")));
    let path = format!("{dir}/{hash:016x}.png");

    if fs::metadata(&path).is_err() {
        fs::create_dir_all(&dir).ok()?;
        fs::write(&path, png(width, height, &rgba)).ok()?;
    }

    Some(path)
}

fn crc32(bytes: &[u8]) -> u32 {
    !bytes.iter().fold(!0u32, |crc, &byte| {
        (0..8).fold(crc ^ u32::from(byte), |crc, _| if crc & 1 == 1 { (crc >> 1) ^ 0xedb8_8320 } else { crc >> 1 })
    })
}

// Uncompressed PNG: zlib stored blocks, one filter byte per row
fn png(width: u32, height: u32, rgba: &[u8]) -> Vec<u8> {
    let mut raw = Vec::with_capacity(rgba.len() + height as usize);
    for row in rgba.chunks_exact(width as usize * 4) {
        raw.push(0);
        raw.extend_from_slice(row);
    }

    let mut zlib = vec![0x78, 0x01];
    let blocks: Vec<&[u8]> = raw.chunks(65_535).collect();
    for (index, block) in blocks.iter().enumerate() {
        zlib.push(u8::from(index == blocks.len() - 1));
        let length = block.len() as u16;
        zlib.extend_from_slice(&length.to_le_bytes());
        zlib.extend_from_slice(&(!length).to_le_bytes());
        zlib.extend_from_slice(block);
    }
    let (a, b) = raw.iter().fold((1u32, 0u32), |(a, b), &byte| {
        let a = (a + u32::from(byte)) % 65_521;
        (a, (b + a) % 65_521)
    });
    zlib.extend_from_slice(&((b << 16) | a).to_be_bytes());

    let mut header = Vec::new();
    header.extend_from_slice(&width.to_be_bytes());
    header.extend_from_slice(&height.to_be_bytes());
    header.extend_from_slice(&[8, 6, 0, 0, 0]);

    let mut file = vec![0x89, b'P', b'N', b'G', 0x0d, 0x0a, 0x1a, 0x0a];
    for (kind, data) in [(b"IHDR", header), (b"IDAT", zlib), (b"IEND", Vec::new())] {
        let mut chunk = kind.to_vec();
        chunk.extend_from_slice(&data);
        file.extend_from_slice(&(data.len() as u32).to_be_bytes());
        file.extend_from_slice(&chunk);
        file.extend_from_slice(&crc32(&chunk).to_be_bytes());
    }

    file
}
