// Centered app carousel, toggled with Mod+Space

use std::time::Duration;

use amane::{
    Apps, Center, Column, DesktopApp, Key, LayerWindow, Monitor, Parent, Pointer, Rectangle, Row,
    Service, Stack, Weight, Widget, children,
};

use crate::anim::{self, EFFECTS, SPRING_FAST};
use crate::launcher::app_icon;
use crate::m3::{self, Grow};
use crate::popups::{self, Anchor, Popup};
use crate::theme::{Roles, SHAPE_LI, SHAPE_XL, SHAPE_XLI, TYPE_BODY, Theme};

const WIDTH: f32 = 720.0;
const PADDING: f32 = 20.0;
const INNER: f32 = WIDTH - 2.0 * PADDING;
const CARD_WIDTH: f32 = 96.0;
const CARD_HEIGHT: f32 = 116.0;
const CELL_WIDTH: f32 = 110.0;
const CELL_HEIGHT: f32 = 130.0;
const HEIGHT: f32 = PADDING + 48.0 + 16.0 + CELL_HEIGHT + PADDING;

#[derive(Default)]
pub struct SmallLauncher {
    query: String,
    // none: the middle app, resolved once the app list is known
    selected: Option<usize>,
}

impl SmallLauncher {
    fn selected(&self, count: usize) -> usize {
        self.selected.unwrap_or(count / 2)
    }
}

impl Service for SmallLauncher {
    fn new() -> Self {
        Self::default()
    }

    fn interval() -> Duration {
        Duration::from_secs(3600)
    }
}

fn matching<'a>(apps: &'a [DesktopApp], query: &str) -> Vec<&'a DesktopApp> {
    let query = query.to_lowercase();
    apps.iter().filter(|app| app.name().to_lowercase().contains(&query)).collect()
}

fn count(query: &str) -> usize {
    matching(Apps::read().list(), query).len()
}

fn set_query(query: String) {
    let selected = if query.is_empty() { None } else { Some(0) };
    *SmallLauncher::write() = SmallLauncher { query, selected };
}

pub fn reset() {
    set_query(String::new());
}

fn select(index: usize) {
    let query = SmallLauncher::read().query.clone();
    let last = count(&query).saturating_sub(1);
    SmallLauncher::write().selected = Some(index.min(last));
}

fn launch(app: &DesktopApp) {
    app.launch();
    popups::close();
}

fn on_key(key: Key) {
    let (query, selected) = {
        let state = SmallLauncher::read();
        (state.query.clone(), state.selected(count(&state.query)))
    };

    match key {
        Key::Escape => popups::close(),
        Key::Enter => {
            let app = matching(Apps::read().list(), &query).get(selected).map(|app| (*app).clone());
            if let Some(app) = app {
                launch(&app);
            }
        }
        Key::Left => select(selected.saturating_sub(1)),
        Key::Right => select(selected + 1),
        Key::Backspace => {
            let mut query = query;
            query.pop();
            set_query(query);
        }
        Key::Space => set_query(query + " "),
        Key::Character(letter) if !letter.is_control() => set_query(format!("{query}{letter}")),
        _ => {}
    }
}

pub fn view(monitor: &Monitor) -> LayerWindow {
    popups::window(monitor, Popup::SmallLauncher, Anchor::Center, on_key, |context| {
        let roles = Theme::read().roles;
        let state = SmallLauncher::read();

        let typed: Box<dyn Widget> = if state.query.is_empty() {
            Box::new(m3::label("Search apps", TYPE_BODY + 1.0, roles.text_on_surface_variant))
        } else {
            Box::new(m3::label(state.query.clone(), TYPE_BODY + 1.0, roles.text_on_surface))
        };
        // the caret sits before the placeholder, after typed text
        let caret = Box::new(Rectangle::new().width(1.5).height(18.0).fill(roles.text_on_surface));
        let parts: Vec<Box<dyn Widget>> = if state.query.is_empty() { vec![caret, typed] } else { vec![typed, caret] };
        let search = Row::new(parts).align(Center);

        let content = Rectangle::new().width(Parent).height(Parent).padding(PADDING).child(
            Column::new(children![m3::search_field(&roles, INNER, search), carousel(&roles, &state)]).gap(16.0),
        );

        m3::surface(&roles, (WIDTH, HEIGHT), SHAPE_XLI, false, Grow::Center, context.opened, content)
    })
}

fn carousel(roles: &Roles, state: &SmallLauncher) -> Rectangle {
    let apps = Apps::read();
    let shown = matching(apps.list(), &state.query);

    let area = Rectangle::new().width(INNER).height(CELL_HEIGHT).clip();

    if shown.is_empty() {
        return area.align_child(Center, Center).child(m3::label(
            "No applications found",
            TYPE_BODY,
            roles.text_on_surface_variant,
        ));
    }

    let selected = state.selected(shown.len());

    // the selected card stays in the middle and the row slides under it
    let target = INNER / 2.0 - (selected as f32 * CELL_WIDTH + CELL_WIDTH / 2.0);
    let offset = anim::float("small-launcher/offset", target, EFFECTS);

    let mut cells: Vec<Box<dyn Widget>> = Vec::new();

    for (index, app) in shown.iter().enumerate() {
        let x = offset + index as f32 * CELL_WIDTH;

        if x + CELL_WIDTH < 0.0 || x > INNER {
            continue;
        }

        cells.push(Box::new(
            Rectangle::new()
                .width(CELL_WIDTH)
                .height(CELL_HEIGHT)
                .translate(x, 0.0)
                .align_child(Center, Center)
                .child(card(roles, app, index, index == selected)),
        ));
    }

    area.child(Stack::new(cells).width(INNER).height(CELL_HEIGHT))
}

fn card(roles: &Roles, app: &DesktopApp, index: usize, selected: bool) -> Rectangle {
    let key = format!("small-launcher/card/{}", app.name());

    let radius = anim::float(&format!("{key}/radius"), if selected { SHAPE_XL } else { SHAPE_LI }, SPRING_FAST);
    let scale = anim::float(&format!("{key}/scale"), if selected { 1.0 } else { 0.9 }, SPRING_FAST);

    let (base, tint) = if selected {
        (roles.primary_container, roles.text_on_primary_container)
    } else {
        (amane::Color::TRANSPARENT, roles.text_on_surface)
    };

    // short names are centered, long ones elided to the card width
    let name = m3::label(app.name(), TYPE_BODY, tint).weight(Weight::Bold);
    let name: Box<dyn Widget> = if m3::width_of(&name) <= CARD_WIDTH - 12.0 {
        Box::new(name)
    } else {
        Box::new(Rectangle::new().width(CARD_WIDTH - 12.0).height(18.0).child(name.elide()))
    };

    let launched = app.clone();
    let hover_key = key.clone();

    Rectangle::new()
        .width(CARD_WIDTH)
        .height(CARD_HEIGHT)
        .radius(radius)
        .scale(scale)
        .fill(m3::state_color(&key, base, tint))
        .cursor(Pointer)
        .align_child(Center, Center)
        .on_hover(move |inside| {
            anim::set_hovered(&hover_key, inside);
            if inside {
                select(index);
            }
        })
        .on_click(move |_| launch(&launched))
        .child(Column::new(vec![Box::new(app_icon(app, 48.0, 36.0, roles)), name]).gap(10.0).align(Center))
}
