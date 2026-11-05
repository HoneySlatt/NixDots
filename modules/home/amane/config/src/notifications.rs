// Notifications (replaces swaync): amane is the server, this draws the toasts and the notification center

use std::collections::HashSet;
use std::fs;
use std::thread;
use std::time::{Duration, SystemTime};

use amane::{
    Center, Column, Horizontal, Image, Key, Layer, LayerWindow, Margin, Monitor, Notification, Notifications, Parent,
    Rectangle, Row, ScrollArea, Service, Shadow, Start, Text, Urgency, Vertical, Weight, Widget, Zone, children,
};

use crate::m3::{self, Grow, Variant};
use crate::popups::{self, Anchor, Popup};
use crate::system;
use crate::theme::{
    self, FONT, MARGIN, POPUP_GAP, Roles, SHAPE_L, SHAPE_M, SHAPE_XL, TYPE_BODY, TYPE_LABEL, TYPE_LABEL_S, TYPE_TITLE,
    Theme,
};
use crate::tray;

const WIDTH: f32 = 380.0;
const PADDING: f32 = 12.0;
const INNER: f32 = WIDTH - 2.0 * PADDING;
const ICON: f32 = 40.0;
const CLOSE: f32 = 32.0;
const LIST_HEIGHT: f32 = 560.0;

const TOAST_TIME: Duration = Duration::from_secs(6);
const MAX_TOASTS: usize = 4;

fn dnd_file() -> String {
    format!("{}/.dnd-enabled", theme::config_dir())
}

pub fn dnd() -> bool {
    fs::read_to_string(dnd_file()).is_ok_and(|text| text.trim() == "true")
}

pub fn toggle_dnd() {
    let _ = fs::write(dnd_file(), if dnd() { "false\n" } else { "true\n" });
    system::refresh();
}

// Toasts closed by a click: they stay in the center
#[derive(Default)]
pub struct Toasts {
    hidden: HashSet<u32>,
}

impl Service for Toasts {
    fn new() -> Self {
        Self::default()
    }

    // Redraws while toasts are up, so expired ones go away
    fn listen() {
        let mut shown = false;

        loop {
            thread::sleep(Duration::from_millis(500));

            let now = !toasts().is_empty();
            if now || shown {
                drop(Self::write());
            }
            shown = now;
        }
    }
}

fn age(notification: &Notification) -> Duration {
    SystemTime::now().duration_since(notification.received()).unwrap_or_default()
}

// Newest first: recent ones, critical ones until closed; only critical ones while in do not disturb
fn toasts() -> Vec<u32> {
    let dnd = system::SystemState::read().dnd;
    let hidden = &Toasts::read().hidden;

    Notifications::read()
        .list()
        .iter()
        .rev()
        .filter(|notification| {
            let critical = notification.urgency() == Urgency::Critical;
            !hidden.contains(&notification.id()) && (critical || (!dnd && age(notification) < TOAST_TIME))
        })
        .map(Notification::id)
        .take(MAX_TOASTS)
        .collect()
}

fn hide_toast(id: u32) {
    Toasts::write().hidden.insert(id);
}

// Top right corner, under the bar when it is on top
fn toast_layer(height: f32) -> LayerWindow {
    LayerWindow::new()
        .width(WIDTH)
        .height(height)
        .anchor_vertical(Vertical::Top)
        .anchor_horizontal(Horizontal::Right)
        .margin(Margin { top: POPUP_GAP as i32, right: MARGIN, bottom: 0, left: 0 })
        .layer(Layer::Overlay)
        .space(Zone::Respect)
        .namespace("amane:toasts")
}

// Toasts show on the focused output only
pub fn toast_window(monitor: &Monitor) -> LayerWindow {
    let ids = toasts();
    let visible = !ids.is_empty()
        && !popups::is_open(Popup::Notifications)
        && popups::focused_output().is_none_or(|output| output == monitor.name);

    if !visible {
        return toast_layer(1.0).visible(false);
    }

    let roles = Theme::read().roles;
    let notifications = Notifications::read();
    let cards: Vec<Box<dyn Widget>> = ids
        .iter()
        .filter_map(|id| notifications.list().iter().find(|notification| notification.id() == *id))
        .map(|notification| -> Box<dyn Widget> { Box::new(card(&roles, notification, WIDTH, true)) })
        .collect();

    let column = Column::new(cards).gap(8.0);
    let height = m3::height_of(&column);

    toast_layer(height).child(column)
}

// Spec bodies may carry simple markup; shown as plain text
fn plain(text: &str) -> String {
    let mut plain = String::new();
    let mut in_tag = false;

    for character in text.chars() {
        match character {
            '<' => in_tag = true,
            '>' => in_tag = false,
            _ if !in_tag => plain.push(character),
            _ => {}
        }
    }

    plain.replace("&lt;", "<").replace("&gt;", ">").replace("&quot;", "\"").replace("&apos;", "'").replace("&amp;", "&")
}

fn time_ago(notification: &Notification) -> String {
    match age(notification).as_secs() {
        0..60 => String::from("now"),
        seconds @ 60..3600 => format!("{} min", seconds / 60),
        seconds @ 3600..86400 => format!("{} h", seconds / 3600),
        seconds => format!("{} d", seconds / 86400),
    }
}

// The sent image, the icon named by the sender, or the app's own icon;
// image and icon may each be a file, a file:// uri or an icon name
fn picture(notification: &Notification) -> Option<String> {
    [notification.image(), notification.icon(), &notification.app_name().to_lowercase()]
        .into_iter()
        .find_map(|name| tray::icon_file(name.strip_prefix("file://").unwrap_or(name), ""))
}

fn icon(roles: &Roles, notification: &Notification) -> Rectangle {
    let frame = Rectangle::new().width(ICON).height(ICON).radius(SHAPE_M).clip();

    match picture(notification) {
        Some(path) => frame.fill(Image::cover(path).thumbnail(80, 80)),
        None => frame
            .fill(roles.primary_container)
            .align_child(Center, Center)
            .child(m3::icon("notifications", 22.0, roles.text_on_primary_container, true)),
    }
}

// Wrapped text sized to its real height
fn paragraph(text: Text, width: f32) -> Rectangle {
    let height = text.height_in(width);
    Rectangle::new().width(width).height(height).child(text)
}

fn card(roles: &Roles, notification: &Notification, width: f32, toast: bool) -> Rectangle {
    let id = notification.id();
    let key = format!("notification/{id}{}", if toast { "/toast" } else { "" });
    let text_width = width - 2.0 * PADDING - ICON - CLOSE - 2.0 * PADDING;
    let critical = notification.urgency() == Urgency::Critical;

    let header = format!("{}  ·  {}", notification.app_name(), time_ago(notification));
    let mut lines: Vec<Box<dyn Widget>> =
        vec![Box::new(m3::label(header, TYPE_LABEL_S, roles.text_on_surface_variant).elide())];

    if !notification.summary().is_empty() {
        let summary = Text::new(plain(notification.summary()))
            .font(FONT)
            .size(TYPE_BODY + 1.0)
            .weight(Weight::Bold)
            .color(if critical { roles.error } else { roles.text_on_surface })
            .wrap()
            .max_lines(2);
        lines.push(Box::new(paragraph(summary, text_width)));
    }

    if !notification.body().is_empty() {
        let body = Text::new(plain(notification.body()))
            .font(FONT)
            .size(TYPE_BODY)
            .color(roles.text_on_surface_variant)
            .wrap()
            .max_lines(if toast { 3 } else { 5 });
        lines.push(Box::new(paragraph(body, text_width)));
    }

    if !notification.actions().is_empty() {
        let buttons: Vec<Box<dyn Widget>> = notification
            .actions()
            .iter()
            .map(|action| -> Box<dyn Widget> {
                let action_key = String::from(action.key());
                let label = action.label();
                let button_width = (m3::width_of(&m3::label(label, TYPE_BODY + 1.0, roles.primary)) + 32.0).min(text_width);
                Box::new(m3::text_button(roles, &format!("{key}/{action_key}"), label, button_width, Variant::Tonal, move || {
                    Notifications::invoke(id, &action_key);
                }))
            })
            .collect();
        lines.push(Box::new(Row::new(buttons).gap(8.0)));
    }

    let text = Column::new(lines).width(text_width).gap(2.0);
    let height = m3::height_of(&text).max(ICON) + 2.0 * PADDING;

    let close = m3::icon_button(roles, &format!("{key}/close"), "close", (CLOSE, CLOSE), Variant::Standard, false, false, move || {
        Notifications::dismiss(id)
    });

    let container = if toast { roles.surface } else { roles.surface_container_high };
    let card = m3::hoverable(Rectangle::new().width(width).height(height), &key)
        .radius(SHAPE_L)
        .fill(m3::state_color(&key, container, roles.text_on_surface))
        .padding(PADDING)
        .on_click(move |_| {
            hide_toast(id);
            Notifications::click(id);
        })
        .child(
            Row::new(children![icon(roles, notification), text, close])
                .width(Parent)
                .gap(PADDING)
                .align(Start),
        );

    let card = if critical { card.border(2.0, roles.error) } else { card };

    if toast { card.shadow(Shadow::drop(roles.shadow).blur(16.0).offset(0.0, 4.0)) } else { card }
}

fn on_key(key: Key) {
    if key == Key::Escape {
        popups::close();
    }
}

// The center lists everything, newest first
pub fn view(monitor: &Monitor) -> LayerWindow {
    popups::window(monitor, Popup::Notifications, Anchor::TopRight, on_key, |context| {
        let roles = Theme::read().roles;
        let notifications = Notifications::read();
        let dnd = system::SystemState::read().dnd;
        let count = notifications.list().len();

        let subtitle = match count {
            _ if dnd => String::from("Do not disturb"),
            0 => String::from("All caught up"),
            1 => String::from("1 notification"),
            count => format!("{count} notifications"),
        };

        let header = Row::new(children![
            Column::new(children![
                m3::label("Notifications", TYPE_TITLE, roles.text_on_surface).weight(Weight::Bold),
                m3::label(subtitle, TYPE_LABEL, roles.text_on_surface_variant),
            ])
            .width(Parent),
            m3::switch(&roles, "notifications/dnd", dnd, toggle_dnd),
            m3::icon_button(&roles, "notifications/clear", "clear_all", (40.0, 40.0), Variant::Standard, false, false, Notifications::clear),
        ])
        .width(INNER)
        .gap(12.0)
        .align(Center);

        let body: Box<dyn Widget> = if count == 0 {
            Box::new(
                Rectangle::new().width(INNER).height(160.0).align_child(Center, Center).child(
                    Column::new(children![
                        m3::icon("notifications_off", 32.0, roles.text_on_surface_variant, false),
                        m3::label("No notifications", TYPE_BODY, roles.text_on_surface_variant),
                    ])
                    .gap(8.0)
                    .align(Center),
                ),
            )
        } else {
            let cards: Vec<Box<dyn Widget>> = notifications
                .list()
                .iter()
                .rev()
                .map(|notification| -> Box<dyn Widget> { Box::new(card(&roles, notification, INNER, false)) })
                .collect();
            let list = Column::new(cards).width(INNER).gap(8.0);
            let height = m3::height_of(&list).min(LIST_HEIGHT);

            Box::new(ScrollArea::new("notifications/list", list).width(INNER).height(height))
        };

        let column = Column::new(vec![Box::new(header) as Box<dyn Widget>, body]).width(INNER).gap(12.0);
        let height = m3::height_of(&column) + 2.0 * PADDING;
        let content = Rectangle::new().width(Parent).height(Parent).padding(PADDING).child(column);

        m3::surface(
            &roles,
            (WIDTH, height),
            SHAPE_XL,
            !context.top,
            if context.top { Grow::Top } else { Grow::Bottom },
            context.opened,
            content,
        )
    })
}

// Bar glyph: U+F009A pending, U+F009C none, U+F009B pending in do not disturb, U+F0A91 none in do not disturb
pub fn bar_icon() -> char {
    let pending = !Notifications::read().list().is_empty();

    match (system::SystemState::read().dnd, pending) {
        (false, true) => '\u{f009a}',
        (false, false) => '\u{f009c}',
        (true, true) => '\u{f009b}',
        (true, false) => '\u{f0a91}',
    }
}
