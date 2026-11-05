// Context menu of a tray item, read over DBusMenu

use std::thread;
use std::time::Duration;

use amane::{Argument, Bus, Center, Column, Key, LayerWindow, Monitor, Parent, Pointer, Rectangle, Row, Service, Start, Value, Weight, Widget, arguments, children};

use crate::anim::{self, EFFECTS};
use crate::m3::{self, Grow};
use crate::popups::{self, Anchor, Popup};
use crate::theme::{self, Roles, SHAPE_L, SHAPE_M, TYPE_BODY, Theme};

const MENU: &str = "com.canonical.dbusmenu";
const ROW_HEIGHT: f32 = 36.0;
const SEPARATOR_HEIGHT: f32 = 9.0;
const PADDING: f32 = 6.0;

#[derive(Clone, Copy, PartialEq)]
enum Toggle {
    None,
    Check(bool),
    Radio(bool),
}

#[derive(Clone)]
struct Entry {
    id: i32,
    label: String,
    enabled: bool,
    separator: bool,
    toggle: Toggle,
    children: Vec<Entry>,
}

// (ia{sv}av): id, properties, children
fn entry(layout: &Value) -> Option<Entry> {
    let fields = layout.list();
    let properties = fields.get(1)?;

    let flag = |name: &str| match properties.get(name) {
        Value::Bool(value) => *value,
        _ => true,
    };
    let state = properties.get("toggle-state").number() == 1.0;

    let entry = Entry {
        id: fields.first()?.number() as i32,
        // mnemonics are underlined in toolkits, here the marker is dropped
        label: properties.get("label").text().replace("__", "\u{0}").replace('_', "").replace('\u{0}', "_"),
        enabled: flag("enabled"),
        separator: properties.get("type").text() == "separator",
        toggle: match properties.get("toggle-type").text() {
            "checkmark" => Toggle::Check(state),
            "radio" => Toggle::Radio(state),
            _ => Toggle::None,
        },
        children: fields.get(2).map(Value::list).unwrap_or_default().iter().filter(|child| child.list().get(1).is_some_and(|props| !matches!(props.get("visible"), Value::Bool(false)))).filter_map(entry).collect(),
    };

    Some(entry)
}

#[derive(Default)]
pub struct TrayMenu {
    bus: String,
    path: String,
    // distance from the menu's right edge to the right of the screen
    pub margin: f32,
    entries: Vec<Entry>,
    // indices of the submenus opened from the root
    stack: Vec<usize>,
}

impl Service for TrayMenu {
    fn new() -> Self {
        Self::default()
    }

    fn interval() -> Duration {
        Duration::from_secs(3600)
    }
}

pub fn open(bus: String, path: String, margin: f32) {
    *TrayMenu::write() = TrayMenu { bus: bus.clone(), path: path.clone(), margin, entries: Vec::new(), stack: Vec::new() };
    popups::show(Popup::TrayMenu);

    thread::spawn(move || {
        let session = Bus::session();
        session.call(&bus, &path, MENU, "AboutToShow", &arguments![0]);
        let reply = session.call(&bus, &path, MENU, "GetLayout", &[Argument::Int(0), Argument::Int(-1), Argument::TextList(Vec::new())]);

        let entries = reply.list().get(1).and_then(entry).map(|root| root.children).unwrap_or_default();

        let mut menu = TrayMenu::write();
        if menu.bus == bus && menu.path == path {
            menu.entries = entries;
        }
    });
}

fn click(id: i32) {
    let (bus, path) = {
        let menu = TrayMenu::read();
        (menu.bus.clone(), menu.path.clone())
    };

    thread::spawn(move || {
        Bus::session().call(&bus, &path, MENU, "Event", &[Argument::Int(id), Argument::from("clicked"), Argument::Variant(Box::new(Argument::Int(0))), Argument::Unsigned(0)]);
    });
    popups::close();
}

fn back() {
    TrayMenu::write().stack.pop();
}

fn on_key(key: Key) {
    if key != Key::Escape {
        return;
    }

    if TrayMenu::read().stack.is_empty() {
        popups::close();
    } else {
        back();
    }
}

fn shown(menu: &TrayMenu) -> (Vec<Entry>, Option<String>) {
    let mut entries = &menu.entries;
    let mut title = None;

    for &index in &menu.stack {
        let Some(parent) = entries.get(index) else {
            break;
        };
        title = Some(parent.label.clone());
        entries = &parent.children;
    }

    (entries.clone(), title)
}

pub fn view(monitor: &Monitor) -> LayerWindow {
    let margin = TrayMenu::read().margin;

    popups::window(monitor, Popup::TrayMenu, Anchor::Right(margin), on_key, |context| {
        let roles = Theme::read().roles;
        let (entries, title) = shown(&TrayMenu::read());

        let toggles = entries.iter().any(|entry| entry.toggle != Toggle::None);
        let label_width = entries
            .iter()
            .map(|entry| m3::width_of(&m3::label(entry.label.clone(), TYPE_BODY, roles.text_on_surface)))
            .chain(title.iter().map(|title| m3::width_of(&m3::label(title.clone(), TYPE_BODY, roles.text_on_surface)) + 30.0))
            .fold(0.0, f32::max);
        let width = (label_width + 2.0 * 14.0 + if toggles { 30.0 } else { 0.0 } + 24.0).clamp(200.0, 360.0);
        let inner = width - 2.0 * PADDING;

        let mut rows: Vec<Box<dyn Widget>> = Vec::new();

        if let Some(title) = title {
            rows.push(Box::new(row(&roles, "tray-menu/back", inner, true, back, Row::new(children![
                m3::icon("chevron_left", 18.0, roles.text_on_surface_variant, false),
                m3::label(title, TYPE_BODY, roles.text_on_surface).weight(Weight::Bold).elide(),
            ]).width(Parent).gap(12.0).align(Center))));
            rows.push(Box::new(separator(&roles, inner)));
        }

        if entries.is_empty() {
            rows.push(Box::new(m3::centered(inner, ROW_HEIGHT, m3::label("Empty menu", TYPE_BODY, roles.text_on_surface_variant))));
        }

        for (index, entry) in entries.iter().enumerate() {
            if entry.separator {
                rows.push(Box::new(separator(&roles, inner)));
                continue;
            }
            rows.push(Box::new(entry_row(&roles, entry, index, inner, toggles)));
        }

        let column = Column::new(rows).width(inner);
        let height = m3::height_of(&column) + 2.0 * PADDING;

        let content = Rectangle::new().width(Parent).height(Parent).padding(PADDING).child(column);

        m3::surface(&roles, (width, height), SHAPE_L, false, if context.top { Grow::Top } else { Grow::Bottom }, context.opened, content)
    })
}

fn separator(roles: &Roles, width: f32) -> Rectangle {
    Rectangle::new()
        .width(width)
        .height(SEPARATOR_HEIGHT)
        .padding(m3::horizontal(8.0, 8.0))
        .align_child(Start, Center)
        .child(Rectangle::new().width(Parent).height(1.0).fill(roles.outline_variant))
}

fn row(roles: &Roles, key: &str, width: f32, enabled: bool, on_click: impl Fn() + 'static, content: Row) -> Rectangle {
    let hover = anim::float(&format!("{key}/hover"), if enabled && anim::hovered(key) { theme::STATE_HOVER } else { 0.0 }, EFFECTS);
    let hover_key = String::from(key);

    let row = Rectangle::new()
        .width(width)
        .height(ROW_HEIGHT)
        .radius(SHAPE_M)
        .fill(theme::with_alpha(roles.text_on_surface, hover))
        .padding(m3::horizontal(14.0, 10.0))
        .align_child(Start, Center)
        .opacity(if enabled { 1.0 } else { 0.38 })
        .on_hover(move |inside| anim::set_hovered(&hover_key, inside))
        .child(content);

    if enabled {
        row.cursor(Pointer).on_click(move |_| on_click())
    } else {
        row
    }
}

fn entry_row(roles: &Roles, entry: &Entry, index: usize, width: f32, toggles: bool) -> Rectangle {
    let mut items: Vec<Box<dyn Widget>> = Vec::new();

    if toggles {
        let icon = match entry.toggle {
            Toggle::Check(true) => Some("check"),
            Toggle::Radio(true) => Some("radio_button_checked"),
            Toggle::Radio(false) => Some("radio_button_unchecked"),
            _ => None,
        };
        items.push(Box::new(match icon {
            Some(icon) => m3::centered(18.0, 18.0, m3::icon(icon, 18.0, roles.primary, false)),
            None => Rectangle::new().width(18.0).height(18.0),
        }));
    }

    items.push(Box::new(m3::label(entry.label.clone(), TYPE_BODY, roles.text_on_surface).elide()));

    let submenu = !entry.children.is_empty();
    if submenu {
        items.push(Box::new(m3::icon("chevron_right", 18.0, roles.text_on_surface_variant, false)));
    }

    let id = entry.id;
    let on_click = move || {
        if submenu {
            TrayMenu::write().stack.push(index);
        } else {
            click(id);
        }
    };

    row(roles, &format!("tray-menu/{index}/{id}"), width, entry.enabled, on_click, Row::new(items).width(Parent).gap(12.0).align(Center))
}
