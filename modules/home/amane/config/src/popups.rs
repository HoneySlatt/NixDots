use std::thread;
use std::time::{Duration, Instant};

use amane::{
    Align, Center, Color, End, Full, Key, Keyboard, Layer, LayerWindow, Monitor, Padding, Parent, Rectangle,
    Service, Start, Widget, Workspaces, Zone,
};

use crate::bar::Position;
use crate::theme::{MARGIN, POPUP_GAP};
use crate::{
    calendar, control_center, launcher, music_launcher, network_popup, notifications, power_menu, small_launcher,
    steam_launcher, system_monitor, theme_launcher, tray_menu, volume_popup, vpn_launcher, wallpaper_launcher,
};

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum Popup {
    AppLauncher,
    SmallLauncher,
    ControlCenter,
    PowerMenu,
    Volume,
    Network,
    SystemMonitor,
    Calendar,
    ThemeLauncher,
    WallpaperLauncher,
    SteamLauncher,
    VpnLauncher,
    MusicLauncher,
    TrayMenu,
    Notifications,
}

// One popup at a time, shown on the output that had focus when it opened
pub struct Popups {
    open: Option<Popup>,
    output: String,
    opened: Instant,
}

impl Service for Popups {
    fn new() -> Self {
        Self { open: None, output: String::new(), opened: Instant::now() }
    }

    // Closes the popup once another output takes focus
    fn listen() {
        loop {
            thread::sleep(Duration::from_millis(150));

            let focused = focused_output();
            let stale = {
                let popups = Self::read();
                popups.open.is_some() && focused.is_some_and(|output| output != popups.output)
            };

            if stale {
                close();
            }
        }
    }
}

pub fn focused_output() -> Option<String> {
    let workspaces = Workspaces::read();

    workspaces
        .list()
        .iter()
        .find(|workspace| workspace.focused())
        .and_then(|workspace| workspace.output())
        .map(String::from)
}

pub fn is_open(popup: Popup) -> bool {
    Popups::read().open == Some(popup)
}

// Whether the popup is open on this output
pub fn shown_on(popup: Popup, output: &str) -> bool {
    let popups = Popups::read();
    popups.open == Some(popup) && popups.output == output
}

pub fn toggle(popup: Popup) {
    if is_open(popup) {
        close();
    } else {
        show(popup);
    }
}

pub fn show(popup: Popup) {
    match popup {
        Popup::AppLauncher => launcher::reset(),
        Popup::SmallLauncher => small_launcher::reset(),
        Popup::ControlCenter => control_center::reset(),
        Popup::PowerMenu => power_menu::reset(),
        Popup::Volume => volume_popup::reset(),
        Popup::Network => network_popup::reset(),
        Popup::SystemMonitor => system_monitor::reset(),
        Popup::Calendar => calendar::reset(),
        Popup::ThemeLauncher => theme_launcher::reset(),
        Popup::WallpaperLauncher => wallpaper_launcher::reset(),
        Popup::SteamLauncher => steam_launcher::reset(),
        Popup::VpnLauncher => vpn_launcher::reset(),
        Popup::MusicLauncher => music_launcher::reset(),
        // filled in by tray_menu::open before showing
        Popup::TrayMenu => {}
        Popup::Notifications => {}
    }

    let output = focused_output().unwrap_or_default();

    let mut popups = Popups::write();
    popups.open = Some(popup);
    popups.output = output;
    popups.opened = Instant::now();
}

pub fn close() {
    Popups::write().open = None;
}

pub fn ipc_toggle(popup: Popup) -> String {
    toggle(popup);
    String::from(if is_open(popup) { "opened" } else { "closed" })
}

pub enum Anchor {
    TopLeft,
    TopRight,
    // under the bar at a fixed distance from the right edge
    Right(f32),
    // under the bar, centered horizontally
    Top,
    Center,
    // centered over a scrim that also covers the bar
    Modal,
    // the whole screen in one color, content laid out by the popup itself
    Cover(Color),
}

pub struct Context {
    pub opened: Instant,
    pub top: bool,
}

// Full-screen overlay that closes on a click outside its surface, drawn by the output's popup window
pub fn window<W: Widget + 'static>(
    monitor: &Monitor,
    popup: Popup,
    anchor: Anchor,
    on_key: impl Fn(Key) + 'static,
    build: impl FnOnce(&Context) -> W,
) -> LayerWindow {
    let (visible, opened) = {
        let popups = Popups::read();
        (popups.open == Some(popup) && popups.output == monitor.name, popups.opened)
    };

    let window = LayerWindow::new()
        .width(Full)
        .height(Full)
        .layer(Layer::Overlay)
        .namespace("amane:popup")
        .visible(visible);

    if !visible {
        return window;
    }

    let top = Position::read().top;
    let edge = if top { MARGIN as f32 } else { 0.0 };
    let gap = if top { POPUP_GAP } else { 0.0 };

    let backdrop = Rectangle::new().width(Parent).height(Parent).on_click(|_| close());

    let vertical: Align = if top { Start.into() } else { End.into() };

    let backdrop = match anchor {
        Anchor::TopLeft => backdrop
            .padding(Padding { top: gap, right: 0.0, bottom: 0.0, left: edge })
            .align_child(Start, vertical),
        Anchor::TopRight => backdrop
            .padding(Padding { top: gap, right: edge, bottom: 0.0, left: 0.0 })
            .align_child(End, vertical),
        Anchor::Right(margin) => backdrop
            .padding(Padding { top: gap, right: margin, bottom: 0.0, left: 0.0 })
            .align_child(End, vertical),
        Anchor::Top => backdrop
            .padding(Padding { top: gap, right: 0.0, bottom: 0.0, left: 0.0 })
            .align_child(Center, vertical),
        Anchor::Center => backdrop.align_child(Center, Center),
        Anchor::Modal => backdrop.fill(Color::rgba(0, 0, 0, 102)).align_child(Center, Center),
        Anchor::Cover(color) => backdrop.fill(color),
    };

    let window = match anchor {
        Anchor::Modal | Anchor::Cover(_) => window.space(Zone::Ignore),
        _ => window,
    };

    window
        .keyboard(Keyboard::Exclusive)
        .on_key(on_key)
        .child(backdrop.child(build(&Context { opened, top })))
}

// One window per output shows whichever popup is open, so the others cost nothing
pub fn view(monitor: &Monitor) -> LayerWindow {
    let open = Popups::read().open;

    match open {
        Some(Popup::AppLauncher) => launcher::view(monitor),
        Some(Popup::SmallLauncher) => small_launcher::view(monitor),
        Some(Popup::ControlCenter) => control_center::view(monitor),
        Some(Popup::PowerMenu) => power_menu::view(monitor),
        Some(Popup::Volume) => volume_popup::view(monitor),
        Some(Popup::Network) => network_popup::view(monitor),
        Some(Popup::SystemMonitor) => system_monitor::view(monitor),
        Some(Popup::Calendar) => calendar::view(monitor),
        Some(Popup::ThemeLauncher) => theme_launcher::view(monitor),
        Some(Popup::WallpaperLauncher) => wallpaper_launcher::view(monitor),
        Some(Popup::SteamLauncher) => steam_launcher::view(monitor),
        Some(Popup::VpnLauncher) => vpn_launcher::view(monitor),
        Some(Popup::MusicLauncher) => music_launcher::view(monitor),
        Some(Popup::TrayMenu) => tray_menu::view(monitor),
        Some(Popup::Notifications) => notifications::view(monitor),
        None => LayerWindow::new().width(Full).height(Full).layer(Layer::Overlay).namespace("amane:popup").visible(false),
    }
}

// Catches clicks on the other outputs while a popup is open
pub fn click_outside(monitor: &Monitor) -> LayerWindow {
    let visible = {
        let popups = Popups::read();
        popups.open.is_some() && popups.output != monitor.name
    };

    LayerWindow::new()
        .width(Full)
        .height(Full)
        .layer(Layer::Overlay)
        .space(Zone::Ignore)
        .namespace("amane:click-outside")
        .visible(visible)
        .child(Rectangle::new().width(Parent).height(Parent).on_click(|_| close()))
}
