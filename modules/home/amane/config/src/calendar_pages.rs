// Media, wallpaper and theme pages of the calendar popup

use std::fs;
use std::sync::{LazyLock, Mutex, PoisonError};
use std::thread;
use std::time::{Duration, Instant};

use amane::{
    Bus, Canvas, Cap, Center, Color, Column, End, Image, Line, Media, Padding, Palette, Parent, Path,
    Rectangle, Row, Service, Shape, Stack, Start, Weight, Widget, arguments, children,
};

use crate::anim::{self, Motion, SPRING_FAST};
use crate::calendar::{self, CONTENT_HEIGHT, CONTENT_WIDTH, Calendar, Tab, card, round_image};
use crate::m3::{self, Variant};
use crate::theme::{
    self, Roles, SHAPE_LI, SHAPE_M, SHAPE_XL, THEMES, TYPE_BODY, TYPE_HEADLINE, TYPE_LABEL, TYPE_LABEL_S, TYPE_TITLE,
    TYPE_TITLE_L, Theme,
};

const CAVA_CONFIG: &str = "[general]\nbars = 32\nframerate = 30\n\n[output]\nmethod = raw\nraw_target = /dev/stdout\ndata_format = ascii\nascii_max_range = 20\n";

// Audio spectrum for the cover ring, read only while the media page is shown
#[derive(Default)]
pub struct Cava {
    values: Vec<f32>,
}

impl Service for Cava {
    fn new() -> Self {
        Self::default()
    }

    fn listen() {
        let config = format!("{}/amane-cava.conf", std::env::var("XDG_RUNTIME_DIR").unwrap_or_else(|_| String::from("/tmp")));
        let _ = fs::write(&config, CAVA_CONFIG);

        loop {
            if !calendar::active(Tab::Media) {
                thread::sleep(Duration::from_millis(200));
                continue;
            }

            for line in amane::lines(&format!("cava -p {config}")) {
                if !calendar::active(Tab::Media) {
                    break;
                }

                let values: Vec<f32> = line.split(';').filter(|value| !value.is_empty()).map(|value| value.parse().unwrap_or_default()).collect();

                if values != Self::read().values {
                    Self::write().values = values;
                }
            }

            Self::write().values.clear();
        }
    }
}

// Average color of the cover art, for the spectrum ring
#[derive(Default)]
pub struct Cover {
    url: String,
    accent: Option<Color>,
}

impl Service for Cover {
    fn new() -> Self {
        Self::default()
    }

    fn listen() {
        loop {
            thread::sleep(Duration::from_secs(1));

            let url = String::from(Media::read().art_url());
            if url == Cover::read().url {
                continue;
            }

            let accent = url.strip_prefix("file://").and_then(|path| {
                Palette::write().open(path, 8);
                average(Palette::read().colors())
            });

            *Self::write() = Self { url, accent };
        }
    }
}

fn average(colors: &[Color]) -> Option<Color> {
    if colors.is_empty() {
        return None;
    }

    let count = colors.len() as u32;
    let mean = |channel: fn(&Color) -> u8| (colors.iter().map(|color| u32::from(channel(color))).sum::<u32>() / count) as u8;

    Some(Color::rgb(mean(Color::red), mean(Color::green), mean(Color::blue)))
}

fn format_time(time: Duration) -> String {
    let seconds = time.as_secs();
    format!("{}:{:02}", seconds / 60, seconds % 60)
}

// Seeks the active player to a fraction of the track
fn seek(fraction: f32) {
    static LAST: LazyLock<Mutex<Option<Instant>>> = LazyLock::new(Default::default);

    // dragging sends many points, the player only needs a few
    {
        let mut last = LAST.lock().unwrap_or_else(PoisonError::into_inner);
        if last.is_some_and(|at| at.elapsed() < Duration::from_millis(150)) {
            return;
        }
        *last = Some(Instant::now());
    }

    let Some((name, position, length)) = Media::read().active().map(|player| (String::from(player.name()), player.position(), player.length())) else {
        return;
    };

    let target = length.as_secs_f64() * f64::from(fraction.clamp(0.0, 1.0));
    let offset = ((target - position.as_secs_f64()) * 1_000_000.0) as i64;

    thread::spawn(move || {
        Bus::session().call(&name, "/org/mpris/MediaPlayer2", "org.mpris.MediaPlayer2.Player", "Seek", &arguments![offset]);
    });
}

static WAVE_START: LazyLock<Instant> = LazyLock::new(Instant::now);

// M3 Expressive wavy progress: the wave flattens when not playing
fn wavy_progress(roles: &Roles, width: f32, value: f32, playing: bool) -> Canvas {
    const STROKE: f32 = 4.0;
    const AMPLITUDE: f32 = 3.0;
    const WAVELENGTH: f32 = 32.0;
    const HEIGHT: f32 = STROKE + AMPLITUDE * 2.0 + 4.0;

    let wave = anim::float("calendar/wave", if playing { 1.0 } else { 0.0 }, Motion::curve([0.33, 1.0, 0.68, 1.0], 450));
    let phase = if playing {
        amane::request_frame();
        WAVE_START.elapsed().as_secs_f32() / 1.4 * std::f32::consts::TAU
    } else {
        0.0
    };

    let half = STROKE / 2.0;
    let center = HEIGHT / 2.0;
    let value = value.clamp(0.0, 1.0);
    let end = half + value * (width - STROKE);
    let amplitude = AMPLITUDE * wave * (value * 12.0).min(1.0);

    let mut shapes: Vec<Box<dyn Shape>> = Vec::new();

    if end > half + 0.5 {
        let y = |x: f32| center + amplitude * ((x / WAVELENGTH) * std::f32::consts::TAU - phase).sin();
        let mut path = Path::new().move_to(half, y(half));
        let mut x = half + 1.0;
        while x <= end {
            path = path.line_to(x, y(x));
            x += 1.0;
        }
        shapes.push(Box::new(path.stroke(STROKE, roles.primary).cap(Cap::Round)));
    }

    let track_start = if value > 0.0 { end + STROKE + 4.0 } else { half };
    if track_start < width - half {
        shapes.push(Box::new(Line::new().from(track_start, center).to(width - half, center).stroke(STROKE, roles.secondary_container).cap(Cap::Round)));
        shapes.push(Box::new(amane::Circle::new().center(width - half, center).radius(half * 0.5).fill(roles.primary)));
    }

    Canvas::new().width(width).height(HEIGHT).shapes(shapes)
}

// Spectrum bars around the cover
fn spectrum(values: &[f32], color: Color) -> Canvas {
    const SIZE: f32 = 260.0;
    const INNER: f32 = 96.0;

    let center = SIZE / 2.0;
    let count = values.len().max(1) as f32;

    let shapes = values
        .iter()
        .enumerate()
        .map(|(index, value)| -> Box<dyn Shape> {
            let length = (value / 20.0).min(1.0) * 30.0;
            let angle = index as f32 / count * std::f32::consts::TAU - std::f32::consts::FRAC_PI_2;
            let (cos, sin) = (angle.cos(), angle.sin());

            Box::new(
                Line::new()
                    .from(center + INNER * cos, center + INNER * sin)
                    .to(center + (INNER + length) * cos, center + (INNER + length) * sin)
                    .stroke(5.0, color)
                    .cap(Cap::Round),
            )
        })
        .collect();

    Canvas::new().width(SIZE).height(SIZE).shapes(shapes)
}

pub fn media(roles: &Roles) -> Rectangle {
    let media = Media::read();
    let player = media.active();
    let info_width = CONTENT_WIDTH - 52.0 - 260.0 - 34.0;

    let (title, artist) = match player {
        Some(player) => (String::from(player.title()), String::from(player.artist())),
        None => (String::from("No media playing"), String::from("Start playback in any MPRIS player")),
    };
    let playing = media.playing();
    let (position, length) = (media.position(), media.length());
    let value = if player.is_none() || length.is_zero() { 0.0 } else { position.as_secs_f32() / length.as_secs_f32() };

    let accent = Cover::read().accent.unwrap_or(roles.primary);
    let cover = media.art_url().strip_prefix("file://").map(String::from);

    let visual = Stack::new(children![spectrum(&Cava::read().values, accent), m3::centered(260.0, 260.0, round_image(176.0, cover, "music_note", roles))])
        .width(260.0)
        .height(260.0);

    let progress = Rectangle::new()
        .width(info_width)
        .height(14.0)
        .cursor(amane::Pointer)
        .on_drag(move |point| seek(point.x / info_width))
        .child(wavy_progress(roles, info_width, value, playing));

    let times = Row::new(children![
        m3::label(format_time(position), TYPE_LABEL, roles.text_on_surface_variant),
        Rectangle::new().width(Parent).height(1.0),
        m3::label(format_time(length), TYPE_LABEL, roles.text_on_surface_variant),
    ])
    .width(info_width);

    let controls = Row::new(children![
        m3::icon_button(roles, "calendar/media-previous", "skip_previous", (56.0, 56.0), Variant::Tonal, false, false, Media::previous),
        m3::icon_button(
            roles,
            "calendar/media-play",
            if playing { "pause" } else { "play_arrow" },
            (112.0, 80.0),
            Variant::Filled,
            true,
            playing,
            Media::play_pause,
        ),
        m3::icon_button(roles, "calendar/media-next", "skip_next", (56.0, 56.0), Variant::Tonal, false, false, Media::next),
    ])
    .gap(12.0)
    .align(Center);

    let info = Column::new(children![
        Column::new(children![
            m3::label(title, TYPE_HEADLINE, roles.text_on_surface).weight(Weight::Bold).elide(),
            m3::label(artist, TYPE_TITLE, roles.text_on_surface_variant).elide(),
        ])
        .width(info_width)
        .gap(4.0),
        Column::new(children![progress, times]).width(info_width).gap(6.0),
        Rectangle::new().width(info_width).height(80.0).align_child(Center, Center).child(controls),
    ])
    .width(info_width)
    .gap(16.0);

    card(CONTENT_WIDTH, CONTENT_HEIGHT, roles)
        .padding(26.0)
        .align_child(Start, Center)
        .child(Row::new(children![visual, info]).gap(34.0).align(Center))
}

fn nsfw_file() -> String {
    format!("{}/.nsfw-enabled", theme::config_dir())
}

pub fn nsfw_enabled() -> bool {
    fs::read_to_string(nsfw_file()).is_ok_and(|text| text.trim() == "true")
}

fn toggle_nsfw() {
    let _ = fs::write(nsfw_file(), format!("{}\n", !nsfw_enabled()));
}

const PER_PAGE: usize = 12;

// Wallpapers of the current theme, with cached thumbnails
#[derive(Default)]
pub struct Wallpapers {
    theme: String,
    nsfw: bool,
    scanned: bool,
    dir: String,
    thumbnails: String,
    files: Vec<String>,
    thumbnails_ready: bool,
}

pub fn wallpaper_dir(theme: &str) -> String {
    let folder = amane::output(&format!(
        "jq -r --arg t {theme} '(.[$t] // .pastelglow).wallpaperDir' {}/themes/themes.json",
        theme::config_dir()
    ));
    format!("{}/Pictures/Wallpapers/{folder}", theme::home())
}

fn is_image(name: &str) -> bool {
    let lower = name.to_lowercase();
    [".jpg", ".jpeg", ".png", ".webp"].iter().any(|extension| lower.ends_with(extension))
}

impl Service for Wallpapers {
    fn new() -> Self {
        Self::default()
    }

    // rescans when the popup opens on a new theme or NSFW setting, then makes the missing thumbnails
    fn listen() {
        loop {
            thread::sleep(Duration::from_millis(500));

            if !crate::popups::is_open(crate::popups::Popup::Calendar) {
                continue;
            }

            let theme = Theme::read().key.clone();
            let nsfw = nsfw_enabled();

            {
                let current = Self::read();
                if current.scanned && current.theme == theme && current.nsfw == nsfw {
                    continue;
                }
            }

            let dir = wallpaper_dir(&theme);
            let thumbnails = format!("{}/.cache/amane/wallpapers/{theme}", theme::home());

            let mut files: Vec<String> = fs::read_dir(&dir)
                .map(|entries| {
                    entries
                        .flatten()
                        .filter_map(|entry| entry.file_name().into_string().ok())
                        .filter(|name| is_image(name) && name.contains("[NSFW]") == nsfw)
                        .collect()
                })
                .unwrap_or_default();
            files.sort();

            *Self::write() = Self { theme, nsfw, scanned: true, dir: dir.clone(), thumbnails: thumbnails.clone(), files, thumbnails_ready: false };
            {
                let mut state = Calendar::write();
                state.page = 0;
                state.selected_wallpaper.clear();
            }

            amane::output(&format!(
                "mkdir -p '{thumbnails}' && for f in '{dir}'/*; do base=${{f##*/}}; out='{thumbnails}'/\"$base.jpg\"; [ -s \"$out\" ] && continue; \
                 case \"$base\" in *.jpg|*.jpeg|*.png|*.webp|*.JPG|*.JPEG|*.PNG|*.WEBP) ;; *) continue;; esac; \
                 magick \"$f\" -auto-orient -thumbnail '360x240^' -gravity center -extent 360x240 -quality 82 \"$out\" 2>/dev/null; done"
            ));

            Self::write().thumbnails_ready = true;
        }
    }
}

fn apply_wallpaper(dir: String, name: String) {
    amane::spawn(&format!("awww img '{dir}/{name}' --transition-type wave --transition-duration 2"));
    Calendar::write().selected_wallpaper = name;
}

fn change_page(delta: isize, pages: usize) {
    let mut state = Calendar::write();
    state.page = state.page.saturating_add_signed(delta).min(pages - 1);
}

pub fn wallpapers(roles: &Roles) -> Rectangle {
    const COLUMNS: usize = 4;
    const ROWS: usize = 3;

    let walls = Wallpapers::read();
    let state = Calendar::read();

    let inner = CONTENT_WIDTH - 28.0;
    let grid_height = CONTENT_HEIGHT - 28.0 - 40.0 - 12.0;
    let cell = ((inner - 8.0 * (COLUMNS - 1) as f32) / COLUMNS as f32, (grid_height - 8.0 * (ROWS - 1) as f32) / ROWS as f32);
    let pages = walls.files.len().div_ceil(PER_PAGE).max(1);
    let page = state.page.min(pages - 1);

    let shown: Vec<&String> = walls.files.iter().skip(page * PER_PAGE).take(PER_PAGE).collect();
    let mut lines: Vec<Box<dyn Widget>> = Vec::new();

    for row in shown.chunks(COLUMNS) {
        let cells: Vec<Box<dyn Widget>> = row
            .iter()
            .map(|name| -> Box<dyn Widget> { Box::new(wallpaper_cell(roles, &walls, name, *name == &state.selected_wallpaper, cell)) })
            .collect();
        lines.push(Box::new(Row::new(cells).gap(8.0)));
    }

    let count = walls.files.len();
    let pager = |key: &str, name: &str, enabled: bool, delta: isize| {
        Rectangle::new().width(36.0).height(36.0).opacity(if enabled { 1.0 } else { 0.38 }).child(m3::icon_button(
            roles,
            key,
            name,
            (36.0, 36.0),
            Variant::Tonal,
            false,
            false,
            move || change_page(delta, pages),
        ))
    };

    let footer = Row::new(children![
        m3::filter_chip(roles, "calendar/nsfw", ("visibility_off", "NSFW"), walls.nsfw, Some(toggle_nsfw)),
        Rectangle::new().width(Parent).height(1.0),
        m3::label(format!("{count} wallpapers  \u{2022}  {} / {pages}", page + 1), TYPE_BODY, roles.text_on_surface_variant),
        Rectangle::new().width(4.0).height(1.0),
        pager("calendar/walls-previous", "chevron_left", page > 0, -1),
        pager("calendar/walls-next", "chevron_right", page + 1 < pages, 1),
    ])
    .width(inner)
    .height(40.0)
    .gap(8.0)
    .align(Center);

    card(CONTENT_WIDTH, CONTENT_HEIGHT, roles).padding(14.0).child(
        Column::new(children![Rectangle::new().width(inner).height(grid_height).child(Column::new(lines).gap(8.0)), footer])
            .width(inner)
            .gap(12.0),
    )
}

fn wallpaper_cell(roles: &Roles, walls: &Wallpapers, name: &str, selected: bool, size: (f32, f32)) -> Rectangle {
    let (width, height) = size;
    let key = format!("calendar/wallpaper/{name}");

    let target = if selected { SHAPE_XL } else if anim::hovered(&key) { SHAPE_LI } else { SHAPE_M };
    let radius = anim::float(&format!("{key}/radius"), target, SPRING_FAST);

    // the cached thumbnail once it exists, else the file itself (webp needs the thumbnail)
    let thumbnail = format!("{}/{name}.jpg", walls.thumbnails);
    let source = if walls.thumbnails_ready || fs::metadata(&thumbnail).is_ok() {
        Some(thumbnail)
    } else if !name.to_lowercase().ends_with(".webp") {
        Some(format!("{}/{name}", walls.dir))
    } else {
        None
    };

    let frame = Rectangle::new().width(width).height(height).radius(radius).fill(roles.surface_container_highest);
    let frame = match source {
        Some(path) => frame.child(Rectangle::new().width(width).height(height).radius(radius).fill(Image::cover(path).thumbnail(480, 320))),
        None => frame,
    };

    let mut layers: Vec<Box<dyn Widget>> = vec![Box::new(frame)];
    if selected {
        layers.push(Box::new(Rectangle::new().width(width).height(height).radius(radius).border(3.0, roles.primary)));
        layers.push(Box::new(
            Rectangle::new()
                .width(width)
                .height(height)
                .padding(8.0)
                .align_child(End, Start)
                .child(Rectangle::new().width(28.0).height(28.0).radius(14.0).fill(roles.primary).align_child(Center, Center).child(m3::icon(
                    "check",
                    16.0,
                    roles.text_on_primary,
                    false,
                ))),
        ));
    }

    let (dir, file) = (walls.dir.clone(), String::from(name));

    m3::hoverable(Rectangle::new().width(width).height(height), &key)
        .on_click(move |_| apply_wallpaper(dir.clone(), file.clone()))
        .child(Stack::new(layers).width(width).height(height))
}

pub fn themes(roles: &Roles) -> Rectangle {
    let current = Theme::read().key.clone();
    let inner = CONTENT_WIDTH - 36.0;
    let grid_height = CONTENT_HEIGHT - 36.0 - 46.0;
    let cell = ((inner - 10.0) / 2.0, (grid_height - 20.0) / 3.0);

    let name = theme::theme_name(&current);
    let badge_label = m3::label(name, TYPE_LABEL_S, roles.text_on_primary).weight(Weight::Bold);
    let badge = Rectangle::new()
        .width(m3::width_of(&badge_label) + 16.0)
        .height(20.0)
        .radius(10.0)
        .fill(roles.primary)
        .align_child(Center, Center)
        .child(badge_label);

    let header = Row::new(children![
        Rectangle::new().width(Parent).height(32.0).padding(m3::horizontal(4.0, 0.0)).align_child(Start, Center).child(
            m3::label("Color themes", TYPE_TITLE_L, roles.text_on_surface).weight(Weight::Bold),
        ),
        badge,
    ])
    .width(inner)
    .height(32.0)
    .align(Center);

    let mut lines: Vec<Box<dyn Widget>> = Vec::new();
    for pair in THEMES.chunks(2) {
        let cells: Vec<Box<dyn Widget>> =
            pair.iter().map(|(key, name)| -> Box<dyn Widget> { Box::new(theme_cell(roles, key, name, *key == current, cell)) }).collect();
        lines.push(Box::new(Row::new(cells).gap(10.0)));
    }

    card(CONTENT_WIDTH, CONTENT_HEIGHT, roles)
        .padding(18.0)
        .child(Column::new(children![header, Column::new(lines).gap(10.0)]).width(inner).gap(14.0))
}

fn theme_cell(roles: &Roles, key: &'static str, name: &str, active: bool, size: (f32, f32)) -> Rectangle {
    let (width, height) = size;
    let palette = theme::palette_for(key).expect("listed themes have a palette");
    let hover_key = format!("calendar/theme/{key}");

    let radius = anim::float(&format!("{hover_key}/radius"), if active { SHAPE_XL } else { SHAPE_LI }, SPRING_FAST);

    let dots = Row::new(
        [palette.separator, palette.text, palette.warning, palette.highlight]
            .into_iter()
            .map(|color| -> Box<dyn Widget> { Box::new(Rectangle::new().width(14.0).height(14.0).radius(7.0).fill(color)) })
            .collect(),
    )
    .gap(4.0);

    let mut items: Vec<Box<dyn Widget>> = vec![
        Box::new(m3::swatch(52.0, palette.accent, palette.process, palette.misc)),
        Box::new(Column::new(children![m3::label(name, TYPE_TITLE, palette.text).weight(Weight::Bold).elide(), dots]).width(Parent).gap(4.0)),
    ];
    if active {
        items.push(Box::new(m3::icon("check_circle", 24.0, palette.accent, false)));
    }

    let cell = m3::hoverable(Rectangle::new().width(width).height(height), &hover_key)
        .radius(radius)
        .fill(m3::state_color(&hover_key, palette.background, palette.text))
        .padding(Padding { top: 0.0, right: 18.0, bottom: 0.0, left: 18.0 })
        .align_child(Start, Center)
        .on_click(move |_| theme::set_theme(key))
        .child(Row::new(items).width(Parent).gap(14.0).align(Center));

    if active { cell.border(3.0, roles.primary) } else { cell }
}
