// NymVPN country picker: entry first, then exit, toggled with Mod+Ctrl+V

use std::thread;
use std::time::Duration;

use amane::{
    Center, Column, Key, LayerWindow, Monitor, Parent, Pointer, Rectangle, Row, Service, Start, Weight, Widget,
    children,
};

use crate::anim::{self, EFFECTS, SPRING_FAST};
use crate::m3::{self, Grow, Variant};
use crate::popups::{self, Anchor, Popup};
use crate::theme::{Roles, SHAPE_LI, SHAPE_M, SHAPE_XLI, SHAPE_XS, TYPE_BODY, TYPE_HEADLINE, TYPE_LABEL, Theme};

const WIDTH: f32 = 1040.0;
const HEIGHT: f32 = 680.0;
const INNER: f32 = WIDTH - 48.0;
const ROW_HEIGHT: f32 = 56.0;
const ROW_STEP: f32 = ROW_HEIGHT + 2.0;
const LIST_HEIGHT: f32 = HEIGHT - 48.0 - 48.0 - 32.0 - 48.0 - 16.0 - 4.0 * 16.0;

#[derive(Clone, PartialEq)]
struct Country {
    code: String,
    name: String,
    servers: u32,
    entry: bool,
    exit: bool,
}

// Gateway countries and the current tunnel, from the nym-countries script
#[derive(Default, PartialEq)]
pub struct Nodes {
    state: String,
    entry: String,
    exit: String,
    countries: Vec<Country>,
}

impl Nodes {
    fn read_now() -> Self {
        let output = amane::output(
            "nym-countries | jq -r '([.state, .entry, .exit] | @tsv), (.countries[] | [.code, .name, .servers, .entry, .exit] | @tsv)'",
        );
        let mut lines = output.lines();

        let mut nodes = Self::default();
        if let Some(header) = lines.next() {
            let fields: Vec<&str> = header.split('\t').collect();
            if let [state, entry, exit] = fields[..] {
                (nodes.state, nodes.entry, nodes.exit) = (String::from(state), String::from(entry), String::from(exit));
            }
        }

        nodes.countries = lines
            .filter_map(|line| {
                let fields: Vec<&str> = line.split('\t').collect();
                let [code, name, servers, entry, exit] = fields[..] else {
                    return None;
                };
                Some(Country {
                    code: String::from(code),
                    name: String::from(name),
                    servers: servers.parse().unwrap_or_default(),
                    entry: entry == "true",
                    exit: exit == "true",
                })
            })
            .collect();

        nodes
    }
}

fn refresh() {
    let nodes = Nodes::read_now();

    if nodes != *Nodes::read() {
        *Nodes::write() = nodes;
    }
}

impl Service for Nodes {
    fn new() -> Self {
        Self::default()
    }

    fn listen() {
        refresh();
    }
}

#[derive(Clone, Copy, PartialEq, Default)]
enum Step {
    #[default]
    Entry,
    Exit,
}

#[derive(Default)]
pub struct VpnLauncher {
    query: String,
    selected: usize,
    step: Step,
    // the entry country picked in the first step: code and name
    entry: Option<(String, String)>,
    scroll: f32,
}

impl Service for VpnLauncher {
    fn new() -> Self {
        Self::default()
    }

    fn interval() -> Duration {
        Duration::from_secs(3600)
    }
}

pub fn reset() {
    *VpnLauncher::write() = VpnLauncher::default();
    thread::spawn(refresh);
}

fn matching<'a>(countries: &'a [Country], query: &str) -> Vec<&'a Country> {
    let query = query.to_lowercase();
    countries
        .iter()
        .filter(|country| format!("{} {}", country.name, country.code).to_lowercase().contains(&query))
        .collect()
}

fn count() -> usize {
    let query = VpnLauncher::read().query.clone();
    matching(&Nodes::read().countries, &query).len()
}

// Selects a row and scrolls just enough to show it
fn select(index: usize) {
    let count = count();
    let mut state = VpnLauncher::write();

    state.selected = index.min(count.saturating_sub(1));

    let top = state.selected as f32 * ROW_STEP;
    state.scroll = state.scroll.min(top).max(top + ROW_HEIGHT - LIST_HEIGHT).max(0.0);
}

fn set_query(query: String) {
    let selected = {
        let mut state = VpnLauncher::write();
        state.query = query;
        state.selected
    };
    select(selected);
}

fn scroll_by(lines: f32) {
    let count = count();
    let mut state = VpnLauncher::write();
    state.scroll = (state.scroll + lines * 40.0).clamp(0.0, (count as f32 * ROW_STEP - 2.0 - LIST_HEIGHT).max(0.0));
}

// Picks the entry, then the exit; connecting takes a while, so the launcher closes right away
fn choose() {
    let (query, selected, step, entry) = {
        let state = VpnLauncher::read();
        (state.query.clone(), state.selected, state.step, state.entry.clone())
    };
    let Some(country) = matching(&Nodes::read().countries, &query).get(selected).map(|country| (*country).clone()) else {
        return;
    };

    match (step, entry) {
        (Step::Entry, _) => {
            let exit_index = Nodes::read().countries.iter().position(|country| country.exit).unwrap_or_default();
            {
                let mut state = VpnLauncher::write();
                state.entry = Some((country.code, country.name));
                state.step = Step::Exit;
                state.query.clear();
            }
            select(exit_index);
        }
        (Step::Exit, Some((entry, _))) => {
            amane::spawn(&format!("toggle-nym set {entry} {}", country.code));
            popups::close();
        }
        (Step::Exit, None) => {}
    }
}

fn disconnect() {
    amane::spawn("toggle-nym off");
    popups::close();
}

fn previous_step() {
    let entry = VpnLauncher::read().entry.clone();
    let Some((code, _)) = entry else {
        return;
    };

    let index = Nodes::read().countries.iter().position(|country| country.code == code).unwrap_or_default();
    {
        let mut state = VpnLauncher::write();
        state.step = Step::Entry;
        state.entry = None;
    }
    select(index);
}

fn on_key(key: Key) {
    let (query, selected, step) = {
        let state = VpnLauncher::read();
        (state.query.clone(), state.selected, state.step)
    };

    match key {
        Key::Escape => popups::close(),
        Key::Enter => choose(),
        Key::Delete => disconnect(),
        Key::Down | Key::Control('j') => select(selected + 1),
        Key::Up | Key::Control('k') => select(selected.saturating_sub(1)),
        Key::Backspace if query.is_empty() && step == Step::Exit => previous_step(),
        Key::Backspace => {
            let mut query = query;
            query.pop();
            set_query(query);
        }
        Key::Space => set_query(query + " "),
        Key::Character(letter) => set_query(format!("{query}{letter}")),
        _ => {}
    }
}

pub fn view(monitor: &Monitor) -> LayerWindow {
    popups::window(monitor, Popup::VpnLauncher, Anchor::Modal, on_key, |context| {
        let roles = Theme::read().roles;
        let nodes = Nodes::read();
        let state = VpnLauncher::read();
        let shown = matching(&nodes.countries, &state.query);

        let content = Rectangle::new().width(Parent).height(Parent).padding(24.0).child(
            Column::new(children![
                header(&roles, &nodes),
                steps(&roles, &state, shown.len()),
                search(&roles, &state),
                list(&roles, &shown, &state),
                Rectangle::new().width(INNER).height(16.0).align_child(Center, Center).child(m3::label(
                    "ctrl+j/k navigate   enter select   backspace back   del off   esc close",
                    TYPE_LABEL,
                    roles.outline,
                )),
            ])
            .width(INNER)
            .gap(16.0),
        );

        m3::surface(&roles, (WIDTH, HEIGHT), SHAPE_XLI, false, Grow::Center, context.opened, content)
    })
}

fn header(roles: &Roles, nodes: &Nodes) -> Row {
    let connected = nodes.state == "Connected";
    let or_random = |code: &str| if code.is_empty() { String::from("random") } else { String::from(code) };
    let state = if nodes.state.is_empty() { "Unknown" } else { &nodes.state };

    let bubble = Rectangle::new()
        .width(48.0)
        .height(48.0)
        .radius(anim::float("vpn/bubble", if connected { SHAPE_M } else { 24.0 }, SPRING_FAST))
        .fill(anim::color("vpn/bubble-color", if connected { roles.primary } else { roles.surface_container_highest }, EFFECTS))
        .align_child(Center, Center)
        .child(m3::icon("shield_lock", 28.0, if connected { roles.text_on_primary } else { roles.text_on_surface_variant }, false));

    let titles = Column::new(children![
        m3::label("NymVPN", TYPE_HEADLINE, roles.text_on_surface).weight(Weight::Bold),
        m3::label(
            format!("{state}  \u{2022}  {} \u{2192} {}", or_random(&nodes.entry), or_random(&nodes.exit)),
            TYPE_BODY,
            if connected { roles.primary } else { roles.text_on_surface_variant },
        ),
    ])
    .width(Parent)
    .gap(2.0);

    Row::new(children![
        bubble,
        titles,
        m3::button(roles, "vpn/disconnect", ("power_settings_new", "Disconnect"), 40.0, Variant::Error, disconnect),
    ])
    .width(INNER)
    .gap(16.0)
    .align(Center)
}

fn steps(roles: &Roles, state: &VpnLauncher, count: usize) -> Row {
    let exit_step = state.step == Step::Exit;
    let entry_text = match &state.entry {
        Some((_, name)) if exit_step => format!("Entry: {name}"),
        _ => String::from("Entry"),
    };

    Row::new(children![
        m3::filter_chip(roles, "vpn/entry", ("public", &entry_text), !exit_step, exit_step.then_some(previous_step as fn())),
        m3::icon("chevron_right", 18.0, roles.text_on_surface_variant, false),
        m3::filter_chip(roles, "vpn/exit", ("logout", "Exit"), exit_step, None),
        Rectangle::new().width(Parent).height(1.0),
        m3::label(format!("{count} countries"), TYPE_BODY, roles.text_on_surface_variant),
    ])
    .width(INNER)
    .height(32.0)
    .gap(8.0)
    .align(Center)
}

fn search(roles: &Roles, state: &VpnLauncher) -> Rectangle {
    let placeholder = if state.step == Step::Entry { "Search entry country" } else { "Search exit country" };
    let text = if state.query.is_empty() {
        m3::label(placeholder, TYPE_BODY + 1.0, roles.text_on_surface_variant)
    } else {
        m3::label(state.query.clone(), TYPE_BODY + 1.0, roles.text_on_surface)
    };

    m3::search_field(roles, INNER, text).fill(roles.surface_container_highest)
}

fn list(roles: &Roles, shown: &[&Country], state: &VpnLauncher) -> Rectangle {
    let first = (state.scroll / ROW_STEP) as usize;
    let mut rows: Vec<Box<dyn Widget>> = Vec::new();

    for (index, country) in shown.iter().enumerate().skip(first) {
        if index as f32 * ROW_STEP > state.scroll + LIST_HEIGHT {
            break;
        }
        let position = (index == 0, index == shown.len() - 1);
        let current = if state.step == Step::Entry { country.entry } else { country.exit };
        rows.push(Box::new(row(roles, country, index, position, (index == state.selected, current))));
    }

    let offset = first as f32 * ROW_STEP - state.scroll;

    Rectangle::new()
        .width(INNER)
        .height(LIST_HEIGHT)
        .clip()
        .on_scroll(|scroll| scroll_by(scroll.y))
        .child(
            Rectangle::new()
                .width(INNER)
                .height(LIST_HEIGHT - offset)
                .translate(0.0, offset)
                .child(Column::new(rows).width(INNER).gap(2.0)),
        )
}

fn row(roles: &Roles, country: &Country, index: usize, position: (bool, bool), flags: (bool, bool)) -> Rectangle {
    let key = format!("vpn/row/{index}");
    let ((first, last), (selected, current)) = (position, flags);

    let top = anim::float(&format!("{key}/top"), if selected || first { SHAPE_LI } else { SHAPE_XS }, SPRING_FAST);
    let bottom = anim::float(&format!("{key}/bottom"), if selected || last { SHAPE_LI } else { SHAPE_XS }, SPRING_FAST);
    let (base, tint) = if selected {
        (roles.secondary_container, roles.text_on_secondary_container)
    } else {
        (roles.surface_container_high, roles.text_on_surface)
    };

    let badge = Rectangle::new()
        .width(40.0)
        .height(40.0)
        .radius(if current { SHAPE_M } else { 20.0 })
        .fill(if current { roles.primary } else { roles.surface_container_highest })
        .align_child(Center, Center);
    let badge = if current {
        badge.child(m3::icon("check", 20.0, roles.text_on_primary, false))
    } else {
        badge.child(m3::label(country.code.clone(), TYPE_LABEL, roles.text_on_surface_variant).weight(Weight::Bold))
    };

    let servers = format!(
        "{} {}{}",
        country.servers,
        if country.servers == 1 { "server" } else { "servers" },
        if current { "  \u{2022}  current" } else { "" }
    );
    let titles = Column::new(children![
        m3::label(country.name.clone(), TYPE_BODY + 1.0, tint).weight(Weight::Bold).elide(),
        m3::label(servers, TYPE_LABEL, if current { roles.primary } else { roles.text_on_surface_variant }),
    ])
    .width(Parent)
    .gap(1.0);

    let chevron = Rectangle::new()
        .width(20.0)
        .height(20.0)
        .opacity(anim::float(&format!("{key}/chevron"), if selected { 1.0 } else { 0.0 }, EFFECTS))
        .child(m3::icon("chevron_right", 20.0, roles.text_on_secondary_container, false));

    let hover_key = key.clone();

    Rectangle::new()
        .width(INNER)
        .height(ROW_HEIGHT)
        .radius_top_left(top)
        .radius_top_right(top)
        .radius_bottom_left(bottom)
        .radius_bottom_right(bottom)
        .fill(m3::state_color(&key, base, tint))
        .padding(m3::horizontal(12.0, 18.0))
        .align_child(Start, Center)
        .cursor(Pointer)
        .on_hover(move |inside| {
            anim::set_hovered(&hover_key, inside);
            if inside {
                select(index);
            }
        })
        .on_click(|_| choose())
        .child(Row::new(children![badge, titles, chevron]).width(Parent).gap(14.0).align(Center))
}
