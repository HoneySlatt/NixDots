// Calendar popup opened from the clock: overview, media, wallpapers and themes

use std::fs;
use std::thread;
use std::time::Duration;

use amane::{
    Center, Color, Column, Key, LayerWindow, Media, Monitor, Padding, Parent, Path, Rectangle,
    Row, Service, Shape, Stack, Start, Weight, Widget, children, shapes,
};

use crate::anim::{self, EFFECTS, SPRING_FAST};
use crate::calendar_pages;
use crate::m3::{self, Grow, Variant};
use crate::popups::{self, Anchor, Popup};
use crate::system::{self, DISTRO_ICON, History, Load};
use crate::theme::{
    self, Roles, SHAPE_XL, SHAPE_XLI, SYMBOL_FONT, TYPE_BODY, TYPE_HEADLINE, TYPE_LABEL, TYPE_TITLE, TYPE_TITLE_L, Theme,
};

const WIDTH: f32 = 920.0;
const HEIGHT: f32 = 540.0;
const RAIL: f32 = 96.0;
pub const CONTENT_WIDTH: f32 = WIDTH - 8.0 - 16.0 - RAIL - 12.0;
pub const CONTENT_HEIGHT: f32 = HEIGHT - 2.0 * 16.0;
const HEADER: f32 = 88.0;

#[derive(Clone, Copy, PartialEq, Default)]
pub enum Tab {
    #[default]
    Overview,
    Media,
    Walls,
    Themes,
}

#[derive(Default)]
pub struct Calendar {
    pub tab: Tab,
    // the month shown by the grid, none for the current one
    shown: Option<(i32, u32)>,
    pub page: usize,
    pub selected_wallpaper: String,
}

impl Service for Calendar {
    fn new() -> Self {
        Self::default()
    }

    fn interval() -> Duration {
        Duration::from_secs(3600)
    }
}

pub fn active(tab: Tab) -> bool {
    popups::is_open(Popup::Calendar) && Calendar::read().tab == tab
}

pub fn reset() {
    {
        let mut state = Calendar::write();
        state.tab = Tab::Overview;
        state.shown = None;
    }
    thread::spawn(|| {
        let now = Now::read_now();
        *Now::write() = now;
    });
}

fn set_tab(tab: Tab) {
    let mut state = Calendar::write();
    state.tab = tab;
    state.shown = None;
}

// The current date and time, refreshed every second while the popup is open
#[derive(Default, PartialEq)]
pub struct Now {
    hour: String,
    minute: String,
    weekday: String,
    day: u32,
    month: u32,
    year: i32,
    uptime: String,
}

impl Now {
    fn read_now() -> Self {
        let output = amane::output("date '+%H %M %a %d %m %Y'");
        let parts: Vec<&str> = output.split_whitespace().collect();

        let seconds = fs::read_to_string("/proc/uptime")
            .ok()
            .and_then(|text| text.split('.').next()?.parse::<u64>().ok())
            .unwrap_or_default();

        let [hour, minute, weekday, day, month, year] = parts[..] else {
            return Self::default();
        };

        Self {
            hour: String::from(hour),
            minute: String::from(minute),
            weekday: format!("{weekday} {day}"),
            day: day.parse().unwrap_or_default(),
            month: month.parse().unwrap_or_default(),
            year: year.parse().unwrap_or_default(),
            uptime: format!("{}h {}m", seconds / 3600, seconds % 3600 / 60),
        }
    }
}

impl Service for Now {
    fn new() -> Self {
        Self::default()
    }

    fn listen() {
        system::poll(Duration::from_secs(1), || popups::is_open(Popup::Calendar), Self::read_now);
    }
}

#[derive(PartialEq)]
pub struct Weather {
    temperature: String,
    description: String,
    icon: &'static str,
}

// wttr.in weather codes to Material Symbols
fn weather_icon(code: u32) -> &'static str {
    match code {
        113 => "sunny",
        116 => "partly_cloudy_day",
        119 | 122 => "cloud",
        143 | 248 | 260 => "foggy",
        176 | 263 | 266 | 293 | 296 => "rainy_light",
        299 | 302 | 305 | 308 | 356 | 359 => "rainy_heavy",
        200 | 386 | 389 | 392 | 395 => "thunderstorm",
        179 | 182 | 185 | 227 | 230 | 281 | 284 | 311 | 314 | 317 | 323 | 326 | 329 | 332 | 335 | 338 | 350 | 362
        | 365 | 368 | 371 | 374 | 377 => "weather_snowy",
        _ => "cloud",
    }
}

impl Service for Weather {
    fn new() -> Self {
        Self { temperature: String::from("--"), description: String::from("Loading..."), icon: "cloud" }
    }

    // fetched now, then every 15 minutes
    fn listen() {
        loop {
            let output = amane::output(
                "curl -sf 'wttr.in/?format=j1' | jq -r '.current_condition[0] | [.temp_C, .weatherDesc[0].value, .weatherCode] | @tsv'",
            );
            let fields: Vec<&str> = output.split('\t').collect();

            let weather = match fields[..] {
                [temperature, description, code] => Self {
                    temperature: format!("{temperature}\u{b0}C"),
                    description: String::from(description),
                    icon: weather_icon(code.parse().unwrap_or_default()),
                },
                _ => Self { temperature: String::from("--"), description: String::from("Unavailable"), icon: "cloud" },
            };

            if weather != *Self::read() {
                *Self::write() = weather;
            }

            thread::sleep(Duration::from_secs(900));
        }
    }
}

fn hostname() -> String {
    fs::read_to_string("/etc/hostname").map_or_else(|_| String::from("System"), |name| String::from(name.trim()))
}

fn on_key(key: Key) {
    if key == Key::Escape {
        popups::close();
    }
}

pub fn view(monitor: &Monitor) -> LayerWindow {
    popups::window(monitor, Popup::Calendar, Anchor::Top, on_key, |context| {
        let roles = Theme::read().roles;
        let tab = Calendar::read().tab;

        let page: Box<dyn Widget> = match tab {
            Tab::Overview => Box::new(overview(&roles)),
            Tab::Media => Box::new(calendar_pages::media(&roles)),
            Tab::Walls => Box::new(calendar_pages::wallpapers(&roles)),
            Tab::Themes => Box::new(calendar_pages::themes(&roles)),
        };

        let content = Rectangle::new()
            .width(Parent)
            .height(Parent)
            .padding(Padding { top: 16.0, right: 16.0, bottom: 16.0, left: 8.0 })
            .child(Row::new(vec![Box::new(rail(&roles, tab)), page]).gap(12.0));

        m3::surface(
            &roles,
            (WIDTH, HEIGHT),
            SHAPE_XLI,
            !context.top,
            if context.top { Grow::Top } else { Grow::Bottom },
            context.opened,
            content,
        )
    })
}

fn rail(roles: &Roles, tab: Tab) -> Rectangle {
    let now = Now::read();
    let active = tab == Tab::Overview;

    let (big, small) = if active {
        (roles.text_on_primary, roles.text_on_primary)
    } else {
        (roles.primary, roles.text_on_surface_variant)
    };

    let digits = |text: &str| m3::label(text, 44.0, big).weight(Weight::ExtraBold);
    let clock = Column::new(children![
        digits(&now.hour),
        digits(&now.minute),
        Rectangle::new().width(1.0).height(10.0),
        m3::label(now.weekday.clone(), TYPE_LABEL, small).weight(Weight::Bold),
    ])
    .gap(-6.0)
    .align(Center);

    let key = "calendar/clock-tab";
    let clock_tab = m3::hoverable(Rectangle::new().width(80.0).height(156.0), key)
        .radius(anim::float(&format!("{key}/radius"), if active { SHAPE_XL } else { 40.0 }, SPRING_FAST))
        .fill(m3::state_color(
            key,
            if active { roles.primary } else { Color::TRANSPARENT },
            if active { roles.text_on_primary } else { roles.text_on_surface },
        ))
        .align_child(Center, Center)
        .on_click(|_| set_tab(Tab::Overview))
        .child(clock);

    let mut items: Vec<Box<dyn Widget>> = vec![Box::new(clock_tab), Box::new(Rectangle::new().width(1.0).height(6.0))];

    for (name, text, target) in [("music_note", "Media", Tab::Media), ("wallpaper", "Walls", Tab::Walls), ("palette", "Themes", Tab::Themes)] {
        items.push(Box::new(nav_item(roles, name, text, tab == target, move || set_tab(target))));
    }

    Rectangle::new()
        .width(RAIL)
        .height(CONTENT_HEIGHT)
        .padding(Padding { top: 4.0, right: 0.0, bottom: 0.0, left: 0.0 })
        .child(Column::new(items).width(RAIL).gap(14.0).align(Center))
}

// Navigation rail destination: pill indicator that expands from the center
fn nav_item(roles: &Roles, name: &str, text: &str, active: bool, on_click: impl Fn() + 'static) -> Rectangle {
    let key = format!("calendar/nav/{text}");
    let pill = anim::float(&format!("{key}/pill"), if active { 56.0 } else { 24.0 }, SPRING_FAST);
    let pill_opacity = anim::float(&format!("{key}/pill-opacity"), if active { 1.0 } else { 0.0 }, EFFECTS);
    let hover = anim::float(&format!("{key}/hover"), if anim::hovered(&key) { theme::STATE_HOVER } else { 0.0 }, EFFECTS);

    let indicator = Stack::new(children![
        Rectangle::new()
            .width(pill)
            .height(32.0)
            .translate((56.0 - pill) / 2.0, 0.0)
            .radius(16.0)
            .fill(roles.secondary_container)
            .opacity(pill_opacity),
        Rectangle::new().width(56.0).height(32.0).radius(16.0).fill(theme::with_alpha(roles.text_on_surface, hover)),
        m3::centered(
            56.0,
            32.0,
            m3::icon(name, 20.0, if active { roles.text_on_secondary_container } else { roles.text_on_surface_variant }, active),
        ),
    ])
    .width(56.0)
    .height(32.0);

    let caption = m3::label(text, TYPE_LABEL, if active { roles.text_on_surface } else { roles.text_on_surface_variant })
        .weight(if active { Weight::Bold } else { Weight::SemiBold });

    m3::hoverable(Rectangle::new().width(80.0).height(56.0), &key)
        .align_child(Center, Start)
        .on_click(move |_| on_click())
        .child(Column::new(children![indicator, caption]).gap(4.0).align(Center))
}

pub fn card(width: f32, height: f32, roles: &Roles) -> Rectangle {
    Rectangle::new().width(width).height(height).radius(SHAPE_XL).fill(roles.surface_container_high)
}

// Rounded polar shape from the M3 Expressive shape library (cookie, flower...)
pub fn polar_shape(size: f32, lobes: f32, depth: f32, color: Color) -> amane::Canvas {
    let center = size / 2.0;
    let base = center / (1.0 + depth);
    let point = |step: usize| {
        let angle = step as f32 / 120.0 * std::f32::consts::TAU;
        let radius = base * (1.0 + depth * (lobes * angle).cos());
        (center + radius * angle.cos(), center + radius * angle.sin())
    };

    let (x, y) = point(0);
    let path = (1..=120).fold(Path::new().move_to(x, y), |path, step| {
        let (x, y) = point(step);
        path.line_to(x, y)
    });

    amane::Canvas::new().width(size).height(size).shapes(shapes![path.close().fill(color)])
}

// Circular image with a fallback icon
pub fn round_image(size: f32, path: Option<String>, fallback: &str, roles: &Roles) -> Rectangle {
    let shown = path.as_deref().is_some_and(|path| fs::metadata(path).is_ok());
    let circle = Rectangle::new().width(size).height(size).radius(size / 2.0).fill(roles.surface_container_highest);

    match path {
        Some(path) if shown => circle.child(
            Rectangle::new()
                .width(size)
                .height(size)
                .radius(size / 2.0)
                .fill(amane::Image::cover(path).thumbnail((size * 2.0) as u32, (size * 2.0) as u32)),
        ),
        _ => circle.align_child(Center, Center).child(m3::icon(fallback, size * 0.4, roles.text_on_surface_variant, false)),
    }
}

fn media_buttons(roles: &Roles) -> Row {
    let playing = Media::read().playing();

    Row::new(children![
        m3::icon_button(roles, "calendar/previous", "skip_previous", (40.0, 40.0), Variant::Standard, false, false, Media::previous),
        m3::icon_button(
            roles,
            "calendar/play",
            if playing { "pause" } else { "play_arrow" },
            (48.0, 48.0),
            Variant::Filled,
            true,
            playing,
            Media::play_pause,
        ),
        m3::icon_button(roles, "calendar/next", "skip_next", (40.0, 40.0), Variant::Standard, false, false, Media::next),
    ])
    .gap(4.0)
    .align(Center)
}

fn overview(roles: &Roles) -> Column {
    const WEATHER_WIDTH: f32 = 270.0;

    let weather = Weather::read();
    let now = Now::read();

    let weather_card = card(WEATHER_WIDTH, HEADER, roles).padding(m3::horizontal(16.0, 20.0)).align_child(Start, Center).child(
        Row::new(children![
            Stack::new(children![
                polar_shape(56.0, 9.0, 0.07, roles.tertiary_container),
                m3::centered(56.0, 56.0, m3::icon(weather.icon, 26.0, roles.text_on_tertiary_container, false)),
            ])
            .width(56.0)
            .height(56.0),
            Column::new(children![
                m3::label(weather.temperature.clone(), TYPE_HEADLINE, roles.text_on_surface).weight(Weight::Bold),
                m3::label(weather.description.clone(), TYPE_LABEL, roles.text_on_surface_variant).elide(),
            ])
            .width(Parent),
        ])
        .width(Parent)
        .gap(14.0)
        .align(Center),
    );

    let wm = std::env::var("XDG_CURRENT_DESKTOP").unwrap_or_else(|_| String::from("Unknown"));
    let subtitle = Row::new(children![
        amane::Text::new(DISTRO_ICON.to_string()).font(SYMBOL_FONT).size(TYPE_LABEL).color(roles.text_on_surface_variant),
        m3::label(format!(" on {wm}  \u{2022}  up {}", now.uptime), TYPE_LABEL, roles.text_on_surface_variant).elide(),
    ])
    .width(Parent)
    .align(Center);

    let avatar = format!("{}/Pictures/Others/Honey.png", theme::home());
    let profile_card = card(CONTENT_WIDTH - WEATHER_WIDTH - 12.0, HEADER, roles).padding(m3::horizontal(16.0, 16.0)).align_child(Start, Center).child(
        Row::new(children![
            round_image(56.0, Some(avatar), "person", roles),
            Column::new(children![m3::label("Honey", TYPE_TITLE_L, roles.text_on_surface).weight(Weight::Bold), subtitle]).width(Parent),
            media_buttons(roles),
        ])
        .width(Parent)
        .gap(14.0)
        .align(Center),
    );

    let page_height = CONTENT_HEIGHT - HEADER - 12.0;

    Column::new(children![
        Row::new(children![weather_card, profile_card]).gap(12.0),
        Row::new(children![month_card(roles, &now, page_height), stats_card(roles, page_height)]).gap(12.0),
    ])
    .width(CONTENT_WIDTH)
    .gap(12.0)
}

fn days_in_month(year: i32, month: u32) -> u32 {
    match month {
        2 if (year % 4 == 0 && year % 100 != 0) || year % 400 == 0 => 29,
        2 => 28,
        4 | 6 | 9 | 11 => 30,
        _ => 31,
    }
}

// 0 for Sunday
fn weekday(year: i32, month: u32, day: u32) -> u32 {
    const OFFSETS: [i32; 12] = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4];

    let year = if month < 3 { year - 1 } else { year };
    (year + year / 4 - year / 100 + year / 400 + OFFSETS[month as usize - 1] + day as i32).rem_euclid(7) as u32
}

fn shift_month(delta: i32) {
    let now = Now::read();
    let mut state = Calendar::write();

    let (year, month) = state.shown.unwrap_or((now.year, now.month));
    let index = year * 12 + month as i32 - 1 + delta;

    state.shown = Some((index.div_euclid(12), index.rem_euclid(12) as u32 + 1));
}

fn month_card(roles: &Roles, now: &Now, height: f32) -> Rectangle {
    const MONTHS: [&str; 12] = [
        "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December",
    ];

    let width = CONTENT_WIDTH - 170.0 - 12.0;
    let inner = width - 36.0;
    let card = card(width, height, roles).padding(Padding { top: 14.0, right: 18.0, bottom: 18.0, left: 18.0 });

    if now.month == 0 {
        return card;
    }

    let (year, month) = Calendar::read().shown.unwrap_or((now.year, now.month));

    let header = Row::new(children![
        Rectangle::new().width(Parent).height(40.0).padding(m3::horizontal(6.0, 0.0)).align_child(Start, Center).child(
            m3::label(format!("{} {year}", MONTHS[month as usize - 1]), TYPE_TITLE_L, roles.text_on_surface).weight(Weight::Bold),
        ),
        m3::icon_button(roles, "calendar/month-previous", "chevron_left", (40.0, 40.0), Variant::Standard, false, false, || shift_month(-1)),
        m3::icon_button(roles, "calendar/month-next", "chevron_right", (40.0, 40.0), Variant::Standard, false, false, || shift_month(1)),
    ])
    .width(inner)
    .height(40.0)
    .align(Center);

    let cell_width = inner / 7.0;
    let names = Row::new(
        ["M", "T", "W", "T", "F", "S", "S"]
            .into_iter()
            .map(|name| -> Box<dyn Widget> {
                Box::new(m3::centered(cell_width, 22.0, m3::label(name, TYPE_LABEL, roles.text_on_surface_variant).weight(Weight::Bold)))
            })
            .collect(),
    );

    // days of the previous month, this month, then the next one, in rows of seven
    let previous_days = days_in_month(if month == 1 { year - 1 } else { year }, if month == 1 { 12 } else { month - 1 });
    // weeks start on Monday
    let start = (weekday(year, month, 1) + 6) % 7;
    let mut days: Vec<(u32, bool)> = (0..start).rev().map(|back| (previous_days - back, false)).collect();
    days.extend((1..=days_in_month(year, month)).map(|day| (day, true)));
    let rows = days.len().div_ceil(7).max(5);
    let mut next = 1;
    while days.len() < rows * 7 {
        days.push((next, false));
        next += 1;
    }

    let grid_height = height - 14.0 - 18.0 - 78.0;
    let cell_height = grid_height / rows as f32;
    let current_month = year == now.year && month == now.month;

    let mut lines: Vec<Box<dyn Widget>> = Vec::new();
    for (row, week) in days.chunks(7).enumerate() {
        let cells: Vec<Box<dyn Widget>> = week
            .iter()
            .enumerate()
            .map(|(column, &(day, current))| -> Box<dyn Widget> {
                Box::new(day_cell(roles, (day, current), current_month && current && day == now.day, (cell_width, cell_height), row * 7 + column))
            })
            .collect();
        lines.push(Box::new(Row::new(cells)));
    }

    card.child(Column::new(children![header, names, Column::new(lines)]).width(inner).gap(8.0))
}

fn day_cell(roles: &Roles, day: (u32, bool), today: bool, size: (f32, f32), index: usize) -> Rectangle {
    let (number, current) = day;
    let (width, height) = size;
    let key = format!("calendar/day/{index}");

    let color = if today {
        roles.text_on_primary
    } else if current {
        roles.text_on_surface
    } else {
        theme::with_alpha(roles.outline, 0.6)
    };
    let text = m3::label(number.to_string(), TYPE_BODY + 1.0, color).weight(if today { Weight::ExtraBold } else { Weight::SemiBold });

    let mut layers: Vec<Box<dyn Widget>> = Vec::new();
    if today {
        layers.push(Box::new(m3::centered(width, height, polar_shape(42.0, 9.0, 0.07, roles.primary))));
    } else if current {
        let hover = anim::float(&format!("{key}/hover"), if anim::hovered(&key) { theme::STATE_HOVER } else { 0.0 }, EFFECTS);
        layers.push(Box::new(m3::centered(
            width,
            height,
            Rectangle::new().width(38.0).height(38.0).radius(19.0).fill(theme::with_alpha(roles.text_on_surface, hover)),
        )));
    }
    layers.push(Box::new(m3::centered(width, height, text)));

    let hover_key = key.clone();
    Rectangle::new()
        .width(width)
        .height(height)
        .on_hover(move |inside| anim::set_hovered(&hover_key, inside))
        .child(Stack::new(layers).width(width).height(height))
}

fn stat_bar(roles: &Roles, key: &str, name: &str, text: String, value: f32, accent: Color) -> Column {
    const TRACK: f32 = 200.0;

    let filled = anim::float(key, (TRACK * value.clamp(0.0, 1.0)).max(16.0), SPRING_FAST);

    let track = Rectangle::new()
        .width(16.0)
        .height(TRACK)
        .radius(8.0)
        .fill(theme::with_alpha(roles.secondary, 0.22))
        .align_child(Start, amane::End)
        .child(Rectangle::new().width(16.0).height(filled).radius(8.0).fill(anim::color(&format!("{key}/color"), accent, EFFECTS)));

    Column::new(children![
        track,
        m3::icon(name, 18.0, roles.text_on_surface_variant, false),
        m3::label(text, TYPE_LABEL, roles.text_on_surface).weight(Weight::Bold),
    ])
    .width(36.0)
    .gap(10.0)
    .align(Center)
}

fn stats_card(roles: &Roles, height: f32) -> Rectangle {
    let history = History::read();
    let cpu = history.cpu.last().copied().unwrap_or_default();
    let ram = history.ram.last().copied().unwrap_or_default();
    let gpu = Load::read().gpu as f32;
    let misc = Theme::read().palette.misc;

    let bars = Row::new(children![
        stat_bar(roles, "calendar/cpu", "memory", format!("{}%", cpu.round()), cpu / 100.0, if cpu >= 90.0 { roles.error } else { roles.primary }),
        stat_bar(roles, "calendar/gpu", "thermostat", format!("{gpu}\u{b0}"), (gpu / 100.0).min(1.0), if gpu >= 80.0 { roles.error } else { roles.tertiary }),
        stat_bar(roles, "calendar/ram", "memory_alt", format!("{}%", ram.round()), ram / 100.0, if ram >= 90.0 { roles.error } else { misc }),
    ])
    .gap(10.0);

    card(170.0, height, roles).align_child(Center, Center).child(
        Column::new(children![
            m3::label(hostname(), TYPE_TITLE, roles.text_on_surface).weight(Weight::Bold),
            bars,
        ])
        .gap(18.0)
        .align(Center),
    )
}
