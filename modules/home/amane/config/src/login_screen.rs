// Login prompt shared by the lock screen (lock.rs) and the greetd greeter (modules/nixos/desktop/amane-greeter)

use std::path::Path;
use std::thread;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use amane::{
    Center, Column, End, Image, Key, Padding, Parent, Rectangle, Service, Stack, Start, TextInput, Weight, Widget,
    children,
};

use crate::anim::{self, EFFECTS, SPRING_DEFAULT};
use crate::m3;
use crate::theme::{self, Roles, SHAPE_L, TYPE_LABEL, TYPE_LABEL_S, TYPE_TITLE, TYPE_TITLE_L};

pub const INPUT: &str = "login/answer";

const FIELD_WIDTH: f32 = 324.0;

// What the prompt asks and shows
pub struct Prompt<'a> {
    pub user: &'a str,
    // empty for a plain password
    pub question: &'a str,
    pub secret: bool,
    pub busy: bool,
    // (is an error, text)
    pub message: Option<(bool, &'a str)>,
}

pub fn on_key(key: Key) {
    if key == Key::Escape {
        TextInput::set_text(INPUT, "");
    }
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

// Blurred wallpaper under a veil of the surface color
pub fn backdrop(roles: &Roles, wallpaper: &str) -> Rectangle {
    Rectangle::new().width(Parent).height(Parent).fill(roles.surface).child(
        Rectangle::new()
            .width(Parent)
            .height(Parent)
            .fill(Image::cover(wallpaper).thumbnail(640, 360).blurred(6))
            .child(Rectangle::new().width(Parent).height(Parent).fill(theme::with_alpha(roles.surface, 0.35))),
    )
}

pub fn clock(roles: &Roles) -> Rectangle {
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

// Avatar and field centered on the screen, growing in from `opened`; `extra` goes under the status line
pub fn card(roles: &Roles, prompt: &Prompt, opened: Instant, on_submit: fn(String), extra: Option<Box<dyn Widget>>) -> Rectangle {
    let mut items: Vec<Box<dyn Widget>> = vec![
        Box::new(avatar(roles, prompt.user)),
        Box::new(field(roles, prompt, on_submit)),
        Box::new(status(roles, prompt.message)),
    ];
    items.extend(extra);

    Rectangle::new()
        .width(Parent)
        .height(Parent)
        .align_child(Center, Center)
        .opacity(anim::since(opened, EFFECTS).clamp(0.0, 1.0))
        .scale(0.9 + 0.1 * anim::since(opened, SPRING_DEFAULT))
        .child(Column::new(items).gap(16.0).align(Center))
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
fn field(roles: &Roles, prompt: &Prompt, on_submit: fn(String)) -> Rectangle {
    let question = if prompt.question.is_empty() { "Password" } else { prompt.question };

    let input = TextInput::new(INPUT)
        .size(TYPE_TITLE)
        .color(roles.text_on_surface)
        .width(FIELD_WIDTH - 16.0 - 56.0)
        .focused()
        .on_submit(on_submit);
    let input = if prompt.secret { input.password() } else { input };

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

    if prompt.busy {
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
fn status(roles: &Roles, message: Option<(bool, &str)>) -> Rectangle {
    let (color, text) = match message {
        Some((true, text)) => (roles.error, text),
        Some((false, text)) => (roles.text_on_surface_variant, text),
        None => (roles.text_on_surface_variant, ""),
    };

    Rectangle::new()
        .width(FIELD_WIDTH)
        .height(18.0)
        .align_child(Center, Center)
        .child(m3::label(text, TYPE_LABEL, color))
}
