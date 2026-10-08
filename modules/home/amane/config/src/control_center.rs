// Control center opened from the bar's power button

use std::thread;
use std::time::Duration;

use amane::{
    Audio, Bluetooth, Brightness, Center, Column, Image, Key, LayerWindow, Link, Media, Monitor,
    Network, Parent, Rectangle, Row, Service, Stack, Start, Weight, Widget, children,
};

use crate::anim::{self, EFFECTS, SPRING_DEFAULT};
use crate::m3::{self, Grow, Variant};
use crate::notifications;
use crate::popups::{self, Anchor, Popup};
use crate::system::{self, NIGHT_LIGHT_TOGGLE, SystemState, Vpn, toggle_and_refresh};
use crate::theme::{Roles, SHAPE_L, SHAPE_XL, SHAPE_XLI, TYPE_LABEL, TYPE_TITLE, TYPE_TITLE_L, Theme};

const WIDTH: f32 = 520.0;
const PADDING: f32 = 16.0;
const INNER: f32 = WIDTH - 2.0 * PADDING;
const SPACING: f32 = 10.0;

#[derive(Default)]
pub struct ControlCenter {
    power_actions: bool,
}

impl Service for ControlCenter {
    fn new() -> Self {
        Self::default()
    }

    fn interval() -> Duration {
        Duration::from_secs(3600)
    }
}

pub fn reset() {
    ControlCenter::write().power_actions = false;
    thread::spawn(system::refresh);
}

fn run_action(command: &str) {
    popups::close();
    amane::spawn(command);
}

fn toggle_power_actions() {
    let mut state = ControlCenter::write();
    state.power_actions = !state.power_actions;
}

fn on_key(key: Key) {
    if key != Key::Escape {
        return;
    }

    if ControlCenter::read().power_actions {
        toggle_power_actions();
    } else {
        popups::close();
    }
}

pub fn view(monitor: &Monitor) -> LayerWindow {
    popups::window(monitor, Popup::ControlCenter, Anchor::TopRight, on_key, |context| {
        let roles = Theme::read().roles;
        let power_actions = ControlCenter::read().power_actions;

        let mut sections: Vec<Box<dyn Widget>> = vec![Box::new(header(&roles, power_actions))];

        // collapsible row of session actions
        let reveal = anim::float("control-center/actions", if power_actions { 1.0 } else { 0.0 }, SPRING_DEFAULT);
        if reveal > 0.01 {
            sections.push(Box::new(
                Rectangle::new()
                    .width(INNER)
                    .height(56.0 * reveal.max(0.0))
                    .clip()
                    .opacity(anim::float("control-center/actions-opacity", if power_actions { 1.0 } else { 0.0 }, EFFECTS))
                    .child(session_actions(&roles)),
            ));
        }

        sections.push(Box::new(tiles(&roles)));
        sections.push(Box::new(sliders(&roles)));
        sections.push(Box::new(media(&roles)));

        let column = Column::new(sections).width(INNER).gap(SPACING);
        let height = m3::height_of(&column) + 2.0 * PADDING;

        let content = Rectangle::new().width(Parent).height(Parent).padding(PADDING).child(column);

        m3::surface(
            &roles,
            (WIDTH, height),
            SHAPE_XLI,
            !context.top,
            if context.top { Grow::Top } else { Grow::Bottom },
            context.opened,
            content,
        )
    })
}

fn header(roles: &Roles, power_actions: bool) -> Row {
    let system = SystemState::read();

    let titles = Column::new(children![
        m3::label(system.day.clone(), TYPE_TITLE_L, roles.text_on_surface).weight(Weight::Bold),
        m3::label(system.date.clone(), TYPE_LABEL, roles.text_on_surface_variant),
    ])
    .width(Parent);

    let mut items: Vec<Box<dyn Widget>> = vec![Box::new(titles)];

    if let Some(percent) = system.battery {
        items.push(Box::new(m3::chip(roles, "battery_full", &format!("{percent}%"))));
    }

    items.push(Box::new(m3::icon_button(
        roles,
        "control-center/power",
        "power_settings_new",
        (40.0, 40.0),
        Variant::Error,
        true,
        power_actions,
        toggle_power_actions,
    )));

    Row::new(items).width(INNER).gap(8.0).align(Center)
}

fn session_actions(roles: &Roles) -> Row {
    let actions = [
        ("Lock", "lock", "lock-screen"),
        ("Logout", "logout", "niri msg action quit"),
        ("Reboot", "restart_alt", "systemctl reboot"),
        ("Shutdown", "power_settings_new", "systemctl poweroff"),
    ];
    let width = (INNER - 3.0 * 2.0) / 4.0;

    let mut buttons: Vec<Box<dyn Widget>> = Vec::new();

    for (index, (text, name, command)) in actions.into_iter().enumerate() {
        buttons.push(Box::new(m3::group_button(
            roles,
            &format!("control-center/action/{text}"),
            name,
            text,
            (width, 56.0),
            TYPE_LABEL,
            (index == 0, index == actions.len() - 1),
            move || run_action(command),
        )));
    }

    Row::new(buttons).gap(2.0)
}

fn tiles(roles: &Roles) -> Column {
    let width = (INNER - 8.0) / 2.0;

    let network = Network::read();
    let (name, title, subtitle) = match network.link() {
        Link::Offline => ("wifi_off", "Wi-Fi", String::from("Off")),
        Link::Wifi => ("wifi", "Wi-Fi", String::from(network.ssid())),
        Link::Wired | Link::Other => ("lan", "Ethernet", String::from("Connected")),
    };
    let wifi_enabled = network.wifi_enabled();
    let network_tile = m3::quick_tile(
        roles,
        "control-center/network",
        width,
        (name, title, &subtitle),
        network.link() != Link::Offline,
        move || Network::set_wifi(!wifi_enabled),
    );

    let powered = Bluetooth::read().powered();
    let bluetooth_tile = m3::quick_tile(
        roles,
        "control-center/bluetooth",
        width,
        (if powered { "bluetooth" } else { "bluetooth_disabled" }, "Bluetooth", if powered { "On" } else { "Off" }),
        powered,
        move || Bluetooth::set_powered(!powered),
    );

    let vpn = Vpn::read().connected;
    let vpn_tile = m3::quick_tile(
        roles,
        "control-center/vpn",
        width,
        ("shield_lock", "VPN", if vpn { "Connected" } else { "Off" }),
        vpn,
        || amane::spawn("toggle-nym"),
    );

    let system = SystemState::read();
    let dnd_tile = m3::quick_tile(
        roles,
        "control-center/dnd",
        width,
        ("do_not_disturb_on", "Do not disturb", if system.dnd { "On" } else { "Off" }),
        system.dnd,
        notifications::toggle_dnd,
    );
    let night_tile = m3::quick_tile(
        roles,
        "control-center/night-light",
        INNER,
        ("nightlight", "Night light", if system.night_light { "On" } else { "Off" }),
        system.night_light,
        || toggle_and_refresh(NIGHT_LIGHT_TOGGLE),
    );

    Column::new(children![
        Row::new(children![network_tile, bluetooth_tile]).gap(8.0),
        Row::new(children![vpn_tile, dnd_tile]).gap(8.0),
        night_tile,
    ])
    .gap(8.0)
}

fn sliders(roles: &Roles) -> Column {
    let audio = Audio::read();
    let volume = m3::slider(
        roles,
        "control-center/volume",
        (INNER, 36.0, 48.0),
        (f32::from(audio.volume()), audio.muted()),
        if audio.muted() { "volume_off" } else { "volume_up" },
        Some(Audio::toggle_mute),
        Audio::set_volume,
    );

    let brightness = m3::slider(
        roles,
        "control-center/brightness",
        (INNER, 36.0, 48.0),
        (f32::from(Brightness::read().percent()), false),
        "brightness_6",
        None,
        Brightness::set,
    );

    Column::new(children![volume, brightness]).gap(SPACING)
}

fn media(roles: &Roles) -> Rectangle {
    let media = Media::read();
    let player = media.active();

    let (title, artist) = match player {
        Some(player) => (player.title().to_owned(), player.artist().to_owned()),
        None => (String::from("No media"), String::from("Nothing playing")),
    };
    let playing = player.is_some_and(|player| player.playing());

    // only local cover art can be shown
    let cover_path = media.art_url().strip_prefix("file://").map(String::from);
    let has_cover = cover_path.as_deref().is_some_and(Image::loaded);

    let mut cover_layers: Vec<Box<dyn Widget>> = Vec::new();
    if !has_cover {
        cover_layers.push(Box::new(m3::centered(56.0, 56.0, m3::icon("music_note", 28.0, roles.text_on_surface_variant, false))));
    }
    if let Some(path) = cover_path {
        cover_layers.push(Box::new(
            Rectangle::new().width(56.0).height(56.0).radius(SHAPE_L).fill(Image::cover(path).thumbnail(136, 136)),
        ));
    }

    let cover = Rectangle::new()
        .width(56.0)
        .height(56.0)
        .radius(SHAPE_L)
        .fill(roles.surface_container_highest)
        .child(Stack::new(cover_layers).width(56.0).height(56.0));

    let titles = Column::new(children![
        m3::label(title, TYPE_TITLE, roles.text_on_surface).weight(Weight::Bold).elide(),
        m3::label(artist, TYPE_LABEL, roles.text_on_surface_variant).elide(),
    ])
    .width(Parent)
    .gap(2.0);

    let has_player = player.is_some();

    Rectangle::new()
        .width(INNER)
        .height(80.0)
        .radius(SHAPE_XL)
        .fill(roles.surface_container_high)
        .padding(14.0)
        .align_child(Start, Center)
        .child(
            Row::new(children![
                cover,
                titles,
                m3::icon_button(roles, "control-center/previous", "skip_previous", (40.0, 40.0), Variant::Standard, false, false, move || {
                    if has_player {
                        Media::previous();
                    }
                }),
                m3::icon_button(
                    roles,
                    "control-center/play",
                    if playing { "pause" } else { "play_arrow" },
                    (52.0, 52.0),
                    Variant::Filled,
                    true,
                    playing,
                    move || {
                        if has_player {
                            Media::play_pause();
                        }
                    },
                ),
                m3::icon_button(roles, "control-center/next", "skip_next", (40.0, 40.0), Variant::Standard, false, false, move || {
                    if has_player {
                        Media::next();
                    }
                }),
            ])
            .width(Parent)
            .gap(14.0)
            .align(Center),
        )
}
