// Material 3 Expressive building blocks shared by the popups

use std::rc::Rc;
use std::time::Instant;

use amane::{
    Canvas, Center, Color, Column, Padding, Parent, Path, Pointer, Rectangle, Row, Shadow, Shape, Size, Stack,
    Start, Text, Weight,
    Widget, children, shapes,
};

use crate::anim::{self, EFFECTS, SPRING_DEFAULT, SPRING_FAST};
use crate::icons;
use crate::theme::{
    self, FONT, ICON_FONT, Roles, SHAPE_LI, SHAPE_M, SHAPE_S, SHAPE_XS, STATE_HOVER, TYPE_BODY, TYPE_LABEL, TYPE_TITLE,
};

pub fn width_of(widget: &impl Widget) -> f32 {
    match widget.width() {
        Size::Fixed(width) => width,
        Size::Parent => 0.0,
    }
}

pub fn label(text: impl Into<String>, size: f32, color: Color) -> Text {
    Text::new(text).font(FONT).size(size).weight(Weight::SemiBold).color(color)
}

// Material Symbols Rounded glyph, centered on its ink
pub fn icon(name: &str, size: f32, color: Color, filled: bool) -> Text {
    let family = format!("{ICON_FONT}:FILL={},opsz={}", u8::from(filled), size.clamp(20.0, 48.0));

    Text::new(icons::glyph(name).to_string())
        .font(&family)
        .size(size)
        .color(color)
        .tight()
}

pub fn centered(width: f32, height: f32, child: impl Widget + 'static) -> Rectangle {
    Rectangle::new().width(width).height(height).align_child(Center, Center).child(child)
}

pub fn horizontal(left: f32, right: f32) -> Padding {
    Padding { top: 0.0, right, bottom: 0.0, left }
}

// Tracks the pointer for state layers under `key`
pub fn hoverable(rectangle: Rectangle, key: &str) -> Rectangle {
    let key = String::from(key);
    rectangle.cursor(Pointer).on_hover(move |inside| anim::set_hovered(&key, inside))
}

// Container color with the hover state layer laid over it
pub fn state_color(key: &str, base: Color, tint: Color) -> Color {
    let target = if anim::hovered(key) { STATE_HOVER } else { 0.0 };
    let alpha = anim::float(&format!("{key}/state"), target, EFFECTS);

    theme::overlay(anim::color(&format!("{key}/color"), base, EFFECTS), tint, alpha)
}

#[derive(Clone, Copy)]
pub enum Grow {
    Top,
    Bottom,
    Center,
}

// Elevated popup container with an expressive entrance
pub fn surface(
    roles: &Roles,
    size: (f32, f32),
    radius: f32,
    flush_bottom: bool,
    grow: Grow,
    opened: Instant,
    content: impl Widget + 'static,
) -> Rectangle {
    let (width, height) = size;
    let scale = 0.9 + 0.1 * anim::since(opened, SPRING_DEFAULT);

    // scaled around the center, so shifted back to keep the growing edge in place
    let shift = (1.0 - scale) * height / 2.0;
    let shift = match grow {
        Grow::Top => -shift,
        Grow::Bottom => shift,
        Grow::Center => 0.0,
    };

    let rectangle = Rectangle::new().width(width).height(height).fill(roles.surface);
    let rectangle = if flush_bottom {
        rectangle.radius_top_left(radius).radius_top_right(radius)
    } else {
        rectangle.radius(radius)
    };

    rectangle
        .shadow(Shadow::drop(roles.shadow).blur(28.0).offset(0.0, 6.0))
        .opacity(anim::since(opened, EFFECTS).clamp(0.0, 1.0))
        .scale(scale)
        .translate(0.0, shift)
        .on_click(|_| {})
        .child(content)
}

pub fn search_field(roles: &Roles, width: f32, content: impl Widget + 'static) -> Rectangle {
    Rectangle::new()
        .width(width)
        .height(48.0)
        .radius(24.0)
        .fill(roles.surface_container_high)
        .padding(horizontal(16.0, 20.0))
        .align_child(Start, Center)
        .child(
            Row::new(children![icon("search", 20.0, roles.text_on_surface, false), content])
                .gap(14.0)
                .align(Center),
        )
}

#[derive(Clone, Copy, PartialEq)]
pub enum Variant {
    Standard,
    Filled,
    Tonal,
    Outlined,
    Error,
}

// Container and content colors of a button variant
fn variant_colors(roles: &Roles, variant: Variant, toggle: bool, checked: bool) -> (Color, Color) {
    let selected = toggle && checked;

    match variant {
        Variant::Filled if toggle && !checked => (roles.surface_container_highest, roles.primary),
        Variant::Filled => (roles.primary, roles.text_on_primary),
        Variant::Tonal if selected => (roles.secondary, roles.text_on_secondary),
        Variant::Tonal => (roles.secondary_container, roles.text_on_secondary_container),
        Variant::Outlined => (Color::TRANSPARENT, roles.text_on_surface_variant),
        Variant::Error if selected => (roles.error, roles.text_on_error),
        Variant::Error => (roles.error_container, roles.text_on_error_container),
        Variant::Standard if selected => (Color::TRANSPARENT, roles.primary),
        Variant::Standard => (Color::TRANSPARENT, roles.text_on_surface_variant),
    }
}

// Round at rest, squarer when selected
pub fn icon_button(
    roles: &Roles,
    key: &str,
    name: &str,
    size: (f32, f32),
    variant: Variant,
    toggle: bool,
    checked: bool,
    on_click: impl Fn() + 'static,
) -> Rectangle {
    let (width, height) = size;
    let selected = toggle && checked;
    let (container, content) = variant_colors(roles, variant, toggle, checked);
    let radius = anim::float(&format!("{key}/radius"), height * if selected { 0.3 } else { 0.5 }, SPRING_FAST);

    hoverable(Rectangle::new().width(width).height(height), key)
        .radius(radius)
        .fill(state_color(key, container, content))
        .align_child(Center, Center)
        .on_click(move |_| on_click())
        .child(icon(name, (height * 0.5).round(), content, selected))
}

// One button of a connected group: outer corners full, inner corners small
pub fn group_button(
    roles: &Roles,
    key: &str,
    name: &str,
    text: &str,
    size: (f32, f32),
    label_size: f32,
    position: (bool, bool),
    on_click: impl Fn() + 'static,
) -> Rectangle {
    let (width, height) = size;
    let (first, last) = position;
    let (container, content) = variant_colors(roles, Variant::Error, false, false);
    let outer = height / 2.0;
    let left = if first { outer } else { SHAPE_S };
    let right = if last { outer } else { SHAPE_S };

    hoverable(Rectangle::new().width(width).height(height), key)
        .radius_top_left(left)
        .radius_bottom_left(left)
        .radius_top_right(right)
        .radius_bottom_right(right)
        .fill(state_color(key, container, content))
        .align_child(Center, Center)
        .on_click(move |_| on_click())
        .child(
            Row::new(children![
                icon(name, if height >= 56.0 { 22.0 } else { 18.0 }, content, false),
                label(text, label_size, content).weight(Weight::Bold),
            ])
            .gap(8.0)
            .align(Center),
        )
}

// Quick settings tile: full-round when off, rounded square in primary when on
pub fn quick_tile(
    roles: &Roles,
    key: &str,
    width: f32,
    content: (&str, &str, &str),
    active: bool,
    on_click: impl Fn() + 'static,
) -> Rectangle {
    const HEIGHT: f32 = 60.0;

    let (name, title, subtitle) = content;
    let color = if active { roles.text_on_primary } else { roles.text_on_surface };
    let container = if active { roles.primary } else { roles.surface_container_highest };
    let radius = anim::float(&format!("{key}/radius"), if active { 20.0 } else { HEIGHT / 2.0 }, SPRING_FAST);
    let bubble_radius = anim::float(&format!("{key}/bubble"), if active { SHAPE_M } else { 18.0 }, SPRING_FAST);
    let bubble = if active {
        theme::with_alpha(roles.text_on_primary, 0.14)
    } else {
        theme::mix(roles.surface_container_highest, roles.text_on_surface, 0.07)
    };
    let subtitle_color = if active {
        theme::with_alpha(roles.text_on_primary, 0.8)
    } else {
        roles.text_on_surface_variant
    };

    let mut lines: Vec<Box<dyn Widget>> = vec![Box::new(label(title, TYPE_BODY + 1.0, color).weight(Weight::Bold))];
    if !subtitle.is_empty() {
        lines.push(Box::new(label(subtitle, TYPE_LABEL, subtitle_color).elide()));
    }

    hoverable(Rectangle::new().width(width).height(HEIGHT), key)
        .radius(radius)
        .fill(state_color(key, container, color))
        .padding(horizontal(12.0, 14.0))
        .align_child(Start, Center)
        .on_click(move |_| on_click())
        .child(
            Row::new(children![
                Rectangle::new()
                    .width(36.0)
                    .height(36.0)
                    .radius(bubble_radius)
                    .fill(bubble)
                    .align_child(Center, Center)
                    .child(icon(name, 20.0, color, false)),
                amane::Column::new(lines).width(Parent),
            ])
            .gap(10.0)
            .align(Center),
        )
}

// Thick split track with a bar handle and an optional inset icon
pub fn slider(
    roles: &Roles,
    key: &str,
    dims: (f32, f32, f32),
    state: (f32, bool),
    name: &str,
    on_icon: Option<fn()>,
    on_move: impl Fn(u8) + 'static,
) -> Rectangle {
    const GAP: f32 = 6.0;

    // total width, track height, handle height
    let (width, track_height, handle_height) = dims;
    let on_move = Rc::new(on_move);

    let (value, muted) = state;
    let dragged = anim::dragged(key);
    let shown = dragged.unwrap_or(value).clamp(0.0, 100.0);
    let active_color = if muted { roles.outline } else { roles.primary };

    let handle_width = anim::float(&format!("{key}/handle"), if dragged.is_some() { 2.0 } else { 4.0 }, SPRING_FAST);
    let handle_x = shown / 100.0 * (width - handle_width);
    let active_width = (handle_x - GAP).max(0.0);
    let inactive_x = handle_x + handle_width + GAP;
    let inactive_width = (width - inactive_x).max(0.0);
    let track_y = (handle_height - track_height) / 2.0;

    let mut layers: Vec<Box<dyn Widget>> = Vec::new();

    if active_width > 0.5 {
        let inner = SHAPE_XS.min(active_width / 2.0);
        layers.push(Box::new(
            Rectangle::new()
                .width(active_width)
                .height(track_height)
                .translate(0.0, track_y)
                .radius_top_left(track_height / 2.0)
                .radius_bottom_left(track_height / 2.0)
                .radius_top_right(inner)
                .radius_bottom_right(inner)
                .fill(anim::color(&format!("{key}/active"), active_color, EFFECTS)),
        ));
    }

    if inactive_width > 0.5 {
        let inner = SHAPE_XS.min(inactive_width / 2.0);
        let track = Rectangle::new()
            .width(inactive_width)
            .height(track_height)
            .translate(inactive_x, track_y)
            .radius_top_right(track_height / 2.0)
            .radius_bottom_right(track_height / 2.0)
            .radius_top_left(inner)
            .radius_bottom_left(inner)
            .fill(roles.secondary_container)
            .padding(horizontal(0.0, (track_height - 4.0) / 2.0))
            .align_child(amane::End, Center);

        let track = if inactive_width > track_height {
            track.child(Rectangle::new().width(4.0).height(4.0).radius(2.0).fill(active_color))
        } else {
            track
        };

        layers.push(Box::new(track));
    }

    let icon_size = (track_height * 0.5).round();
    let icon_x = (track_height - icon_size) / 2.0 + 4.0;
    let icon_color = if active_width > icon_x + icon_size {
        roles.text_on_primary
    } else {
        roles.text_on_secondary_container
    };

    layers.push(Box::new(
        Rectangle::new()
            .width(width)
            .height(handle_height)
            .on_drag({
                let key = String::from(key);
                let on_move = Rc::clone(&on_move);
                move |point| {
                    let value = (point.x / width).clamp(0.0, 1.0) * 100.0;
                    anim::drag(&key, value.round());
                    on_move(value.round() as u8);
                }
            })
            .on_scroll(move |scroll| {
                let step = if scroll.y < 0.0 { 5.0 } else if scroll.y > 0.0 { -5.0 } else { return };
                on_move((value + step).clamp(0.0, 100.0) as u8);
            })
            .cursor(Pointer),
    ));

    if !name.is_empty() {
        let glyph = centered(icon_size + 8.0, icon_size + 8.0, icon(name, icon_size, icon_color, false))
            .translate(icon_x - 4.0, (handle_height - icon_size - 8.0) / 2.0);
        layers.push(Box::new(match on_icon {
            Some(clicked) => glyph.cursor(Pointer).on_click(move |_| clicked()),
            None => glyph,
        }));
    }

    layers.push(Box::new(
        Rectangle::new()
            .width(handle_width)
            .height(handle_height)
            .translate(handle_x, 0.0)
            .radius(handle_width / 2.0)
            .fill(active_color),
    ));

    // value bubble above the handle while dragging
    let bubble_shown = anim::float(&format!("{key}/bubble"), if dragged.is_some() { 1.0 } else { 0.0 }, EFFECTS);
    if bubble_shown > 0.01 {
        let text = label(format!("{}", shown.round()), TYPE_LABEL, roles.inverse_on_surface).weight(Weight::Bold);
        let bubble_width = (width_of(&text) + 20.0).max(40.0);
        let bubble_x = (handle_x + handle_width / 2.0 - bubble_width / 2.0).clamp(0.0, width - bubble_width);

        layers.push(Box::new(
            Rectangle::new()
                .width(bubble_width)
                .height(32.0)
                .translate(bubble_x, -38.0)
                .radius(16.0)
                .fill(roles.inverse_surface)
                .opacity(bubble_shown)
                .scale(0.6 + 0.4 * bubble_shown)
                .align_child(Center, Center)
                .child(text),
        ));
    }

    Rectangle::new().width(width).height(handle_height).child(amane::Stack::new(layers).width(width).height(handle_height))
}

// Keyboard focus indicator around an area at `origin`, with (left, right) corner radii
pub fn focus_ring(roles: &Roles, key: &str, origin: (f32, f32), size: (f32, f32), radius: (f32, f32), shown: bool) -> Rectangle {
    const GROW: f32 = 6.0;

    let ((x, y), (width, height), (left, right)) = (origin, size, radius);

    Rectangle::new()
        .width(width + 2.0 * GROW)
        .height(height + 2.0 * GROW)
        .translate(x - GROW, y - GROW)
        .radius_top_left(left + GROW)
        .radius_bottom_left(left + GROW)
        .radius_top_right(right + GROW)
        .radius_bottom_right(right + GROW)
        .border(3.0, roles.secondary)
        .opacity(anim::float(&format!("{key}/ring"), if shown { 1.0 } else { 0.0 }, EFFECTS))
}

// `item` with a focus ring around its whole area
pub fn ringed(roles: &Roles, key: &str, item: impl Widget + 'static, radius: (f32, f32), shown: bool) -> Stack {
    let size = (width_of(&item), height_of(&item));

    Stack::new(children![item, focus_ring(roles, key, (0.0, 0.0), size, radius, shown)])
        .width(size.0)
        .height(size.1)
}

pub fn height_of(widget: &impl Widget) -> f32 {
    match widget.height() {
        Size::Fixed(height) => height,
        Size::Parent => 0.0,
    }
}

// Outlined, non-clickable filter chip
pub fn chip(roles: &Roles, name: &str, text: &str) -> Rectangle {
    let content = Row::new(children![
        icon(name, 16.0, roles.primary, false),
        label(text, TYPE_LABEL, roles.text_on_surface_variant).weight(Weight::Bold),
    ])
    .gap(8.0)
    .align(Center);

    Rectangle::new()
        .width(width_of(&content) + 24.0)
        .height(32.0)
        .radius(SHAPE_S)
        .border(1.0, roles.outline_variant)
        .align_child(Center, Center)
        .child(content)
}

// Common button with a text label, 40 pixels tall
pub fn text_button(roles: &Roles, key: &str, text: &str, width: f32, variant: Variant, on_click: impl Fn() + 'static) -> Rectangle {
    let (container, content) = variant_colors(roles, variant, false, false);

    let button = hoverable(Rectangle::new().width(width).height(40.0), key)
        .radius(20.0)
        .fill(state_color(key, container, content))
        .align_child(Center, Center)
        .on_click(move |_| on_click())
        .child(label(text, TYPE_BODY + 1.0, content).weight(Weight::Bold));

    if variant == Variant::Outlined {
        button.border(1.0, roles.outline_variant)
    } else {
        button
    }
}

// M3 switch: the thumb grows and gains a check when selected
pub fn switch(roles: &Roles, key: &str, checked: bool, on_click: impl Fn() + 'static) -> Rectangle {
    const WIDTH: f32 = 52.0;
    const HEIGHT: f32 = 32.0;

    let thumb = anim::float(&format!("{key}/thumb"), if checked { 24.0 } else { 16.0 }, SPRING_FAST);
    let center = anim::float(&format!("{key}/x"), if checked { WIDTH - HEIGHT / 2.0 } else { HEIGHT / 2.0 }, SPRING_FAST);
    let halo = anim::float(&format!("{key}/halo"), if anim::hovered(key) { STATE_HOVER } else { 0.0 }, EFFECTS);

    let track = Rectangle::new()
        .width(WIDTH)
        .height(HEIGHT)
        .radius(HEIGHT / 2.0)
        .fill(anim::color(&format!("{key}/track"), if checked { roles.primary } else { roles.surface_container_highest }, EFFECTS));
    let track = if checked { track } else { track.border(2.0, roles.outline) };

    let check = Rectangle::new()
        .width(thumb)
        .height(thumb)
        .align_child(Center, Center)
        .opacity(anim::float(&format!("{key}/check"), if checked { 1.0 } else { 0.0 }, EFFECTS))
        .child(icon("check", 14.0, roles.primary, false));

    let layers = children![
        track,
        Rectangle::new()
            .width(40.0)
            .height(40.0)
            .translate(center - 20.0, HEIGHT / 2.0 - 20.0)
            .radius(20.0)
            .fill(theme::with_alpha(if checked { roles.primary } else { roles.text_on_surface }, halo)),
        Rectangle::new()
            .width(thumb)
            .height(thumb)
            .translate(center - thumb / 2.0, (HEIGHT - thumb) / 2.0)
            .radius(thumb / 2.0)
            .fill(anim::color(&format!("{key}/thumb-color"), if checked { roles.text_on_primary } else { roles.outline }, EFFECTS))
            .child(check),
    ];

    hoverable(Rectangle::new().width(WIDTH).height(HEIGHT), key)
        .on_click(move |_| on_click())
        .child(Stack::new(layers).width(WIDTH).height(HEIGHT))
}

// Expandable list segment: a clickable header over a body that slides open
pub fn section(
    roles: &Roles,
    key: &str,
    width: f32,
    header: (&str, &str, &str),
    position: (bool, bool),
    expanded: bool,
    on_toggle: impl Fn() + 'static,
    body: Column,
) -> Rectangle {
    const HEADER: f32 = 48.0;

    let (name, title, summary) = header;
    let (first, last) = position;

    let top = if expanded || first { SHAPE_LI } else { SHAPE_XS };
    let bottom = if expanded || last { SHAPE_LI } else { SHAPE_XS };
    let top = anim::float(&format!("{key}/top"), top, SPRING_FAST);
    let bottom = anim::float(&format!("{key}/bottom"), bottom, SPRING_FAST);
    let open = anim::float(&format!("{key}/open"), if expanded { 1.0 } else { 0.0 }, SPRING_DEFAULT).max(0.0);
    let rotation = anim::float(&format!("{key}/rotation"), if expanded { 180.0 } else { 0.0 }, SPRING_FAST);

    let mut lines: Vec<Box<dyn Widget>> = vec![Box::new(label(title, TYPE_BODY + 1.0, roles.text_on_surface).weight(Weight::Bold))];
    if !summary.is_empty() {
        lines.push(Box::new(label(summary, TYPE_LABEL, roles.text_on_surface_variant).elide()));
    }

    let hover = anim::float(&format!("{key}/hover"), if anim::hovered(key) { STATE_HOVER } else { 0.0 }, EFFECTS);
    let header_bottom = if expanded { 0.0 } else { bottom };

    let header = hoverable(Rectangle::new().width(width).height(HEADER), key)
        .radius_top_left(top)
        .radius_top_right(top)
        .radius_bottom_left(header_bottom)
        .radius_bottom_right(header_bottom)
        .fill(theme::with_alpha(roles.text_on_surface, hover))
        .padding(horizontal(16.0, 16.0))
        .align_child(Start, Center)
        .on_click(move |_| on_toggle())
        .child(
            Row::new(children![
                icon(name, 20.0, roles.text_on_surface_variant, false),
                Column::new(lines).width(Parent),
                centered(20.0, 20.0, icon("expand_more", 20.0, roles.text_on_surface_variant, false)).rotate(rotation),
            ])
            .width(Parent)
            .gap(14.0)
            .align(Center),
        );

    let body_height = height_of(&body);
    let body = Rectangle::new()
        .width(width)
        .height(body_height)
        .padding(horizontal(8.0, 8.0))
        .opacity(anim::float(&format!("{key}/body"), if expanded { 1.0 } else { 0.0 }, EFFECTS))
        .child(body);

    Rectangle::new()
        .width(width)
        .height(HEADER + open * (body_height + 8.0))
        .radius_top_left(top)
        .radius_top_right(top)
        .radius_bottom_left(bottom)
        .radius_bottom_right(bottom)
        .fill(roles.surface_container_high)
        .clip()
        .child(Column::new(children![header, body]))
}

static LOADING_START: std::sync::LazyLock<Instant> = std::sync::LazyLock::new(Instant::now);

// M3 Expressive loading indicator: a rotating shape that morphs between forms
pub fn loading_indicator(color: Color, size: f32) -> Canvas {
    const LOBES: [f32; 6] = [9.0, 4.0, 6.0, 5.0, 8.0, 3.0];

    amane::request_frame();

    let cycle = (LOADING_START.elapsed().as_secs_f32() / 0.7) % LOBES.len() as f32;
    let lobes = LOBES[cycle as usize];
    let depth = 0.05 + 0.13 * (std::f32::consts::PI * cycle.fract()).sin();
    let turn = (cycle * 140.0).to_radians();

    let center = size / 2.0;
    let base = center / (1.0 + depth);
    let point = |step: usize| {
        let angle = step as f32 / 120.0 * std::f32::consts::TAU;
        let radius = base * (1.0 + depth * (lobes * angle).cos());
        (center + radius * (angle + turn).cos(), center + radius * (angle + turn).sin())
    };

    let (x, y) = point(0);
    let mut path = Path::new().move_to(x, y);
    for step in 1..=120 {
        let (x, y) = point(step);
        path = path.line_to(x, y);
    }

    Canvas::new().width(size).height(size).shapes(shapes![path.close().fill(color)])
}

// Common button with an icon and a label
pub fn button(roles: &Roles, key: &str, content: (&str, &str), size: f32, variant: Variant, on_click: impl Fn() + 'static) -> Rectangle {
    let (name, text) = content;
    let large = size >= 56.0;
    let (container, color) = variant_colors(roles, variant, false, false);

    let row = Row::new(children![
        icon(name, if large { 22.0 } else { 18.0 }, color, false),
        label(text, if large { TYPE_TITLE } else { TYPE_BODY + 1.0 }, color).weight(Weight::Bold),
    ])
    .gap(8.0)
    .align(Center);

    hoverable(Rectangle::new().width(width_of(&row) + if large { 48.0 } else { 32.0 }).height(size), key)
        .radius(size / 2.0)
        .fill(state_color(key, container, color))
        .align_child(Center, Center)
        .on_click(move |_| on_click())
        .child(row)
}

// Android-style palette swatch: one color on top, two below
pub fn swatch(size: f32, top: Color, left: Color, right: Color) -> Canvas {
    let center = size / 2.0;

    let slice = |start: f32, sweep: f32, color: Color| -> Box<dyn Shape> {
        Box::new(Path::new().move_to(center, center).arc(center, center, center, start, sweep).close().fill(color))
    };

    Canvas::new().width(size).height(size).shapes(vec![slice(270.0, 180.0, top), slice(90.0, 90.0, right), slice(180.0, 90.0, left)])
}

// Selectable filter chip: outlined at rest, tonal with a check when selected
pub fn filter_chip(roles: &Roles, key: &str, content: (&str, &str), selected: bool, on_click: Option<fn()>) -> Rectangle {
    let (name, text) = content;
    let (glyph, icon_color, text_color) = if selected {
        ("check", roles.text_on_secondary_container, roles.text_on_secondary_container)
    } else {
        (name, roles.primary, roles.text_on_surface_variant)
    };

    let content = Row::new(children![icon(glyph, 16.0, icon_color, false), label(text, TYPE_LABEL, text_color).weight(Weight::Bold)])
        .gap(8.0)
        .align(Center);

    let chip = hoverable(Rectangle::new().width(width_of(&content) + 24.0).height(32.0), key)
        .radius(SHAPE_S)
        .fill(state_color(key, if selected { roles.secondary_container } else { Color::TRANSPARENT }, text_color))
        .align_child(Center, Center)
        .child(content);
    let chip = match on_click {
        Some(clicked) => chip.on_click(move |_| clicked()),
        None => chip.cursor(amane::Cursor::Default),
    };

    if selected { chip } else { chip.border(1.0, roles.outline_variant) }
}
