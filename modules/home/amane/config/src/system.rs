// Services behind the bar modules that amane does not provide itself

use std::fs;
use std::path::PathBuf;
use std::sync::LazyLock;
use std::thread;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use amane::{Bus, Link, Network, Service};

use crate::popups::{self, Popup};

pub struct Clock {
    pub text: String,
}

impl Service for Clock {
    fn new() -> Self {
        Self { text: String::new() }
    }

    // Wakes up once per minute, aligned on the minute change
    fn listen() {
        loop {
            Self::write().text = amane::output("date '+%I:%M %p\u{2003}-\u{2003}%a %d'");

            let seconds = SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .map(|elapsed| elapsed.as_secs())
                .unwrap_or(0);

            thread::sleep(Duration::from_secs(60 - seconds % 60));
        }
    }
}

pub const HOT_PERCENT: u8 = 95;

// Shared on/off phase for modules flashing at high load
pub struct Blink {
    pub on: bool,
}

impl Service for Blink {
    fn new() -> Self {
        Self { on: false }
    }

    fn interval() -> Duration {
        Duration::from_millis(500)
    }

    fn update(&mut self) -> bool {
        let load = Load::read();
        let hot = load.cpu >= HOT_PERCENT || load.ram >= HOT_PERCENT;
        drop(load);
        let on = hot && !self.on;
        let changed = on != self.on;

        self.on = on;
        changed
    }
}

// CPU, RAM and GPU temperature, sampled together every 2 seconds
pub struct Load {
    pub cpu: u8,
    pub ram: u8,
    pub gpu: u32,
    // /proc/stat counters of the last sample: idle plus iowait, and the total of the first 8 fields
    idle: u64,
    total: u64,
    hwmon: Option<PathBuf>,
}

fn cpu_counters() -> (u64, u64) {
    let stat = fs::read_to_string("/proc/stat").unwrap_or_default();
    let fields: Vec<u64> = stat.lines().next().unwrap_or_default().split_whitespace().skip(1).take(8).map(|field| field.parse().unwrap_or(0)).collect();

    let idle = fields.get(3).copied().unwrap_or(0) + fields.get(4).copied().unwrap_or(0);
    (idle, fields.iter().sum())
}

fn ram_percent() -> u8 {
    let meminfo = fs::read_to_string("/proc/meminfo").unwrap_or_default();
    let field = |name: &str| {
        meminfo.lines().find_map(|line| line.strip_prefix(name)?.split_whitespace().next()?.parse::<f64>().ok()).unwrap_or(0.0)
    };

    let total = field("MemTotal:");
    if total == 0.0 {
        return 0;
    }
    ((total - field("MemAvailable:")) / total * 100.0).round() as u8
}

impl Load {
    fn sample(&mut self) {
        let (idle, total) = cpu_counters();

        if self.total > 0 && total > self.total {
            let idle_since = idle.saturating_sub(self.idle) as f64;
            let total_since = (total - self.total) as f64;
            self.cpu = ((1.0 - idle_since / total_since) * 100.0).round() as u8;
        }
        (self.idle, self.total) = (idle, total);

        self.ram = ram_percent();

        self.gpu = self
            .hwmon
            .as_ref()
            .and_then(|path| fs::read_to_string(path).ok())
            .and_then(|text| text.trim().parse::<u32>().ok())
            .map_or(self.gpu, |millis| (millis as f32 / 1000.0).round() as u32);
    }
}

impl Service for Load {
    fn new() -> Self {
        let mut load = Self { cpu: 0, ram: 0, gpu: 0, idle: 0, total: 0, hwmon: amdgpu_hwmon() };
        load.sample();
        load
    }

    fn interval() -> Duration {
        Duration::from_secs(2)
    }

    fn update(&mut self) -> bool {
        let before = (self.cpu, self.ram, self.gpu);
        self.sample();
        before != (self.cpu, self.ram, self.gpu)
    }
}

// What the bar shows of the network, so signal jitter that keeps the same icon redraws nothing
#[derive(Clone, Copy, PartialEq)]
pub struct NetBar {
    pub link: Link,
    pub level: usize,
    pub weak: bool,
}

impl NetBar {
    fn read_now() -> Self {
        let network = Network::read();
        let strength = network.strength();

        Self { link: network.link(), level: usize::from(strength / 20).min(4), weak: strength < 25 }
    }
}

impl Service for NetBar {
    fn new() -> Self {
        Self::read_now()
    }

    fn listen() {
        poll(Duration::from_secs(1), || true, Self::read_now);
    }
}

fn amdgpu_hwmon() -> Option<PathBuf> {
    fs::read_dir("/sys/class/hwmon").ok()?.flatten().find_map(|entry| {
        let name = fs::read_to_string(entry.path().join("name")).ok()?;
        (name.trim() == "amdgpu").then(|| entry.path().join("temp1_input"))
    })
}

// Active only when the NymVPN tunnel is connected
#[derive(PartialEq)]
pub struct Vpn {
    pub connected: bool,
}

// The tunnel state word of `nym-vpnc status`, like Connected or Connecting
fn vpn_state() -> String {
    let output = std::process::Command::new("/run/current-system/sw/bin/nym-vpnc")
        .arg("status")
        .stderr(std::process::Stdio::null())
        .output()
        .map(|output| String::from_utf8_lossy(&output.stdout).into_owned())
        .unwrap_or_default();

    output
        .lines()
        .find_map(|line| line.strip_prefix("State: "))
        .and_then(|rest| rest.split(|letter: char| !letter.is_ascii_alphabetic()).next())
        .map(String::from)
        .unwrap_or_default()
}

// Reads the state, following a transition like Connecting until it settles
fn check_vpn() {
    loop {
        let state = vpn_state();
        let connected = state == "Connected";

        if connected != Vpn::read().connected {
            Vpn::write().connected = connected;
        }

        if !state.ends_with("ing") {
            return;
        }
        thread::sleep(Duration::from_secs(1));
    }
}

impl Service for Vpn {
    fn new() -> Self {
        Self { connected: false }
    }

    // NetworkManager announces the tunnel devices coming and going, the rest is a slow poll
    fn listen() {
        for signal in ["DeviceAdded", "DeviceRemoved", "StateChanged"] {
            thread::spawn(move || {
                for _ in Bus::system().signals("org.freedesktop.NetworkManager", signal) {
                    check_vpn();
                }
            });
        }

        loop {
            check_vpn();
            thread::sleep(Duration::from_secs(10));
        }
    }
}

// U+F009A notification, U+F009C none, U+F009B dnd-notification, U+F0A91 dnd-none
pub struct SwayncIcon {
    pub icon: char,
}

fn swaync_icon(alt: &str) -> char {
    match alt {
        "notification" | "inhibited-notification" => '\u{f009a}',
        "dnd-notification" | "dnd-inhibited-notification" => '\u{f009b}',
        "dnd-none" | "dnd-inhibited-none" => '\u{f0a91}',
        _ => '\u{f009c}',
    }
}

// The string value of a top-level key in a flat JSON line
fn json_string<'a>(line: &'a str, key: &str) -> Option<&'a str> {
    let start = line.find(&format!("\"{key}\":"))? + key.len() + 3;
    let rest = line[start..].trim_start().strip_prefix('"')?;
    rest.split('"').next()
}

impl Service for SwayncIcon {
    fn new() -> Self {
        Self { icon: swaync_icon("none") }
    }

    fn listen() {
        loop {
            for line in amane::lines("swaync-client -swb") {
                let icon = swaync_icon(json_string(&line, "alt").unwrap_or("none"));

                if icon != Self::read().icon {
                    Self::write().icon = icon;
                }
            }

            thread::sleep(Duration::from_secs(1));
        }
    }
}

pub static DISTRO_ICON: LazyLock<char> = LazyLock::new(distro_icon);

fn distro_icon() -> char {
    let release = fs::read_to_string("/etc/os-release").unwrap_or_default();
    let id = release
        .lines()
        .find_map(|line| line.strip_prefix("ID="))
        .unwrap_or_default()
        .trim_matches('"')
        .to_lowercase();

    match id.as_str() {
        "arch" => '\u{f303}',
        "nixos" => '\u{f1105}',
        "ubuntu" => '\u{f31b}',
        "debian" => '\u{f306}',
        "fedora" => '\u{f30a}',
        "manjaro" => '\u{f312}',
        "opensuse" => '\u{f314}',
        "gentoo" => '\u{f30d}',
        "void" => '\u{f32f}',
        "alpine" => '\u{f300}',
        "artix" => '\u{f31f}',
        "endeavouros" => '\u{f322}',
        "garuda" => '\u{f337}',
        "mint" => '\u{f30f}',
        "pop" => '\u{f32a}',
        "zorin" => '\u{f33f}',
        _ => '\u{f17c}',
    }
}

pub const NIGHT_LIGHT_TOGGLE: &str =
    "if pgrep -x wlsunset >/dev/null; then pkill wlsunset; else wlsunset -T 6001 -t 6000 >/dev/null 2>&1 & fi";

// Quick settings state, read while the control center or the power menu is open
#[derive(Default, PartialEq)]
pub struct SystemState {
    pub dnd: bool,
    pub night_light: bool,
    pub battery: Option<u8>,
    // NetworkManager name of the active Wi-Fi or Ethernet connection
    pub connection: String,
    pub day: String,
    pub date: String,
}

fn battery() -> Option<u8> {
    fs::read_dir("/sys/class/power_supply").ok()?.flatten().find_map(|entry| {
        let path = entry.path();
        let name = entry.file_name().to_string_lossy().into_owned();
        let kind = fs::read_to_string(path.join("type")).ok()?;

        if kind.trim() != "Battery" || name.starts_with("hidpp_") || name.starts_with("ps-controller-") {
            return None;
        }

        fs::read_to_string(path.join("capacity")).ok()?.trim().parse().ok()
    })
}

fn connection() -> String {
    amane::output("nmcli -t -f TYPE,STATE,CONNECTION device")
        .lines()
        .find_map(|line| {
            let mut parts = line.splitn(3, ':');
            let (kind, state, name) = (parts.next()?, parts.next()?, parts.next()?);
            (state == "connected" && (kind == "wifi" || kind == "ethernet")).then(|| String::from(name))
        })
        .unwrap_or_default()
}

impl SystemState {
    fn read_now() -> Self {
        Self {
            dnd: amane::output("swaync-client -D") == "true",
            night_light: !amane::output("pgrep -x wlsunset").is_empty(),
            battery: battery(),
            connection: connection(),
            day: amane::output("date +%A"),
            date: amane::output("date '+%-d %B'"),
        }
    }
}

pub fn refresh() {
    let state = SystemState::read_now();

    if state != *SystemState::read() {
        *SystemState::write() = state;
    }
}

// Runs a toggle command, then reads the new state back
pub fn toggle_and_refresh(command: &'static str) {
    thread::spawn(move || {
        amane::output(command);
        refresh();
    });
}

impl Service for SystemState {
    fn new() -> Self {
        Self::default()
    }

    fn listen() {
        let open = || popups::is_open(Popup::ControlCenter) || popups::is_open(Popup::PowerMenu);
        poll(Duration::from_secs(2), open, Self::read_now);
    }
}

const HISTORY_LENGTH: usize = 36;

// Last samples of each metric, for the system monitor graphs
#[derive(Default)]
pub struct History {
    pub cpu: Vec<f32>,
    pub gpu: Vec<f32>,
    pub ram: Vec<f32>,
}

fn push_sample(samples: &mut Vec<f32>, value: f32) {
    samples.push(value.clamp(0.0, 100.0));

    if samples.len() > HISTORY_LENGTH {
        samples.remove(0);
    }
}

impl Service for History {
    fn new() -> Self {
        Self::default()
    }

    fn interval() -> Duration {
        Duration::from_secs(2)
    }

    fn update(&mut self) -> bool {
        let load = Load::read();
        push_sample(&mut self.cpu, f32::from(load.cpu));
        push_sample(&mut self.gpu, load.gpu as f32);
        push_sample(&mut self.ram, f32::from(load.ram));
        true
    }
}

// Polls outside the Service lock, so slow commands never hold up a view that reads it
pub fn poll<S: Service + PartialEq>(interval: Duration, active: impl Fn() -> bool, read_now: impl Fn() -> S) {
    loop {
        thread::sleep(interval);

        if !active() {
            continue;
        }

        let fresh = read_now();

        if fresh != *S::read() {
            *S::write() = fresh;
        }
    }
}
