// Full-screen game carousel over Slatty's library, toggled with Mod+G

use std::thread;
use std::time::Duration;

use amane::{
    Center, Image, Key, LayerWindow, Monitor, Pointer, Rectangle, Row, Service, Stack, Weight, Widget,
    children, window_size,
};

use crate::anim::{self, Motion, SPRING_FAST};
use crate::art;
use crate::m3::{self, Variant};
use crate::popups::{self, Anchor, Popup};
use crate::theme::{self, Roles, SHAPE_XL, SHAPE_XXL, TYPE_BODY, TYPE_HEADLINE, TYPE_TITLE_L, Theme};

const CARD_WIDTH: f32 = 280.0;
const CARD_HEIGHT: f32 = 420.0;
const CARD_STEP: f32 = CARD_WIDTH + 30.0;

#[derive(Clone, PartialEq)]
struct Game {
    name: String,
    art: String,
    launch: String,
}

// Installed games, as listed by the slatty-games script
#[derive(Default, PartialEq)]
pub struct Games {
    list: Vec<Game>,
}

impl Games {
    fn read_now() -> Self {
        let output = amane::output("slatty-games | jq -r '.[] | [.name, .art, .launch] | @tsv'");

        let list = output
            .lines()
            .filter_map(|line| {
                let fields: Vec<&str> = line.split('\t').collect();
                let [name, art, launch] = fields[..] else {
                    return None;
                };
                Some(Game { name: String::from(name), art: String::from(art), launch: String::from(launch) })
            })
            .collect();

        Self { list }
    }
}

fn refresh() {
    let games = Games::read_now();

    if games != *Games::read() {
        *Games::write() = games;
    }
}

impl Service for Games {
    fn new() -> Self {
        Self::default()
    }

    fn listen() {
        refresh();
    }
}

#[derive(Default)]
pub struct SteamLauncher {
    query: String,
    // none: the middle game, resolved once the list is known
    selected: Option<usize>,
}

impl SteamLauncher {
    fn selected(&self, count: usize) -> usize {
        self.selected.unwrap_or(count / 2).min(count.saturating_sub(1))
    }
}

impl Service for SteamLauncher {
    fn new() -> Self {
        Self::default()
    }

    fn interval() -> Duration {
        Duration::from_secs(3600)
    }
}

pub fn reset() {
    *SteamLauncher::write() = SteamLauncher::default();
    thread::spawn(refresh);
}

fn matching<'a>(games: &'a [Game], query: &str) -> Vec<&'a Game> {
    let query = query.to_lowercase();
    games.iter().filter(|game| game.name.to_lowercase().contains(&query)).collect()
}

fn count() -> usize {
    let query = SteamLauncher::read().query.clone();
    matching(&Games::read().list, &query).len()
}

fn current_index() -> usize {
    let count = count();
    SteamLauncher::read().selected(count)
}

fn select(index: usize) {
    let last = count().saturating_sub(1);
    SteamLauncher::write().selected = Some(index.min(last));
}

fn set_query(query: String) {
    let selected = if query.is_empty() { None } else { Some(0) };
    *SteamLauncher::write() = SteamLauncher { query, selected };
}

fn launch() {
    let index = current_index();
    let command = {
        let query = SteamLauncher::read().query.clone();
        let games = Games::read();
        matching(&games.list, &query).get(index).map(|game| game.launch.clone())
    };

    if let Some(command) = command.filter(|command| !command.is_empty()) {
        amane::spawn(&command);
        popups::close();
    }
}

fn on_key(key: Key) {
    let query = SteamLauncher::read().query.clone();

    match key {
        Key::Escape => popups::close(),
        Key::Enter => launch(),
        Key::Left | Key::Control('h') => select(current_index().saturating_sub(1)),
        Key::Right | Key::Control('l') => select(current_index() + 1),
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
    let roles = Theme::read().roles;
    let backdrop = theme::with_alpha(roles.surface_container_lowest, 0.86);

    popups::window(monitor, Popup::SteamLauncher, Anchor::Cover(backdrop), on_key, |_| {
        let (width, height) = window_size();
        let state = SteamLauncher::read();
        let games = Games::read();
        let shown = matching(&games.list, &state.query);
        let selected = state.selected(shown.len());

        let search_y = (height * 0.115).max(54.0);
        let carousel_y = (height * 0.27).round();

        let typed: Box<dyn Widget> = if state.query.is_empty() {
            Box::new(m3::label("Search games", TYPE_BODY + 1.0, roles.text_on_surface_variant))
        } else {
            Box::new(m3::label(state.query.clone(), TYPE_BODY + 1.0, roles.text_on_surface))
        };
        let caret: Box<dyn Widget> = Box::new(Rectangle::new().width(1.5).height(18.0).fill(roles.text_on_surface));
        let parts = if state.query.is_empty() { vec![caret, typed] } else { vec![typed, caret] };

        let mut layers: Vec<Box<dyn Widget>> = vec![Box::new(
            m3::search_field(&roles, 480.0, Row::new(parts).align(Center)).translate((width - 480.0) / 2.0, search_y),
        )];

        layers.extend(carousel(&roles, &shown, selected, width, carousel_y));

        let chevron_y = carousel_y + (CARD_HEIGHT + 44.0) / 2.0 - 32.0;
        layers.push(Box::new(
            m3::icon_button(&roles, "steam/previous", "chevron_left", (64.0, 64.0), Variant::Tonal, false, false, || {
                select(current_index().saturating_sub(1))
            })
            .translate(40.0, chevron_y),
        ));
        layers.push(Box::new(
            m3::icon_button(&roles, "steam/next", "chevron_right", (64.0, 64.0), Variant::Tonal, false, false, || select(current_index() + 1))
                .translate(width - 40.0 - 64.0, chevron_y),
        ));

        let title_y = carousel_y + CARD_HEIGHT + 36.0;
        let title = m3::label(shown.get(selected).map(|game| game.name.clone()).unwrap_or_default(), TYPE_HEADLINE + 6.0, roles.text_on_surface)
            .weight(Weight::ExtraBold);
        let title_height = m3::height_of(&title);
        let title_width = m3::width_of(&title).min(width - 120.0);
        layers.push(Box::new(
            Rectangle::new()
                .width(title_width)
                .height(title_height)
                .translate((width - title_width) / 2.0, title_y)
                .child(title.elide()),
        ));

        layers.push(Box::new(play_button(&roles).translate((width - 220.0) / 2.0, title_y + title_height + 24.0)));

        Stack::new(layers).width(width).height(height)
    })
}

fn play_button(roles: &Roles) -> Rectangle {
    let key = "steam/play";

    m3::hoverable(Rectangle::new().width(220.0).height(64.0), key)
        .radius(32.0)
        .fill(m3::state_color(key, roles.primary, roles.text_on_primary))
        .align_child(Center, Center)
        .on_click(|_| launch())
        .child(
            Row::new(children![
                m3::icon("play_arrow", 26.0, roles.text_on_primary, false),
                m3::label("Play", TYPE_TITLE_L, roles.text_on_primary).weight(Weight::Bold),
            ])
            .gap(8.0)
            .align(Center),
        )
}

// Cards shrink and fade with their distance from the selected one, which is drawn on top
fn carousel(roles: &Roles, shown: &[&Game], selected: usize, width: f32, y: f32) -> Vec<Box<dyn Widget>> {
    let target = width / 2.0 - (selected as f32 * CARD_STEP + CARD_WIDTH / 2.0);
    let start = anim::float("steam/offset", target, Motion::curve([0.25, 0.1, 0.25, 1.0], 220));

    let mut visible: Vec<(usize, f32)> = shown
        .iter()
        .enumerate()
        .map(|(index, _)| (index, start + index as f32 * CARD_STEP))
        .filter(|(_, x)| *x + CARD_STEP > 0.0 && *x < width)
        .collect();

    visible.sort_by_key(|(index, _)| std::cmp::Reverse(index.abs_diff(selected)));

    visible
        .into_iter()
        .map(|(index, x)| -> Box<dyn Widget> {
            let distance = index.abs_diff(selected) as f32;
            let scale = (1.0 - distance * 0.145).max(0.48);
            let opacity = (1.0 - distance * 0.17).max(0.25);

            Box::new(card(roles, shown[index], index, index == selected).scale(scale).opacity(opacity).translate(x, y))
        })
        .collect()
}

fn card(roles: &Roles, game: &Game, index: usize, selected: bool) -> Rectangle {
    let key = format!("steam/card/{}", game.name);
    let radius = anim::float(&format!("{key}/radius"), if selected { SHAPE_XXL } else { SHAPE_XL }, SPRING_FAST);

    let art = art::path(&game.art);
    let loaded = art.as_deref().is_some_and(Image::loaded);

    let mut layers: Vec<Box<dyn Widget>> = Vec::new();
    if !loaded {
        layers.push(Box::new(m3::centered(CARD_WIDTH, CARD_HEIGHT, m3::icon("sports_esports", 64.0, roles.text_on_surface_variant, false))));
    }
    if let Some(art) = art {
        layers.push(Box::new(
            Rectangle::new()
                .width(CARD_WIDTH)
                .height(CARD_HEIGHT)
                .radius(radius)
                .fill(Image::cover(art).thumbnail((CARD_WIDTH * 2.0) as u32, (CARD_HEIGHT * 2.0) as u32)),
        ));
    }
    layers.push(Box::new(m3::focus_ring(roles, &key, (0.0, 0.0), (CARD_WIDTH, CARD_HEIGHT), (radius, radius), selected)));

    Rectangle::new()
        .width(CARD_WIDTH)
        .height(CARD_HEIGHT)
        .radius(radius)
        .fill(roles.surface_container_high)
        .cursor(Pointer)
        .on_click(move |_| {
            if selected {
                launch();
            } else {
                select(index);
            }
        })
        .child(Stack::new(layers).width(CARD_WIDTH).height(CARD_HEIGHT))
}
