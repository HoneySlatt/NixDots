// Login screen for greetd, built from the shell's theme and Material 3 components

// Shared with the shell (modules/home/amane/config/src), which uses more of them
#[allow(dead_code)]
mod anim;
#[allow(dead_code)]
mod icons;
#[allow(dead_code)]
mod m3;
#[allow(dead_code)]
mod theme;

mod greetd;
mod login;

use std::env;
use std::path::Path;
use std::sync::LazyLock;
use std::thread;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use amane::{
    App, Center, Column, End, Full, Image, Key, Keyboard, Layer, LayerWindow, Monitor, Padding, Parent, Rectangle,
    Row, Service, Stack, Start, TextInput, Weight, Widget, Zone, children,
};

use login::{INPUT, Login, Stage};
use m3::{Grow, Variant};
use theme::{Roles, SHAPE_L, SHAPE_XL, TYPE_LABEL, TYPE_LABEL_S, TYPE_TITLE, TYPE_TITLE_L, Theme};

const CARD_WIDTH: f32 = 380.0;
const CARD_PADDING: f32 = 28.0;
const FIELD_WIDTH: f32 = CARD_WIDTH - 2.0 * CARD_PADDING;

static OPENED: LazyLock<Instant> = LazyLock::new(Instant::now);

fn main() {
    // the greetd conversation starts before the first frame
    drop(Login::read());

    App::new().font(theme::FONT).window_per_monitor(view).run();
}

struct Clock {
    time: String,
    date: String,
}

impl Service for Clock {
    fn new() -> Self {
        Self { time: String::new(), date: String::new() }
    }

    // Wakes up once per minute, aligned on the minute change
    fn listen() {
        loop {
            {
                let mut clock = Self::write();
                clock.time = amane::output("date '+%I:%M %p'");
                clock.date = amane::output("date '+%A %d %B'");
            }

            let seconds = SystemTime::now().duration_since(UNIX_EPOCH).map_or(0, |elapsed| elapsed.as_secs());
            thread::sleep(Duration::from_secs(60 - seconds % 60));
        }
    }
}

// The login card goes on one output, the others only show the backdrop and clock
fn is_main(monitor: &Monitor) -> bool {
    env::var("AMANE_GREETER_OUTPUT").map_or(true, |output| output == monitor.name)
}

fn view(monitor: &Monitor) -> LayerWindow {
    let roles = Theme::read().roles;
    let main = is_main(monitor);

    let mut layers: Vec<Box<dyn Widget>> = vec![Box::new(backdrop(&roles)), Box::new(clock(&roles))];
    if main {
        layers.push(Box::new(Rectangle::new().width(Parent).height(Parent).align_child(Center, Center).child(card(&roles))));
        layers.push(Box::new(power(&roles)));
    }

    let window = LayerWindow::new()
        .width(Full)
        .height(Full)
        .layer(Layer::Overlay)
        .space(Zone::Ignore)
        .namespace("amane:greeter")
        .child(Stack::new(layers).width(Parent).height(Parent));

    if main { window.keyboard(Keyboard::Exclusive).on_key(on_key) } else { window }
}

fn on_key(key: Key) {
    if key == Key::Escape {
        TextInput::set_text(INPUT, "");
    }
}

// Blurred theme wallpaper under a veil of the surface color
fn backdrop(roles: &Roles) -> Rectangle {
    let wallpaper = format!("{}/wallpaper", theme::home());

    Rectangle::new().width(Parent).height(Parent).fill(roles.surface).child(
        Rectangle::new()
            .width(Parent)
            .height(Parent)
            .fill(Image::cover(wallpaper).thumbnail(640, 360).blurred(6))
            .child(Rectangle::new().width(Parent).height(Parent).fill(theme::with_alpha(roles.surface, 0.35))),
    )
}

fn clock(roles: &Roles) -> Rectangle {
    let clock = Clock::read();

    Rectangle::new()
        .width(Parent)
        .height(Parent)
        .padding(Padding { top: 96.0, right: 0.0, bottom: 0.0, left: 0.0 })
        .align_child(Center, Start)
        .child(
            Column::new(children![
                m3::label(clock.time.as_str(), 96.0, roles.text_on_surface).weight(Weight::Bold),
                m3::label(clock.date.as_str(), TYPE_TITLE_L, roles.text_on_surface_variant),
            ])
            .align(Center),
        )
}

fn card(roles: &Roles) -> Rectangle {
    let login = Login::read();

    let mut items: Vec<Box<dyn Widget>> = vec![
        Box::new(avatar(roles, &login.user)),
        Box::new(m3::label(login.full_name.as_str(), TYPE_TITLE_L, roles.text_on_surface).weight(Weight::Bold)),
        Box::new(field(roles, &login)),
        Box::new(status(roles, &login)),
    ];

    if let Some(session) = login.sessions.get(login.session) {
        let next = (login.sessions.len() > 1).then_some(login::next_session as fn());
        items.push(Box::new(m3::filter_chip(roles, "greeter/session", ("monitor", &session.name), false, next)));
    }

    let content = Column::new(items).gap(16.0).align(Center);
    let height = m3::height_of(&content) + 2.0 * CARD_PADDING;

    m3::surface(
        roles,
        (CARD_WIDTH, height),
        SHAPE_XL,
        false,
        Grow::Center,
        *OPENED,
        Rectangle::new().width(Parent).height(Parent).padding(CARD_PADDING).align_child(Center, Start).child(content),
    )
}

// AccountsService picture, or a person glyph in a primary container
fn avatar(roles: &Roles, user: &str) -> Rectangle {
    const SIZE: f32 = 112.0;

    let picture = format!("/var/lib/AccountsService/icons/{user}");
    let circle = Rectangle::new().width(SIZE).height(SIZE).radius(SIZE / 2.0).clip();

    if Path::new(&picture).exists() {
        circle.fill(Image::cover(picture).thumbnail(224, 224))
    } else {
        circle
            .fill(roles.primary_container)
            .align_child(Center, Center)
            .child(m3::icon("person", 56.0, roles.text_on_primary_container, true))
    }
}

// Filled text field like the network popup's: question on top, answer below
fn field(roles: &Roles, login: &Login) -> Rectangle {
    let busy = login.stage != Stage::Asking;
    let question = if login.question.is_empty() { "Password" } else { login.question.as_str() };

    let input = TextInput::new(INPUT)
        .size(TYPE_TITLE)
        .color(roles.text_on_surface)
        .width(FIELD_WIDTH - 16.0 - 56.0)
        .focused()
        .on_submit(login::submit);
    let input = if login.secret { input.password() } else { input };

    let mut layers: Vec<Box<dyn Widget>> = vec![
        Box::new(
            Rectangle::new()
                .width(Parent)
                .height(Parent)
                .padding(Padding { top: 9.0, right: 0.0, bottom: 0.0, left: 16.0 })
                .child(m3::label(question, TYPE_LABEL_S, roles.primary).weight(Weight::Bold)),
        ),
        Box::new(
            Rectangle::new()
                .width(Parent)
                .height(Parent)
                .padding(Padding { top: 22.0, right: 56.0, bottom: 4.0, left: 16.0 })
                .align_child(Start, Center)
                .child(input),
        ),
    ];

    if busy {
        layers.push(Box::new(
            Rectangle::new()
                .width(Parent)
                .height(Parent)
                .padding(m3::horizontal(0.0, 16.0))
                .align_child(End, Center)
                .child(m3::loading_indicator(roles.primary, 24.0)),
        ));
    }

    Rectangle::new()
        .width(FIELD_WIDTH)
        .height(56.0)
        .radius(SHAPE_L)
        .fill(roles.surface_container_highest)
        .border(2.0, roles.primary)
        .child(Stack::new(layers).width(Parent).height(Parent))
}

// One line under the field, always reserved so the card never jumps
fn status(roles: &Roles, login: &Login) -> Rectangle {
    let (color, text) = match (&login.message, login.stage) {
        (Some((true, text)), _) => (roles.error, text.as_str()),
        (Some((false, text)), _) => (roles.text_on_surface_variant, text.as_str()),
        (None, Stage::Starting) => (roles.text_on_surface_variant, "Starting session"),
        (None, Stage::Connecting) => (roles.text_on_surface_variant, "Connecting to greetd"),
        (None, _) => (roles.text_on_surface_variant, ""),
    };

    Rectangle::new()
        .width(FIELD_WIDTH)
        .height(18.0)
        .align_child(Center, Center)
        .child(m3::label(text, TYPE_LABEL, color))
}

fn power(roles: &Roles) -> Rectangle {
    let reboot = m3::icon_button(roles, "greeter/reboot", "restart_alt", (56.0, 56.0), Variant::Tonal, false, false, || {
        amane::spawn("systemctl reboot")
    });
    let poweroff = m3::icon_button(roles, "greeter/poweroff", "power_settings_new", (56.0, 56.0), Variant::Error, false, false, || {
        amane::spawn("systemctl poweroff")
    });

    Rectangle::new()
        .width(Parent)
        .height(Parent)
        .padding(32.0)
        .align_child(End, End)
        .child(Row::new(children![reboot, poweroff]).gap(12.0))
}
