// Music launcher over the running Kopuz app, toggled with Mod+M

use std::thread;

use amane::{
    Center, Color, Gradient, Image, Key, LayerWindow, Monitor, Pointer, Rectangle, Row, Service, Stack, Weight, Widget,
    children, window_size,
};

use crate::anim::{self, Motion, SPRING_FAST};
use crate::art;
use crate::calendar_pages::{format_time, wavy_progress};
use crate::kopuz::{self, Item, Kind, Library, Player};
use crate::m3::{self, Grow, Variant};
use crate::popups::{self, Anchor, Popup};
use crate::theme::{
    self, Roles, SHAPE_LI, SHAPE_S, SHAPE_XL, SHAPE_XLI, TYPE_BODY, TYPE_HEADLINE, TYPE_LABEL, TYPE_TITLE, TYPE_TITLE_L, Theme,
};

const TABS: [(&str, &str); 5] =
    [("queue_music", "Playlists"), ("album", "Albums"), ("artist", "Artists"), ("music_note", "Songs"), ("favorite", "Favorites")];

const SIDE: f32 = 112.0;
const LIST_Y: f32 = 192.0;
const LIST_HEIGHT: f32 = 262.0;
const CARD: (f32, f32) = (184.0, 214.0);
const SELECTED_CARD: (f32, f32) = (236.0, 258.0);
const CARD_GAP: f32 = 20.0;
const COVER: f32 = 184.0;
// around the card list, for the focus ring of the cards at its edges
const RING_ROOM: f32 = 8.0;

// Section, search and selection stay between openings
#[derive(Default)]
pub struct MusicLauncher {
    section: usize,
    selected: usize,
    // the card selected before, still shrinking back
    previous: usize,
    query: String,
    // typing goes to the search after `/`, like in vim
    searching: bool,
}

impl Service for MusicLauncher {
    fn new() -> Self {
        Self::default()
    }

    fn listen() {}
}

pub fn reset() {
    MusicLauncher::write().searching = false;
    thread::spawn(kopuz::refresh_library);
    // started here so the first state is read while the launcher opens
    drop(Player::read());
}

fn matching<'a>(items: &'a [Item], query: &str) -> Vec<&'a Item> {
    let query = query.trim().to_lowercase();
    if query.is_empty() {
        return items.iter().collect();
    }

    items.iter().filter(|item| item.search.contains(&query)).collect()
}

fn shown_count() -> usize {
    let state = MusicLauncher::read();
    matching(&Library::read().sections[state.section], &state.query).len()
}

fn select(index: usize) {
    let mut state = MusicLauncher::write();
    if index != state.selected {
        state.previous = state.selected;
        state.selected = index;
    }
}

fn move_selection(delta: isize) {
    let count = shown_count() as isize;
    if count == 0 {
        return;
    }

    let selected = MusicLauncher::read().selected as isize;
    select((selected + delta).rem_euclid(count) as usize);
}

fn set_section(section: usize) {
    let mut state = MusicLauncher::write();
    *state = MusicLauncher { section, ..MusicLauncher::default() };
}

fn set_searching(searching: bool) {
    MusicLauncher::write().searching = searching;
}

fn set_query(query: String) {
    let mut state = MusicLauncher::write();
    state.query = query;
    state.selected = 0;
    state.previous = 0;
}

// Songs play from the clicked one through the shown list, collections from a random track
fn play(index: usize) {
    select(index);

    let (item, keys) = {
        let state = MusicLauncher::read();
        let library = Library::read();
        let shown = matching(&library.sections[state.section], &state.query);
        let Some(item) = shown.get(index).map(|item| (*item).clone()) else {
            return;
        };
        let keys: Vec<String> = shown.iter().map(|item| item.id.clone()).collect();
        (item, keys)
    };

    if item.kind == Kind::Song {
        kopuz::play_songs(&keys, index);
    } else {
        kopuz::play_collection(&item);
    }
}

fn on_key(key: Key) {
    let (query, searching) = {
        let state = MusicLauncher::read();
        (state.query.clone(), state.searching)
    };

    match key {
        Key::Escape if searching => {
            set_query(String::new());
            set_searching(false);
        }
        Key::Escape => popups::close(),
        Key::Enter if searching => set_searching(false),
        Key::Control(' ') => kopuz::toggle(),
        Key::Enter => {
            // read apart: a guard inside the call would live through play(), which writes the state
            let selected = MusicLauncher::read().selected;
            play(selected);
        }
        Key::Control('n') => kopuz::next(),
        Key::Control('p') => kopuz::previous(),
        Key::Control('-') => kopuz::adjust_volume(-0.1),
        Key::Control('=') => kopuz::adjust_volume(0.1),
        Key::Control(digit @ '1'..='5') => set_section(digit as usize - '1' as usize),
        Key::Left | Key::Up | Key::Control('h') | Key::Control('k') => move_selection(-1),
        Key::Right | Key::Down | Key::Control('l') | Key::Control('j') => move_selection(1),
        Key::Backspace if searching && query.is_empty() => set_searching(false),
        Key::Backspace if searching => {
            let mut query = query;
            query.pop();
            set_query(query);
        }
        Key::Space if searching => set_query(query + " "),
        Key::Character(letter) if searching => set_query(format!("{query}{letter}")),
        Key::Character('/') => set_searching(true),
        Key::Space => kopuz::toggle(),
        Key::Character('n') => kopuz::next(),
        Key::Character('p') => kopuz::previous(),
        Key::Character(digit @ '1'..='5') => set_section(digit as usize - '1' as usize),
        Key::Tab => {
            let section = MusicLauncher::read().section;
            set_section((section + 1) % TABS.len());
        }
        Key::Character('-') => kopuz::adjust_volume(-0.1),
        Key::Character('=') => kopuz::adjust_volume(0.1),
        _ => {}
    }
}

pub fn view(monitor: &Monitor) -> LayerWindow {
    popups::window(monitor, Popup::MusicLauncher, Anchor::Modal, on_key, |context| {
        let roles = Theme::read().roles;
        let (width, height) = window_size();
        let size = ((width - 96.0).min(1360.0), (height - 126.0).min(800.0));

        let content = panel(&roles, size);

        m3::surface(&roles, size, SHAPE_XLI, false, Grow::Center, context.opened, content)
    })
}

fn panel(roles: &Roles, size: (f32, f32)) -> Stack {
    let (width, height) = size;
    let state = MusicLauncher::read();
    let library = Library::read();
    let shown = matching(&library.sections[state.section], &state.query);
    let selected = state.selected.min(shown.len().saturating_sub(1));

    let mut layers: Vec<Box<dyn Widget>> = Vec::new();

    let search_width = (width * 0.5).min(640.0);
    layers.push(Box::new(search(roles, &state.query, state.searching, search_width).translate((width - search_width) / 2.0, 28.0)));

    let tabs_width = 5.0 * 150.0 + 4.0 * 2.0;
    layers.push(Box::new(place(tabs(roles, state.section), (width - tabs_width) / 2.0, 96.0)));

    let count = m3::label(format!("{} items", shown.len()), TYPE_LABEL, roles.text_on_surface_variant);
    let count_y = LIST_Y - 8.0 - m3::height_of(&count);
    layers.push(Box::new(place(count, SIDE, count_y)));

    let list_width = width - 2.0 * SIDE;
    layers.push(Box::new(cards(roles, &shown, (state.section, selected, state.previous), list_width).translate(SIDE - RING_ROOM, LIST_Y - RING_ROOM)));

    let chevron_y = LIST_Y + LIST_HEIGHT / 2.0 - 24.0;
    layers.push(Box::new(
        m3::icon_button(roles, "music/previous", "chevron_left", (48.0, 48.0), Variant::Tonal, false, false, || move_selection(-1))
            .translate(40.0, chevron_y),
    ));
    layers.push(Box::new(
        m3::icon_button(roles, "music/next", "chevron_right", (48.0, 48.0), Variant::Tonal, false, false, || move_selection(1))
            .translate(width - 40.0 - 48.0, chevron_y),
    ));

    let top = LIST_Y + LIST_HEIGHT + 36.0;
    layers.extend(now_playing(roles, (SIDE, top), (width - 2.0 * SIDE, height - 28.0 - top), &library));

    Stack::new(layers).width(width).height(height)
}

// The caret shows while typing goes to the search
fn search(roles: &Roles, query: &str, searching: bool, width: f32) -> Rectangle {
    let typed: Box<dyn Widget> = if query.is_empty() {
        Box::new(m3::label("Search music", TYPE_BODY + 1.0, roles.text_on_surface_variant))
    } else {
        Box::new(m3::label(query, TYPE_BODY + 1.0, roles.text_on_surface))
    };
    let parts = if searching {
        let caret: Box<dyn Widget> = Box::new(Rectangle::new().width(1.5).height(18.0).fill(roles.text_on_surface));
        if query.is_empty() { vec![caret, typed] } else { vec![typed, caret] }
    } else {
        vec![typed]
    };

    m3::search_field(roles, width, Row::new(parts).align(Center)).on_click(|_| set_searching(true))
}

// Connected tonal toggle buttons; the checked one turns fully round
fn tabs(roles: &Roles, section: usize) -> Row {
    let buttons: Vec<Box<dyn Widget>> = TABS
        .iter()
        .enumerate()
        .map(|(index, (name, text))| -> Box<dyn Widget> {
            let key = format!("music/tab/{index}");
            let checked = index == section;
            let (container, content) = if checked {
                (roles.secondary, roles.text_on_secondary)
            } else {
                (roles.secondary_container, roles.text_on_secondary_container)
            };

            let inner = anim::float(&format!("{key}/inner"), if checked { 24.0 } else { SHAPE_S }, SPRING_FAST);
            let left = if index == 0 { 24.0 } else { inner };
            let right = if index == TABS.len() - 1 { 24.0 } else { inner };

            Box::new(
                m3::hoverable(Rectangle::new().width(150.0).height(48.0), &key)
                    .radius_top_left(left)
                    .radius_bottom_left(left)
                    .radius_top_right(right)
                    .radius_bottom_right(right)
                    .fill(m3::state_color(&key, container, content))
                    .align_child(Center, Center)
                    .on_click(move |_| set_section(index))
                    .child(
                        Row::new(children![
                            m3::icon(name, 18.0, content, checked),
                            m3::label(*text, TYPE_BODY + 1.0, content).weight(Weight::Bold),
                        ])
                        .gap(8.0)
                        .align(Center),
                    ),
            )
        })
        .collect();

    Row::new(buttons).gap(2.0)
}

// Horizontal list keeping the selected card centered, clipped to the space between the chevrons
fn cards(roles: &Roles, shown: &[&Item], selection: (usize, usize, usize), width: f32) -> Rectangle {
    const STEP: f32 = CARD.0 + CARD_GAP;
    let (section, selected, previous) = selection;
    let key = |index: usize| format!("music/card/{section}/{index}");

    // only the selected card and the one it replaced are not at rest
    let grow = |index: usize| {
        let target = if index == selected { SELECTED_CARD.0 } else { CARD.0 };
        anim::float(&format!("{}/width", key(index)), target, SPRING_FAST)
    };
    let selected_width = grow(selected);
    let previous_width = if previous == selected { selected_width } else { grow(previous) };
    let width_of = |index: usize| match index {
        _ if index == selected => selected_width,
        _ if index == previous => previous_width,
        _ => CARD.0,
    };
    let x_of = |index: usize| {
        let mut x = index as f32 * STEP;
        if selected < index {
            x += selected_width - CARD.0;
        }
        if previous != selected && previous < index {
            x += previous_width - CARD.0;
        }
        x
    };

    let total = shown.len() as f32 * STEP - CARD_GAP + (SELECTED_CARD.0 - CARD.0);
    let target = (width / 2.0 - (selected as f32 * STEP + SELECTED_CARD.0 / 2.0)).clamp((width - total).min(0.0), 0.0);
    let offset = anim::float("music/offset", target, Motion::curve([0.25, 0.1, 0.25, 1.0], 160));

    // the cards that can reach the list, the grown ones shifting the others by at most `slack`
    let slack = 2.0 * (SELECTED_CARD.0 - CARD.0);
    let first = ((-offset - RING_ROOM - SELECTED_CARD.0 - slack) / STEP).floor().max(0.0) as usize;
    let last = ((((width + RING_ROOM - offset) / STEP).ceil().max(0.0) as usize) + 1).min(shown.len());

    let mut layers: Vec<Box<dyn Widget>> = Vec::new();
    for (index, item) in shown.iter().enumerate().take(last).skip(first) {
        let x = offset + x_of(index);
        if x > width + RING_ROOM || x + SELECTED_CARD.0 < -RING_ROOM {
            continue;
        }

        let card_width = width_of(index);
        layers.push(Box::new(card(roles, item, &key(index), (index, x + RING_ROOM), card_width, index == selected)));
    }

    // a little larger than the cards, so the focus ring is not cut
    let size = (width + 2.0 * RING_ROOM, LIST_HEIGHT + 2.0 * RING_ROOM);
    Rectangle::new().width(size.0).height(size.1).clip().child(Stack::new(layers).width(size.0).height(size.1))
}

// `x` is where the card starts; it is centered vertically in the list
fn card(roles: &Roles, item: &Item, key: &str, (index, x): (usize, f32), width: f32, selected: bool) -> Rectangle {
    let height = anim::float(&format!("{key}/height"), if selected { SELECTED_CARD.1 } else { CARD.1 }, SPRING_FAST);
    let radius = anim::float(&format!("{key}/radius"), if selected { SHAPE_XL } else { SHAPE_LI }, SPRING_FAST);
    let margin = if selected { 20.0 } else { 16.0 };

    let art = art::path(&item.art);
    let loaded = art.as_deref().is_some_and(Image::loaded);

    let mut layers: Vec<Box<dyn Widget>> = Vec::new();
    if !loaded {
        let name = if item.kind == Kind::Artist { "artist" } else { "music_note" };
        layers.push(Box::new(m3::centered(width, height, m3::icon(name, 56.0, roles.text_on_surface_variant, false)).translate(0.0, -20.0)));
    }
    if let Some(art) = art {
        layers.push(Box::new(
            Rectangle::new()
                .width(width)
                .height(height)
                .radius(radius)
                .fill(Image::cover(art).thumbnail((SELECTED_CARD.0 * 2.0) as u32, (SELECTED_CARD.1 * 2.0) as u32)),
        ));
    }

    // fades to the surface at the bottom, under the titles
    let shade = roles.surface_container_lowest;
    layers.push(Box::new(
        Rectangle::new()
            .width(width)
            .height(height)
            .radius(radius)
            .fill(Gradient::linear(0.0, [(0.0, theme::with_alpha(shade, 0.92)), (0.55, theme::with_alpha(shade, 0.0))])),
    ));
    layers.push(Box::new(Rectangle::new().width(width).height(height).radius(radius).fill(m3::state_color(key, Color::TRANSPARENT, roles.text_on_surface))));
    layers.push(Box::new(m3::focus_ring(roles, key, (0.0, 0.0), (width, height), (radius, radius), selected)));

    let title = m3::label(item.title.clone(), if selected { TYPE_TITLE_L } else { TYPE_BODY + 1.0 }, roles.text_on_surface)
        .weight(Weight::Bold)
        .elide();
    let subtitle = m3::label(item.subtitle.clone(), TYPE_LABEL, roles.text_on_surface_variant).elide();
    let (title_height, subtitle_height) = (m3::height_of(&title), m3::height_of(&subtitle));
    let text_width = width - 2.0 * margin;
    let text_y = height - margin - subtitle_height - 2.0 - title_height;

    layers.push(Box::new(Rectangle::new().width(text_width).height(title_height).translate(margin, text_y).child(title)));
    layers.push(Box::new(
        Rectangle::new().width(text_width).height(subtitle_height).translate(margin, text_y + title_height + 2.0).child(subtitle),
    ));

    m3::hoverable(Rectangle::new().width(width).height(height), key)
        .radius(radius)
        .fill(roles.surface_container_highest)
        .translate(x, RING_ROOM + (LIST_HEIGHT - height) / 2.0)
        .cursor(Pointer)
        .on_click(move |_| play(index))
        .child(Stack::new(layers).width(width).height(height))
}

// Cover, titles, progress and controls of what Kopuz plays
fn now_playing(roles: &Roles, origin: (f32, f32), size: (f32, f32), library: &Library) -> Vec<Box<dyn Widget>> {
    let ((x, y), (width, height)) = (origin, size);
    let player = Player::read().clone();
    let mut layers: Vec<Box<dyn Widget>> = Vec::new();

    let cover = player.track.as_ref().and_then(|track| art::path(&track.art));
    let loaded = cover.as_deref().is_some_and(Image::loaded);
    let mut cover_layers: Vec<Box<dyn Widget>> = Vec::new();
    if !loaded {
        cover_layers.push(Box::new(m3::centered(COVER, COVER, m3::icon("music_note", 64.0, roles.text_on_surface_variant, false))));
    }
    if let Some(cover) = cover {
        cover_layers.push(Box::new(
            Rectangle::new().width(COVER).height(COVER).radius(SHAPE_XL).fill(Image::cover(cover).thumbnail((COVER * 2.0) as u32, (COVER * 2.0) as u32)),
        ));
    }
    layers.push(Box::new(
        Rectangle::new()
            .width(COVER)
            .height(COVER)
            .radius(SHAPE_XL)
            .fill(roles.surface_container_highest)
            .translate(x, y + (height - COVER) / 2.0)
            .child(Stack::new(cover_layers).width(COVER).height(COVER)),
    ));

    let left = x + COVER + 36.0;
    let column = width - COVER - 36.0;

    let status = m3::label(if player.track.is_some() { "Now playing" } else { "Ready" }, TYPE_LABEL, roles.primary).weight(Weight::Bold);
    let chip = m3::filter_chip(roles, "music/source", ("close", if player.connected { "Kopuz" } else { "Disconnected" }), player.connected, None);
    let chip_width = m3::width_of(&chip);
    let status_y = y + (32.0 - m3::height_of(&status)) / 2.0;
    layers.push(Box::new(place(status, left, status_y)));
    layers.push(Box::new(chip.translate(left + column - chip_width, y)));

    let (title, subtitle) = match &player.track {
        Some(track) => (
            track.title.clone(),
            [track.artist.as_str(), track.album.as_str()].iter().filter(|text| !text.is_empty()).copied().collect::<Vec<_>>().join(" - "),
        ),
        None => (String::from("Nothing playing"), String::from("Choose a playlist, album, artist, song, or favorite")),
    };
    let title = m3::label(title, TYPE_HEADLINE + 6.0, roles.text_on_surface).weight(Weight::ExtraBold).elide();
    let title_height = m3::height_of(&title);
    let title_y = y + 32.0 + 6.0;
    layers.push(Box::new(Rectangle::new().width(column).height(title_height).translate(left, title_y).child(title)));

    let subtitle = m3::label(subtitle, TYPE_TITLE, roles.text_on_surface_variant).elide();
    let subtitle_height = m3::height_of(&subtitle);
    layers.push(Box::new(Rectangle::new().width(column).height(subtitle_height).translate(left, title_y + title_height + 6.0).child(subtitle)));

    let controls_y = y + height - 72.0;
    let favorite = player.track.as_ref().is_some_and(|track| library.is_favorite(&track.key));
    let controls = Row::new(children![
        m3::icon_button(roles, "music/shuffle", "shuffle", (48.0, 48.0), Variant::Tonal, true, player.shuffle, kopuz::toggle_shuffle),
        m3::icon_button(roles, "music/skip-previous", "skip_previous", (56.0, 56.0), Variant::Tonal, false, false, kopuz::previous),
        m3::icon_button(
            roles,
            "music/play",
            if player.playing { "pause" } else { "play_arrow" },
            (104.0, 72.0),
            Variant::Filled,
            true,
            player.playing,
            kopuz::toggle,
        ),
        m3::icon_button(roles, "music/skip-next", "skip_next", (56.0, 56.0), Variant::Tonal, false, false, kopuz::next),
        m3::icon_button(roles, "music/favorite", "favorite", (48.0, 48.0), Variant::Tonal, true, favorite, kopuz::toggle_favorite),
    ])
    .gap(10.0)
    .align(Center);
    let controls_width = m3::width_of(&controls);
    layers.push(Box::new(place(controls, left + (column - controls_width) / 2.0, controls_y)));

    let position = m3::label(format_time(player.position()), TYPE_LABEL, roles.text_on_surface_variant);
    let length = m3::label(format_time(player.length), TYPE_LABEL, roles.text_on_surface_variant);
    let (position_width, length_width) = (m3::width_of(&position), m3::width_of(&length));
    let wave_width = column - position_width - length_width - 32.0;
    let value = if player.length.is_zero() { 0.0 } else { player.position().as_secs_f32() / player.length.as_secs_f32() };
    let wave = wavy_progress(roles, wave_width, value, player.playing);
    let row_height = m3::height_of(&wave).max(m3::height_of(&position));
    let progress_y = controls_y - 12.0 - row_height;

    layers.push(Box::new(
        place(Row::new(children![position, wave, length]).gap(16.0).align(Center).height(row_height), left, progress_y),
    ));

    layers
}

// Places a widget of known size at (x, y)
fn place(widget: impl Widget + 'static, x: f32, y: f32) -> Rectangle {
    Rectangle::new().width(m3::width_of(&widget)).height(m3::height_of(&widget)).translate(x, y).child(widget)
}
