// Keyboard-driven power menu, toggled with Mod+P

use std::thread;
use std::time::Duration;

use amane::{
    Audio, Bluetooth, Brightness, Center, Column, Image, Key, LayerWindow, Link, Media, Monitor,
    Network, Padding, Parent, Rectangle, Row, Service, Stack, Start, Weight, Widget, children,
};

use crate::art;
use crate::m3::{self, Grow, Variant};
use crate::notifications;
use crate::popups::{self, Anchor, Popup};
use crate::system::{self, NIGHT_LIGHT_TOGGLE, SystemState, Vpn, toggle_and_refresh};
use crate::theme::{Roles, SHAPE_L, SHAPE_XL, SHAPE_XLI, TYPE_BODY, TYPE_HEADLINE, TYPE_LABEL, TYPE_TITLE, Theme};

const WIDTH: f32 = 720.0;
const PADDING: f32 = 20.0;
const INNER: f32 = WIDTH - 2.0 * PADDING;

const ENTRIES: usize = 14;
const VOLUME: usize = 4;
const BRIGHTNESS: usize = 5;

const LOGOUT: &str = "niri msg action quit";

#[derive(Default)]
pub struct PowerMenu {
    selected: usize,
}

impl Service for PowerMenu {
    fn new() -> Self {
        Self::default()
    }

    fn interval() -> Duration {
        Duration::from_secs(3600)
    }
}

pub fn reset() {
    PowerMenu::write().selected = 0;
    thread::spawn(system::refresh);
}

fn select(index: usize) {
    PowerMenu::write().selected = index.min(ENTRIES - 1);
}

fn run(command: &str) {
    amane::spawn(command);
    popups::close();
}

fn toggle_wifi() {
    let enabled = Network::read().wifi_enabled();
    Network::set_wifi(!enabled);
}

fn toggle_bluetooth() {
    let powered = Bluetooth::read().powered();
    Bluetooth::set_powered(!powered);
}

fn set_brightness(percent: i32) {
    Brightness::set(percent.clamp(0, 100) as u8);
}

fn set_volume(percent: i32) {
    Audio::set_volume(percent.clamp(0, 100) as u8);
}

fn trigger(index: usize) {
    match index {
        0 => toggle_wifi(),
        1 => toggle_bluetooth(),
        2 => amane::spawn("toggle-nym"),
        3 => notifications::toggle_dnd(),
        VOLUME => Audio::toggle_mute(),
        6 => Media::previous(),
        7 => Media::play_pause(),
        8 => Media::next(),
        9 => toggle_and_refresh(NIGHT_LIGHT_TOGGLE),
        10 => run("lock-screen"),
        11 => run(LOGOUT),
        12 => run("systemctl reboot"),
        13 => run("systemctl poweroff"),
        _ => {}
    }
}

// Left and right adjust the selected slider, or move the selection
fn horizontal(delta: i32) {
    let selected = PowerMenu::read().selected;

    match selected {
        VOLUME => set_volume(i32::from(Audio::read().volume()) + delta * 5),
        BRIGHTNESS => set_brightness(i32::from(Brightness::read().percent()) + delta * 5),
        _ => select(selected.saturating_add_signed(delta as isize)),
    }
}

fn on_key(key: Key) {
    let selected = PowerMenu::read().selected;

    match key {
        Key::Escape => popups::close(),
        Key::Enter => trigger(selected),
        Key::Down => select(selected + 1),
        Key::Up => select(selected.saturating_sub(1)),
        Key::Left => horizontal(-1),
        Key::Right => horizontal(1),
        Key::Character(letter) => match letter.to_ascii_lowercase() {
            's' => run("systemctl poweroff"),
            'r' => run("systemctl reboot"),
            'x' | 'e' => run(LOGOUT),
            'o' => run("lock-screen"),
            'm' => Audio::toggle_mute(),
            'n' => toggle_and_refresh(NIGHT_LIGHT_TOGGLE),
            'w' => toggle_wifi(),
            'b' => toggle_bluetooth(),
            'v' => amane::spawn("toggle-nym"),
            'd' => notifications::toggle_dnd(),
            'p' => Media::play_pause(),
            'j' => select(selected + 1),
            'k' => select(selected.saturating_sub(1)),
            'h' => horizontal(-1),
            'l' => horizontal(1),
            _ => {}
        },
        _ => {}
    }
}

// Selects the entry under the pointer
fn hover_select(index: usize, item: impl Widget + 'static) -> Rectangle {
    Rectangle::new()
        .width(m3::width_of(&item))
        .height(m3::height_of(&item))
        .on_hover(move |inside| {
            if inside {
                select(index);
            }
        })
        .child(item)
}

pub fn view(monitor: &Monitor) -> LayerWindow {
    popups::window(monitor, Popup::PowerMenu, Anchor::Modal, on_key, |context| {
        let roles = Theme::read().roles;
        let selected = PowerMenu::read().selected;

        let column = Column::new(children![
            header(&roles),
            tiles(&roles, selected),
            sliders(&roles, selected),
            media(&roles, selected),
            session(&roles, selected),
        ])
        .width(INNER)
        .gap(12.0);

        let height = m3::height_of(&column) + 48.0;

        let content = Rectangle::new()
            .width(Parent)
            .height(Parent)
            .padding(Padding { top: PADDING, right: PADDING, bottom: 0.0, left: PADDING })
            .child(column);

        m3::surface(&roles, (WIDTH, height), SHAPE_XLI, false, Grow::Center, context.opened, content)
    })
}

fn header(roles: &Roles) -> Row {
    let mut items: Vec<Box<dyn Widget>> = vec![Box::new(
        Rectangle::new()
            .width(Parent)
            .height(36.0)
            .align_child(Start, Center)
            .child(m3::label("Power", TYPE_HEADLINE, roles.text_on_surface).weight(Weight::Bold)),
    )];

    if let Some(percent) = SystemState::read().battery {
        items.push(Box::new(m3::chip(roles, "battery_full", &format!("{percent}%"))));
    }

    Row::new(items).width(INNER).align(Center)
}

fn tiles(roles: &Roles, selected: usize) -> Row {
    let width = (INNER - 3.0 * 8.0) / 4.0;

    let network = Network::read();
    let system = SystemState::read();
    let bluetooth = Bluetooth::read().powered();
    let vpn = Vpn::read().connected;

    let wifi_value = if !network.wifi_enabled() {
        String::from("Off")
    } else if !system.connection.is_empty() {
        system.connection.clone()
    } else {
        String::from(match network.link() {
            Link::Offline => "offline",
            Link::Wifi => "wifi",
            Link::Wired | Link::Other => "ethernet",
        })
    };

    let on_off = |on: bool| if on { "On" } else { "Off" };

    let entries = [
        ("wifi", "Wi-Fi", wifi_value.as_str(), network.wifi_enabled() && network.link() != Link::Offline),
        ("bluetooth", "Bluetooth", on_off(bluetooth), bluetooth),
        ("shield_lock", "VPN", on_off(vpn), vpn),
        ("do_not_disturb_on", "DND", on_off(system.dnd), system.dnd),
    ];

    let mut items: Vec<Box<dyn Widget>> = Vec::new();

    for (index, (name, title, value, active)) in entries.into_iter().enumerate() {
        let key = format!("power-menu/tile/{index}");
        let tile = m3::quick_tile(roles, &key, width, (name, title, value), active, move || trigger(index));
        let radius = if active { 20.0 } else { 30.0 };

        items.push(Box::new(hover_select(
            index,
            m3::ringed(roles, &key, tile, (radius, radius), selected == index),
        )));
    }

    Row::new(items).gap(8.0)
}

// Slider with a focus ring around its track
fn slider_entry(roles: &Roles, index: usize, slider: Rectangle, selected: usize) -> Rectangle {
    let ring = m3::focus_ring(
        roles,
        &format!("power-menu/slider/{index}"),
        (0.0, 6.0),
        (INNER, 36.0),
        (22.0, 22.0),
        selected == index,
    );

    hover_select(index, Stack::new(children![slider, ring]).width(INNER).height(48.0))
}

fn sliders(roles: &Roles, selected: usize) -> Column {
    let audio = Audio::read();

    let volume = m3::slider(
        roles,
        "power-menu/volume",
        (INNER, 36.0, 48.0),
        (f32::from(audio.volume()), audio.muted()),
        if audio.muted() { "volume_off" } else { "volume_up" },
        Some(Audio::toggle_mute),
        Audio::set_volume,
    );

    let brightness = m3::slider(
        roles,
        "power-menu/brightness",
        (INNER, 36.0, 48.0),
        (f32::from(Brightness::read().percent()), false),
        "brightness_6",
        None,
        Brightness::set,
    );

    Column::new(children![
        slider_entry(roles, VOLUME, volume, selected),
        slider_entry(roles, BRIGHTNESS, brightness, selected),
    ])
    .gap(12.0)
}

fn media(roles: &Roles, selected: usize) -> Rectangle {
    let media = Media::read();
    let player = media.active();

    let (title, artist) = match player {
        Some(player) if player.title().is_empty() => (String::from("Media"), player.artist().to_owned()),
        Some(player) => (player.title().to_owned(), player.artist().to_owned()),
        None => (String::from("No media"), String::from("Nothing playing")),
    };
    let playing = player.is_some_and(|player| player.playing());
    let night_light = SystemState::read().night_light;

    let cover_path = art::path(media.art_url());
    let has_cover = cover_path.as_deref().is_some_and(Image::loaded);

    let mut cover_layers: Vec<Box<dyn Widget>> = Vec::new();
    if !has_cover {
        cover_layers.push(Box::new(m3::centered(52.0, 52.0, m3::icon("music_note", 26.0, roles.text_on_surface_variant, false))));
    }
    if let Some(path) = cover_path {
        cover_layers.push(Box::new(
            Rectangle::new().width(52.0).height(52.0).radius(SHAPE_L).fill(Image::cover(path).thumbnail(120, 120)),
        ));
    }

    let cover = Rectangle::new()
        .width(52.0)
        .height(52.0)
        .radius(SHAPE_L)
        .fill(roles.surface_container_high)
        .child(Stack::new(cover_layers).width(52.0).height(52.0));

    let titles = Column::new(children![
        m3::label(title, TYPE_TITLE, roles.text_on_surface).weight(Weight::Bold).elide(),
        m3::label(artist, TYPE_LABEL, roles.text_on_surface_variant).elide(),
    ])
    .width(Parent)
    .gap(2.0);

    let buttons = [
        (6, "skip_previous", (48.0, 48.0), Variant::Tonal, false, false),
        (7, if playing { "pause" } else { "play_arrow" }, (72.0, 56.0), Variant::Filled, true, playing),
        (8, "skip_next", (48.0, 48.0), Variant::Tonal, false, false),
        (9, "nightlight", (48.0, 48.0), Variant::Tonal, true, night_light),
    ];

    let mut items: Vec<Box<dyn Widget>> = vec![Box::new(cover), Box::new(titles)];

    for (index, name, size, variant, toggle, checked) in buttons {
        let key = format!("power-menu/media/{index}");
        let button = m3::icon_button(roles, &key, name, size, variant, toggle, checked, move || trigger(index));
        let radius = size.1 * if toggle && checked { 0.3 } else { 0.5 };

        items.push(Box::new(hover_select(
            index,
            m3::ringed(roles, &key, button, (radius, radius), selected == index),
        )));
    }

    Rectangle::new()
        .width(INNER)
        .height(76.0)
        .radius(SHAPE_XL)
        .fill(roles.surface_container_highest)
        .padding(m3::horizontal(14.0, 16.0))
        .align_child(Start, Center)
        .child(Row::new(items).width(Parent).gap(14.0).align(Center))
}

fn session(roles: &Roles, selected: usize) -> Row {
    const HEIGHT: f32 = 52.0;

    let actions = [(10, "Lock", "lock"), (11, "Logout", "logout"), (12, "Reboot", "restart_alt"), (13, "Shutdown", "power_settings_new")];
    let width = (INNER - 3.0 * 2.0) / 4.0;

    let mut buttons: Vec<Box<dyn Widget>> = Vec::new();

    for (position, (index, text, name)) in actions.into_iter().enumerate() {
        let (first, last) = (position == 0, position == actions.len() - 1);
        let key = format!("power-menu/session/{index}");
        let button = m3::group_button(roles, &key, name, text, (width, HEIGHT), TYPE_BODY + 1.0, (first, last), move || {
            trigger(index)
        });

        let left = if first { HEIGHT / 2.0 } else { 8.0 };
        let right = if last { HEIGHT / 2.0 } else { 8.0 };

        buttons.push(Box::new(hover_select(
            index,
            m3::ringed(roles, &key, button, (left, right), selected == index),
        )));
    }

    Row::new(buttons).gap(2.0)
}
