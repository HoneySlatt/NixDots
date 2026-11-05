// Theme picker with a live preview, toggled with Mod+T

use std::time::Duration;

use amane::{
    Center, Color, Column, End, Key, LayerWindow, Monitor, Padding, Parent, Pointer, Rectangle, Row, Service,
    Stack, Start, Weight, Widget, children,
};

use crate::anim::{self, SPRING_DEFAULT, SPRING_FAST};
use crate::m3::{self, Grow};
use crate::popups::{self, Anchor, Popup};
use crate::theme::{
    self, Palette, Roles, SHAPE_LI, SHAPE_M, SHAPE_XLI, THEMES, TYPE_BODY, TYPE_HEADLINE, TYPE_LABEL, TYPE_LABEL_S,
    TYPE_TITLE_L, Theme,
};

const PANEL_WIDTH: f32 = 1080.0;
const PANEL_HEIGHT: f32 = 330.0;
const PREVIEW_WIDTH: f32 = 470.0;
const PREVIEW_HEIGHT: f32 = 190.0;
const CARD_WIDTH: f32 = 154.0;
const CARD_HEIGHT: f32 = 210.0;

#[derive(Default)]
pub struct ThemeLauncher {
    selected: usize,
}

impl Service for ThemeLauncher {
    fn new() -> Self {
        Self::default()
    }

    fn interval() -> Duration {
        Duration::from_secs(3600)
    }
}

// Starts on the current theme
pub fn reset() {
    let current = Theme::read().key.clone();
    ThemeLauncher::write().selected = THEMES.iter().position(|(key, _)| *key == current).unwrap_or_default();
}

fn select(index: usize) {
    ThemeLauncher::write().selected = index.min(THEMES.len() - 1);
}

fn apply(index: usize) {
    theme::set_theme(THEMES[index].0);
    popups::close();
}

fn on_key(key: Key) {
    let selected = ThemeLauncher::read().selected;

    match key {
        Key::Escape => popups::close(),
        Key::Enter => apply(selected),
        Key::Left | Key::Character('h') => select(selected.saturating_sub(1)),
        Key::Right | Key::Character('l') => select(selected + 1),
        _ => {}
    }
}

pub fn view(monitor: &Monitor) -> LayerWindow {
    popups::window(monitor, Popup::ThemeLauncher, Anchor::Modal, on_key, |context| {
        let roles = Theme::read().roles;
        let current = Theme::read().key.clone();
        let selected = ThemeLauncher::read().selected;

        let (key, name) = THEMES[selected];
        let palette = theme::palette_for(key).expect("listed themes have a palette");

        let preview = m3::surface(&roles, (PREVIEW_WIDTH, PREVIEW_HEIGHT), SHAPE_XLI, false, Grow::Center, context.opened, preview(&palette, name, key == current))
            .fill(palette.background)
            .cursor(Pointer)
            .on_click(move |_| apply(selected));

        let panel = m3::surface(&roles, (PANEL_WIDTH, PANEL_HEIGHT), SHAPE_XLI, false, Grow::Center, context.opened, cards(&roles, &current, selected));

        // the panel sits a little below the middle, the preview right above it
        let column = Column::new(children![preview, panel]).gap(16.0).align(Center);
        Rectangle::new().width(m3::width_of(&column)).height(m3::height_of(&column)).translate(0.0, 7.0).child(column)
    })
}

fn pill(width: f32, radius: f32, fill: Color, text: &str, color: Color) -> Rectangle {
    Rectangle::new()
        .width(width)
        .height(40.0)
        .radius(radius)
        .fill(fill)
        .align_child(Center, Center)
        .child(m3::label(text, TYPE_BODY, color).weight(Weight::Bold))
}

fn preview(palette: &Palette, name: &str, active: bool) -> Rectangle {
    let inner = PREVIEW_WIDTH - 48.0;
    let on_accent = theme::content_on(palette.accent);
    let tonal = theme::mix(palette.background, palette.accent, 0.22);

    let mut title: Vec<Box<dyn Widget>> = vec![Box::new(
        Rectangle::new()
            .width(Parent)
            .height(34.0)
            .align_child(Start, Center)
            .child(m3::label(name, TYPE_HEADLINE, palette.text).weight(Weight::Bold)),
    )];
    if active {
        let text = m3::label("Active", TYPE_LABEL_S, on_accent).weight(Weight::Bold);
        title.push(Box::new(
            Rectangle::new().width(m3::width_of(&text) + 16.0).height(20.0).radius(10.0).fill(palette.accent).align_child(Center, Center).child(text),
        ));
    }

    let mut controls: Vec<Box<dyn Widget>> = vec![
        Box::new(pill(m3::width_of(&m3::label("Apply", TYPE_BODY, on_accent).weight(Weight::Bold)) + 40.0, 20.0, palette.accent, "Apply", on_accent)),
        Box::new(pill(m3::width_of(&m3::label("Tonal", TYPE_BODY, palette.text).weight(Weight::Bold)) + 40.0, SHAPE_M, tonal, "Tonal", palette.text)),
        Box::new(
            Rectangle::new()
                .width(52.0)
                .height(32.0)
                .radius(16.0)
                .fill(palette.accent)
                .padding(m3::horizontal(0.0, 4.0))
                .align_child(End, Center)
                .child(Rectangle::new().width(24.0).height(24.0).radius(12.0).fill(on_accent)),
        ),
    ];
    for color in [palette.process, palette.misc, palette.warning] {
        controls.push(Box::new(Rectangle::new().width(28.0).height(28.0).radius(14.0).fill(color)));
    }

    let slider = Row::new(children![
        Rectangle::new().width(inner * 0.62).height(14.0).radius(7.0).fill(palette.accent),
        Rectangle::new().width(4.0).height(32.0).radius(2.0).fill(palette.accent),
        Rectangle::new().width(inner * 0.38 - 16.0).height(14.0).radius(7.0).fill(tonal),
    ])
    .gap(6.0)
    .align(Center);

    Rectangle::new().width(Parent).height(Parent).padding(24.0).child(
        Column::new(children![
            Row::new(title).width(inner).gap(12.0).align(Center),
            Row::new(controls).gap(10.0).align(Center),
            slider,
        ])
        .width(inner)
        .gap(18.0),
    )
}

fn cards(roles: &Roles, current: &str, selected: usize) -> Rectangle {
    let header = Row::new(children![
        Rectangle::new()
            .width(Parent)
            .height(24.0)
            .align_child(Start, Center)
            .child(m3::label("Themes", TYPE_TITLE_L, roles.text_on_surface).weight(Weight::Bold)),
        m3::label("\u{2190}/\u{2192} browse  \u{2022}  enter apply", TYPE_LABEL, roles.text_on_surface_variant),
    ])
    .width(PANEL_WIDTH - 56.0)
    .align(Center);

    let mut cells: Vec<Box<dyn Widget>> = Vec::new();
    for (index, (key, name)) in THEMES.iter().enumerate() {
        cells.push(Box::new(card(roles, index, (key, name), *key == current, index == selected)));
    }

    Rectangle::new()
        .width(Parent)
        .height(Parent)
        .padding(Padding { top: 22.0, right: 28.0, bottom: 26.0, left: 28.0 })
        .child(
            Column::new(children![
                header,
                Rectangle::new()
                    .width(PANEL_WIDTH - 56.0)
                    .height(Parent)
                    .align_child(Center, End)
                    .child(Row::new(cells).height(CARD_HEIGHT + 12.0).gap(16.0).align(Center)),
            ])
            .width(PANEL_WIDTH - 56.0)
            .height(PANEL_HEIGHT - 48.0),
        )
}

fn card(roles: &Roles, index: usize, theme: (&str, &str), active: bool, selected: bool) -> Rectangle {
    let (key, name) = theme;
    let palette = theme::palette_for(key).expect("listed themes have a palette");
    let hover_key = format!("theme-launcher/{key}");

    let radius = anim::float(&format!("{hover_key}/radius"), if selected { SHAPE_XLI } else { SHAPE_LI }, SPRING_FAST);
    let scale = anim::float(&format!("{hover_key}/scale"), if selected { 1.0 } else { 0.94 }, SPRING_FAST);
    let rotation = anim::float(&format!("{hover_key}/rotation"), if selected { 0.0 } else { -45.0 }, SPRING_DEFAULT);

    let dots = Row::new(
        [palette.separator, palette.text, palette.highlight, palette.warning]
            .into_iter()
            .map(|color| -> Box<dyn Widget> { Box::new(Rectangle::new().width(12.0).height(12.0).radius(6.0).fill(color)) })
            .collect(),
    )
    .gap(5.0);

    let content = Column::new(children![
        m3::centered(88.0, 88.0, m3::swatch(88.0, palette.accent, palette.process, palette.misc)).rotate(rotation),
        m3::label(name, TYPE_BODY + 1.0, palette.text).weight(Weight::Bold),
        dots,
    ])
    .gap(16.0)
    .align(Center);

    let mut layers: Vec<Box<dyn Widget>> = vec![Box::new(
        Rectangle::new()
            .width(CARD_WIDTH)
            .height(CARD_HEIGHT)
            .radius(radius)
            .fill(m3::state_color(&hover_key, palette.background, palette.text))
            .align_child(Center, Center)
            .child(content),
    )];

    if active {
        layers.push(Box::new(
            Rectangle::new()
                .width(CARD_WIDTH)
                .height(CARD_HEIGHT)
                .padding(12.0)
                .align_child(End, Start)
                .child(m3::centered(28.0, 28.0, m3::icon("check", 16.0, theme::content_on(palette.accent), false)).radius(14.0).fill(palette.accent)),
        ));
    }

    let mut ring_roles = *roles;
    ring_roles.secondary = palette.accent;
    layers.push(Box::new(m3::focus_ring(&ring_roles, &hover_key, (0.0, 0.0), (CARD_WIDTH, CARD_HEIGHT), (radius, radius), selected)));

    let hover = hover_key.clone();
    Rectangle::new()
        .width(CARD_WIDTH)
        .height(CARD_HEIGHT)
        .scale(scale)
        .cursor(Pointer)
        .on_hover(move |inside| {
            anim::set_hovered(&hover, inside);
            if inside {
                select(index);
            }
        })
        .on_click(move |_| {
            if ThemeLauncher::read().selected == index {
                apply(index);
            } else {
                select(index);
            }
        })
        .child(Stack::new(layers).width(CARD_WIDTH).height(CARD_HEIGHT))
}
