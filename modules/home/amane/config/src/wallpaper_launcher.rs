// Wallpaper picker with a large preview, toggled with Mod+W

use std::fs;
use std::thread;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use amane::{
    Center, Column, End, Image, Key, LayerWindow, Monitor, Padding, Parent, Pointer, Rectangle, Row, Service,
    Stack, Start, Weight, Widget, children,
};

use crate::anim::{self, EFFECTS, SPRING_FAST};
use crate::calendar_pages::{nsfw_enabled, wallpaper_dir};
use crate::m3::{self, Grow, Variant};
use crate::popups::{self, Anchor, Popup};
use crate::theme::{self, Roles, SHAPE_M, SHAPE_XL, SHAPE_XLI, TYPE_LABEL, TYPE_TITLE, Theme};

const WIDTH: f32 = 1180.0;
const HEIGHT: f32 = 790.0;
const INNER: f32 = WIDTH - 32.0;
const PREVIEW_HEIGHT: f32 = HEIGHT - 16.0 - 24.0 - 96.0 - 16.0 - 56.0 - 20.0;
const STRIP_WIDTH: f32 = INNER - 2.0 * 48.0 - 2.0 * 12.0;
const THUMB_STEP: f32 = 156.0 + 10.0;

// Wallpapers of the current theme, with the launcher's own 1280x720 thumbnails
#[derive(Default)]
pub struct LauncherWallpapers {
    theme: String,
    nsfw: bool,
    scanned: bool,
    thumbnails: String,
    files: Vec<String>,
    ready: bool,
}

impl LauncherWallpapers {
    fn thumbnail(&self, path: &str) -> String {
        let name = path.rsplit('/').next().unwrap_or(path);
        format!("{}/{name}.jpg", self.thumbnails)
    }
}

impl Service for LauncherWallpapers {
    fn new() -> Self {
        Self::default()
    }

    // rescans when the launcher opens on a new theme or NSFW setting, then makes the missing thumbnails
    fn listen() {
        loop {
            thread::sleep(Duration::from_millis(300));

            if !popups::is_open(Popup::WallpaperLauncher) {
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
            let thumbnails = format!("{}/.cache/amane/wallpaper-launcher/{theme}", theme::home());

            let files: Vec<String> = amane::output(&format!(
                "find '{dir}' -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\)"
            ))
            .lines()
            .filter(|path| path.contains("[NSFW]") == nsfw)
            .map(String::from)
            .collect();

            let middle = files.len() / 2;
            *Self::write() = Self { theme, nsfw, scanned: true, thumbnails: thumbnails.clone(), files, ready: false };
            WallpaperLauncher::write().selected = middle;

            amane::output(&format!(
                "mkdir -p '{thumbnails}' && for f in '{dir}'/*; do base=${{f##*/}}; out='{thumbnails}'/\"$base.jpg\"; [ -s \"$out\" ] && continue; \
                 case \"$base\" in *.jpg|*.jpeg|*.png|*.webp|*.JPG|*.JPEG|*.PNG|*.WEBP) ;; *) continue;; esac; \
                 magick \"$f\" -auto-orient -thumbnail '1280x720^' -gravity center -extent 1280x720 -quality 90 \"$out\" 2>/dev/null; done"
            ));

            Self::write().ready = true;
        }
    }
}

#[derive(Default)]
pub struct WallpaperLauncher {
    selected: usize,
}

impl Service for WallpaperLauncher {
    fn new() -> Self {
        Self::default()
    }

    fn interval() -> Duration {
        Duration::from_secs(3600)
    }
}

// Starts on the middle wallpaper
pub fn reset() {
    let count = LauncherWallpapers::read().files.len();
    WallpaperLauncher::write().selected = count / 2;
}

fn select(index: usize) {
    let last = LauncherWallpapers::read().files.len().saturating_sub(1);
    WallpaperLauncher::write().selected = index.min(last);
}

fn shuffle() {
    let count = LauncherWallpapers::read().files.len();
    if count == 0 {
        return;
    }

    let nanos = SystemTime::now().duration_since(UNIX_EPOCH).map_or(0, |elapsed| elapsed.subsec_nanos());
    select(nanos as usize % count);
}

fn apply() {
    let path = {
        let walls = LauncherWallpapers::read();
        walls.files.get(WallpaperLauncher::read().selected).cloned()
    };

    if let Some(path) = path {
        amane::spawn(&format!("awww img '{}' --transition-type wave --transition-duration 2", path.replace('\'', r"'\''")));
        popups::close();
    }
}

fn on_key(key: Key) {
    let selected = WallpaperLauncher::read().selected;

    match key {
        Key::Escape => popups::close(),
        Key::Enter => apply(),
        Key::Left | Key::Character('h') => select(selected.saturating_sub(1)),
        Key::Right | Key::Character('l') => select(selected + 1),
        Key::Character('s') => shuffle(),
        _ => {}
    }
}

pub fn view(monitor: &Monitor) -> LayerWindow {
    popups::window(monitor, Popup::WallpaperLauncher, Anchor::Modal, on_key, |context| {
        let roles = Theme::read().roles;
        let walls = LauncherWallpapers::read();
        let selected = WallpaperLauncher::read().selected.min(walls.files.len().saturating_sub(1));
        let current = walls.files.get(selected);

        let preview = Rectangle::new().width(INNER).height(PREVIEW_HEIGHT).radius(SHAPE_XL).fill(roles.surface_container_highest);
        let preview = match current {
            Some(path) if walls.ready || fs::metadata(walls.thumbnail(path)).is_ok() => preview.child(
                Rectangle::new()
                    .width(INNER)
                    .height(PREVIEW_HEIGHT)
                    .radius(SHAPE_XL)
                    .fill(Image::cover(walls.thumbnail(path)).thumbnail(1280, 720)),
            ),
            Some(_) => preview,
            None => preview
                .align_child(Center, Center)
                .child(m3::label("No wallpapers found", TYPE_TITLE, roles.text_on_surface_variant)),
        };

        let name = theme::theme_name(&walls.theme);
        let subtitle = if walls.files.is_empty() {
            String::from(name)
        } else {
            format!("{} / {}  \u{2022}  {name}", selected + 1, walls.files.len())
        };

        let footer = Row::new(children![
            Column::new(children![
                m3::label("Wallpapers", TYPE_TITLE, roles.text_on_surface).weight(Weight::Bold),
                m3::label(subtitle, TYPE_LABEL, roles.text_on_surface_variant),
            ])
            .width(Parent),
            m3::button(&roles, "wallpaper-launcher/shuffle", ("shuffle", "Shuffle"), 56.0, Variant::Tonal, shuffle),
            m3::button(&roles, "wallpaper-launcher/apply", ("check", "Apply"), 56.0, Variant::Filled, apply),
        ])
        .width(INNER - 16.0)
        .gap(8.0)
        .align(Center);

        let content = Rectangle::new().width(Parent).height(Parent).padding(Padding { top: 16.0, right: 16.0, bottom: 0.0, left: 16.0 }).child(
            Column::new(children![
                preview,
                Rectangle::new().width(INNER).height(24.0),
                strip(&roles, &walls, selected),
                Rectangle::new().width(INNER).height(16.0),
                Rectangle::new().width(INNER).height(56.0).padding(m3::horizontal(12.0, 4.0)).align_child(Start, Center).child(footer),
            ])
            .width(INNER),
        );

        m3::surface(&roles, (WIDTH, HEIGHT), SHAPE_XLI, false, Grow::Center, context.opened, content)
    })
}

fn strip(roles: &Roles, walls: &LauncherWallpapers, selected: usize) -> Row {
    let count = walls.files.len();
    let content = count as f32 * THUMB_STEP - 10.0;

    // the selected thumbnail is kept in the middle, without scrolling past either end
    let centered = STRIP_WIDTH / 2.0 - (selected as f32 * THUMB_STEP + 78.0);
    let target = centered.clamp((STRIP_WIDTH - content).min(0.0), 0.0);
    let offset = anim::float("wallpaper-launcher/offset", target, EFFECTS);

    let mut cells: Vec<Box<dyn Widget>> = Vec::new();
    for (index, path) in walls.files.iter().enumerate() {
        let x = offset + index as f32 * THUMB_STEP;
        if x + THUMB_STEP < 0.0 || x > STRIP_WIDTH {
            continue;
        }
        cells.push(Box::new(thumbnail(roles, walls, path, index, index == selected).translate(x, 0.0)));
    }

    Row::new(children![
        m3::icon_button(roles, "wallpaper-launcher/previous", "chevron_left", (48.0, 48.0), Variant::Tonal, false, false, || {
            let selected = WallpaperLauncher::read().selected;
            select(selected.saturating_sub(1));
        }),
        Rectangle::new().width(STRIP_WIDTH).height(96.0).clip().child(Stack::new(cells).width(STRIP_WIDTH).height(96.0)),
        m3::icon_button(roles, "wallpaper-launcher/next", "chevron_right", (48.0, 48.0), Variant::Tonal, false, false, || {
            let selected = WallpaperLauncher::read().selected;
            select(selected + 1);
        }),
    ])
    .gap(12.0)
    .align(Center)
}

fn thumbnail(roles: &Roles, walls: &LauncherWallpapers, path: &str, index: usize, selected: bool) -> Rectangle {
    let key = format!("wallpaper-launcher/thumb/{path}");

    let width = anim::float(&format!("{key}/width"), if selected { 156.0 } else { 148.0 }, SPRING_FAST);
    let height = anim::float(&format!("{key}/height"), if selected { 92.0 } else { 84.0 }, SPRING_FAST);
    let radius = anim::float(&format!("{key}/radius"), if selected { SHAPE_XL } else { SHAPE_M }, SPRING_FAST);

    // the launcher thumbnail once made, else the file itself (webp needs the thumbnail)
    let cached = walls.thumbnail(path);
    let source = if walls.ready || fs::metadata(&cached).is_ok() {
        Some(cached)
    } else if !path.to_lowercase().ends_with(".webp") {
        Some(String::from(path))
    } else {
        None
    };

    let mut layers: Vec<Box<dyn Widget>> = Vec::new();
    let frame = Rectangle::new().width(width).height(height).radius(radius).fill(roles.surface_container_highest);
    layers.push(Box::new(match source {
        Some(source) => frame.child(Rectangle::new().width(width).height(height).radius(radius).fill(Image::cover(source).thumbnail(360, 240))),
        None => frame,
    }));

    let hover = anim::float(&format!("{key}/hover"), if anim::hovered(&key) { theme::STATE_HOVER } else { 0.0 }, EFFECTS);
    layers.push(Box::new(Rectangle::new().width(width).height(height).radius(radius).fill(theme::with_alpha(roles.text_on_surface, hover))));

    if selected {
        layers.push(Box::new(Rectangle::new().width(width).height(height).radius(radius).border(3.0, roles.primary)));
        layers.push(Box::new(
            Rectangle::new().width(width).height(height).padding(8.0).align_child(End, Start).child(
                m3::centered(26.0, 26.0, m3::icon("check", 16.0, roles.text_on_primary, false)).radius(13.0).fill(roles.primary),
            ),
        ));
    }

    let hover_key = key.clone();
    Rectangle::new()
        .width(156.0)
        .height(96.0)
        .cursor(Pointer)
        .align_child(Center, Center)
        .on_hover(move |inside| anim::set_hovered(&hover_key, inside))
        .on_click(move |_| {
            if WallpaperLauncher::read().selected == index {
                apply();
            } else {
                select(index);
            }
        })
        .child(Stack::new(layers).width(width).height(height))
}
