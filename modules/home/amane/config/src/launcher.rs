// App list opened from the distro icon

use std::time::Duration;

use amane::{
    Apps, Center, Column, DesktopApp, Image, Key, LayerWindow, Monitor, Parent, Pointer, Rectangle, Row,
    Service, Stack, Start, TextInput, Weight, Widget, children,
};

use crate::anim::{self, EFFECTS, SPRING_FAST};
use crate::m3::{self, Grow};
use crate::popups::{self, Anchor, Popup};
use crate::theme::{Roles, SHAPE_LI, SHAPE_XL, SHAPE_XS, TYPE_BODY, Theme};

const SEARCH: &str = "app-launcher-search";

const WIDTH: f32 = 380.0;
const HEIGHT: f32 = 430.0;
const PADDING: f32 = 12.0;
const ROW_HEIGHT: f32 = 48.0;
const ROW_STEP: f32 = ROW_HEIGHT + 2.0;
const LIST_HEIGHT: f32 = HEIGHT - 2.0 * PADDING - 48.0 - PADDING;

#[derive(Default)]
pub struct AppLauncher {
    query: String,
    selected: usize,
    // pixels scrolled down the list
    scroll: f32,
}

impl Service for AppLauncher {
    fn new() -> Self {
        Self::default()
    }

    fn interval() -> Duration {
        Duration::from_secs(3600)
    }
}

pub fn reset() {
    *AppLauncher::write() = AppLauncher::default();
    TextInput::set_text(SEARCH, "");
}

fn matching<'a>(apps: &'a [DesktopApp], query: &str) -> Vec<&'a DesktopApp> {
    apps.iter().filter(|app| app.name().to_lowercase().contains(query)).collect()
}

fn count() -> usize {
    let query = AppLauncher::read().query.clone();
    matching(Apps::read().list(), &query).len()
}

fn max_scroll(count: usize) -> f32 {
    (count as f32 * ROW_STEP - 2.0 - LIST_HEIGHT).max(0.0)
}

// Selects a row and scrolls just enough to show it
fn select(index: usize) {
    let count = count();
    let mut state = AppLauncher::write();

    state.selected = index.min(count.saturating_sub(1));

    let top = state.selected as f32 * ROW_STEP;
    state.scroll = state.scroll.min(top).max(top + ROW_HEIGHT - LIST_HEIGHT);
}

fn set_query(text: String) {
    AppLauncher::write().query = text.to_lowercase();
    let selected = AppLauncher::read().selected;
    select(selected);
}

fn scroll_by(lines: f32) {
    let count = count();
    let mut state = AppLauncher::write();
    state.scroll = (state.scroll + lines * 40.0).clamp(0.0, max_scroll(count));
}

fn launch_selected() {
    let app = {
        let state = AppLauncher::read();
        let apps = Apps::read();
        matching(apps.list(), &state.query).get(state.selected).map(|app| (*app).clone())
    };

    if let Some(app) = app {
        app.launch();
        popups::close();
    }
}

fn on_key(key: Key) {
    match key {
        Key::Escape => popups::close(),
        Key::Enter => launch_selected(),
        Key::Down => select(AppLauncher::read().selected + 1),
        Key::Up => select(AppLauncher::read().selected.saturating_sub(1)),
        _ => {}
    }
}

pub fn view(monitor: &Monitor) -> LayerWindow {
    popups::window(monitor, Popup::AppLauncher, Anchor::TopLeft, on_key, |context| {
        let roles = Theme::read().roles;

        let search = TextInput::new(SEARCH)
            .size(TYPE_BODY + 1.0)
            .color(roles.text_on_surface)
            .placeholder("Search apps")
            .width(WIDTH - 2.0 * PADDING - 16.0 - 20.0 - 20.0 - 14.0)
            .focused()
            .on_change(set_query)
            .on_submit(|_| launch_selected());

        let content = Rectangle::new()
            .width(Parent)
            .height(Parent)
            .padding(PADDING)
            .child(
                Column::new(children![m3::search_field(&roles, WIDTH - 2.0 * PADDING, search), list(&roles)])
                    .gap(PADDING),
            );

        m3::surface(
            &roles,
            (WIDTH, HEIGHT),
            SHAPE_XL,
            !context.top,
            if context.top { Grow::Top } else { Grow::Bottom },
            context.opened,
            content,
        )
    })
}

fn list(roles: &Roles) -> Rectangle {
    let state = AppLauncher::read();
    let apps = Apps::read();
    let shown = matching(apps.list(), &state.query);

    let area = Rectangle::new()
        .width(Parent)
        .height(LIST_HEIGHT)
        .clip()
        .on_scroll(|scroll| scroll_by(scroll.y));

    if shown.is_empty() {
        return area.align_child(Center, Center).child(m3::label(
            "No applications found",
            TYPE_BODY,
            roles.text_on_surface_variant,
        ));
    }

    // only the rows in view are built
    let first = (state.scroll / ROW_STEP) as usize;
    let mut rows: Vec<Box<dyn Widget>> = Vec::new();

    for (index, app) in shown.iter().enumerate().skip(first) {
        if index as f32 * ROW_STEP > state.scroll + LIST_HEIGHT {
            break;
        }

        let position = (index == 0, index == shown.len() - 1);
        rows.push(Box::new(row(roles, app, index, position, index == state.selected)));
    }

    let offset = first as f32 * ROW_STEP - state.scroll;

    area.child(
        Rectangle::new()
            .width(Parent)
            .height(LIST_HEIGHT - offset)
            .translate(0.0, offset)
            .child(Column::new(rows).width(Parent).gap(2.0)),
    )
}

pub fn app_icon(app: &DesktopApp, size: f32, fallback: f32, roles: &Roles) -> Stack {
    let mut layers: Vec<Box<dyn Widget>> = Vec::new();

    let loaded = app.icon_path().is_some_and(Image::loaded);
    if !loaded {
        layers.push(Box::new(m3::centered(size, size, m3::icon("apps", fallback, roles.primary, false))));
    }

    if let Some(path) = app.icon_path() {
        let pixels = (size * 2.0) as u32;
        layers.push(Box::new(
            Rectangle::new().width(size).height(size).fill(Image::contain(path).thumbnail(pixels, pixels)),
        ));
    }

    Stack::new(layers).width(size).height(size)
}

// M3 Expressive segmented list item: connected corners, fully rounded when selected
fn row(roles: &Roles, app: &DesktopApp, index: usize, position: (bool, bool), selected: bool) -> Rectangle {
    let key = format!("applauncher/row/{index}");
    let (first, last) = position;

    let top = if selected || first { SHAPE_LI } else { SHAPE_XS };
    let bottom = if selected || last { SHAPE_LI } else { SHAPE_XS };
    let top = anim::float(&format!("{key}/top"), top, SPRING_FAST);
    let bottom = anim::float(&format!("{key}/bottom"), bottom, SPRING_FAST);

    let (base, tint) = if selected {
        (roles.secondary_container, roles.text_on_secondary_container)
    } else {
        (roles.surface_container_high, roles.text_on_surface)
    };

    let name = m3::label(app.name(), TYPE_BODY + 1.0, if selected { roles.text_on_secondary_container } else { roles.text_on_surface })
        .weight(if selected { Weight::Bold } else { Weight::SemiBold })
        .elide();

    let chevron = Rectangle::new()
        .width(20.0)
        .height(20.0)
        .align_child(Center, Center)
        .opacity(anim::float(&format!("{key}/chevron"), if selected { 1.0 } else { 0.0 }, EFFECTS))
        .child(m3::icon("chevron_right", 20.0, roles.text_on_secondary_container, false));

    let launched = app.clone();

    Rectangle::new()
        .width(Parent)
        .height(ROW_HEIGHT)
        .cursor(Pointer)
        .radius_top_left(top)
        .radius_top_right(top)
        .radius_bottom_left(bottom)
        .radius_bottom_right(bottom)
        .fill(m3::state_color(&key, base, tint))
        .padding(m3::horizontal(14.0, 16.0))
        .align_child(Start, Center)
        .on_hover(move |inside| {
            anim::set_hovered(&format!("applauncher/row/{index}"), inside);
            if inside {
                select(index);
            }
        })
        .on_click(move |_| {
            launched.launch();
            popups::close();
        })
        .child(
            Row::new(children![app_icon(app, 28.0, 24.0, roles), name, chevron])
                .width(Parent)
                .gap(14.0)
                .align(Center),
        )
}
