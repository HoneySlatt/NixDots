use std::fs;
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::{SystemTime, UNIX_EPOCH};

use amane::{Color, Service};

pub const FONT: &str = "Google Sans Flex";
pub const SYMBOL_FONT: &str = "Symbols Nerd Font";
// Width axis that gives the bar the footprint it had with a monospace font
pub const BAR_FONT: &str = "Google Sans Flex:wdth=118";

pub const FONT_SIZE: f32 = 13.0;
// Quickshell scales the bar text down slightly
pub const BAR_TEXT_SIZE: f32 = FONT_SIZE * 0.96;

pub const BAR_HEIGHT: f32 = 30.0;
pub const MARGIN: i32 = 6;
pub const BAR_OPACITY: f32 = 0.9;
pub const BORDER_RADIUS: f32 = 12.0;
pub const MODULE_PADDING: f32 = 8.0;
pub const POPUP_GAP: f32 = 6.0;

pub const ICON_FONT: &str = "Material Symbols Rounded";

// Material 3 shape scale
pub const SHAPE_XS: f32 = 4.0;
pub const SHAPE_S: f32 = 8.0;
pub const SHAPE_M: f32 = 12.0;
pub const SHAPE_L: f32 = 16.0;
pub const SHAPE_LI: f32 = 20.0;
pub const SHAPE_XL: f32 = 28.0;
pub const SHAPE_XLI: f32 = 32.0;
pub const SHAPE_XXL: f32 = 48.0;

// Material 3 type scale
pub const TYPE_HEADLINE: f32 = 26.0;
pub const TYPE_TITLE_L: f32 = 20.0;
pub const TYPE_TITLE: f32 = 15.0;
pub const TYPE_BODY: f32 = 13.0;
pub const TYPE_LABEL: f32 = 12.0;
pub const TYPE_LABEL_S: f32 = 11.0;

pub const STATE_HOVER: f32 = 0.08;

const DEFAULT_THEME: &str = "pastelglow";

#[derive(Clone, Copy)]
#[allow(dead_code)]
pub struct Palette {
    pub background: Color,
    pub text: Color,
    pub separator: Color,
    pub warning: Color,
    pub caution: Color,
    pub misc: Color,
    pub process: Color,
    pub accent: Color,
    pub highlight: Color,
}

const fn hex(value: u32) -> Color {
    Color::rgb((value >> 16) as u8, (value >> 8) as u8, value as u8)
}

const fn palette(colors: [u32; 9]) -> Palette {
    Palette {
        background: hex(colors[0]),
        text: hex(colors[1]),
        separator: hex(colors[2]),
        warning: hex(colors[3]),
        caution: hex(colors[4]),
        misc: hex(colors[5]),
        process: hex(colors[6]),
        accent: hex(colors[7]),
        highlight: hex(colors[8]),
    }
}

// Theme keys and display names, in themes.json order
pub const THEMES: [(&str, &str); 6] = [
    ("carbonfox", "Carbonfox"),
    ("everforest", "Everforest Dark"),
    ("rosepine", "Ros\u{e9} Pine"),
    ("pastelglow", "Pastel Glow"),
    ("gruvbox", "Gruvbox Dark"),
    ("gruvbox-light", "Gruvbox Light"),
];

pub fn theme_name(key: &str) -> &'static str {
    THEMES.iter().find(|(known, _)| *known == key).map_or("", |(_, name)| name)
}

pub fn palette_for(key: &str) -> Option<Palette> {
    let colors = match key {
        "carbonfox" => [0x161616, 0xf2f4f8, 0x2a2a2a, 0xff0000, 0x525253, 0x808080, 0xa0a0a0, 0x3a3a3a, 0xc6c6c6],
        "everforest" => [0x2d353b, 0xd3c6aa, 0x343f44, 0xe67e80, 0x3d484d, 0x83c092, 0x7fbbb3, 0xa7c080, 0xdbbc7f],
        "rosepine" => [0x191724, 0xe0def4, 0x26233a, 0xeb6f92, 0x403d52, 0x31748f, 0x9ccfd8, 0xc4a7e7, 0xc4a7e7],
        "pastelglow" => [0xf8e9ee, 0x3b2730, 0xe2c2cb, 0xe0486b, 0x8b6f79, 0x63c7c8, 0x6d8ce3, 0xb86ee6, 0xe0486b],
        "gruvbox" => [0x282828, 0xebdbb2, 0x3c3836, 0xfb4934, 0x504945, 0x8ec07c, 0x83a598, 0xd3869b, 0xfabd2f],
        "gruvbox-light" => [0xfbf1c7, 0x3c3836, 0xebdbb2, 0xcc241d, 0xd5c4a1, 0x689d6a, 0x458588, 0xb16286, 0xd79921],
        _ => return None,
    };

    Some(palette(colors))
}

pub fn with_alpha(color: Color, alpha: f32) -> Color {
    Color::rgba(color.red(), color.green(), color.blue(), (alpha * 255.0).round() as u8)
}

fn channels(color: Color) -> [f32; 3] {
    [color.red(), color.green(), color.blue()].map(|channel| f32::from(channel) / 255.0)
}

fn from_channels([r, g, b]: [f32; 3]) -> Color {
    let byte = |value: f32| (value.clamp(0.0, 1.0) * 255.0).round() as u8;
    Color::rgb(byte(r), byte(g), byte(b))
}

pub fn mix(a: Color, b: Color, amount: f32) -> Color {
    let (a, b) = (channels(a), channels(b));
    from_channels([0, 1, 2].map(|i| a[i] + (b[i] - a[i]) * amount))
}

// `tint` laid over `base` at `alpha`, like a Material state layer
pub fn overlay(base: Color, tint: Color, alpha: f32) -> Color {
    let base_alpha = f32::from(base.alpha()) / 255.0;
    let out_alpha = alpha + base_alpha * (1.0 - alpha);

    if out_alpha == 0.0 {
        return Color::TRANSPARENT;
    }

    let (base, tint) = (channels(base), channels(tint));
    let mixed = from_channels([0, 1, 2].map(|i| (tint[i] * alpha + base[i] * base_alpha * (1.0 - alpha)) / out_alpha));

    with_alpha(mixed, out_alpha)
}

fn luminance(color: Color) -> f32 {
    let linear = |value: f32| {
        if value <= 0.03928 { value / 12.92 } else { ((value + 0.055) / 1.055).powf(2.4) }
    };
    let [r, g, b] = channels(color).map(linear);

    0.2126 * r + 0.7152 * g + 0.0722 * b
}

fn contrast(a: Color, b: Color) -> f32 {
    let (la, lb) = (luminance(a), luminance(b));
    (la.max(lb) + 0.05) / (la.min(lb) + 0.05)
}

// Readable content color on top of any container
pub fn content_on(color: Color) -> Color {
    let dark = mix(color, Color::BLACK, 0.74);
    let light = mix(color, Color::WHITE, 0.94);

    if contrast(dark, color) >= contrast(light, color) { dark } else { light }
}

fn desaturate(color: Color) -> Color {
    let [r, g, b] = channels(color);
    let (max, min) = (r.max(g).max(b), r.min(g).min(b));

    if max == min {
        return color;
    }

    let lightness = (max + min) / 2.0;
    let delta = max - min;
    let saturation = delta / (1.0 - (2.0 * lightness - 1.0).abs());
    let hue = if max == r {
        ((g - b) / delta).rem_euclid(6.0)
    } else if max == g {
        (b - r) / delta + 2.0
    } else {
        (r - g) / delta + 4.0
    } * 60.0;

    let chroma = (1.0 - (2.0 * lightness - 1.0).abs()) * saturation * 0.4;
    let x = chroma * (1.0 - ((hue / 60.0).rem_euclid(2.0) - 1.0).abs());
    let (r, g, b) = match (hue / 60.0) as u32 {
        0 => (chroma, x, 0.0),
        1 => (x, chroma, 0.0),
        2 => (0.0, chroma, x),
        3 => (0.0, x, chroma),
        4 => (x, 0.0, chroma),
        _ => (chroma, 0.0, x),
    };
    let m = lightness - chroma / 2.0;

    from_channels([r + m, g + m, b + m])
}

// Material 3 color roles derived from the active palette, as in Theme.qml
#[derive(Clone, Copy)]
#[allow(dead_code)]
pub struct Roles {
    pub is_dark: bool,
    pub primary: Color,
    pub text_on_primary: Color,
    pub primary_container: Color,
    pub text_on_primary_container: Color,
    pub secondary: Color,
    pub text_on_secondary: Color,
    pub secondary_container: Color,
    pub text_on_secondary_container: Color,
    pub tertiary: Color,
    pub text_on_tertiary: Color,
    pub tertiary_container: Color,
    pub text_on_tertiary_container: Color,
    pub error: Color,
    pub text_on_error: Color,
    pub error_container: Color,
    pub text_on_error_container: Color,
    pub surface: Color,
    pub surface_container_lowest: Color,
    pub surface_container_high: Color,
    pub surface_container_highest: Color,
    pub text_on_surface: Color,
    pub text_on_surface_variant: Color,
    pub outline: Color,
    pub outline_variant: Color,
    pub inverse_surface: Color,
    pub inverse_on_surface: Color,
    pub shadow: Color,
}

impl Roles {
    fn new(palette: &Palette) -> Self {
        let background = palette.background;
        let is_dark = luminance(background) < 0.4;

        let container = |color| mix(background, color, if is_dark { 0.32 } else { 0.22 });
        let on_container = |color| {
            if is_dark { mix(color, Color::WHITE, 0.58) } else { mix(color, Color::BLACK, 0.6) }
        };
        let readable = |color, fallback| if contrast(color, background) >= 1.8 { color } else { fallback };

        let primary = readable(palette.accent, palette.highlight);
        let secondary = desaturate(primary);
        let tertiary = readable(palette.process, palette.misc);
        let error = palette.warning;

        Self {
            is_dark,
            primary,
            text_on_primary: content_on(primary),
            primary_container: container(primary),
            text_on_primary_container: on_container(primary),
            secondary,
            text_on_secondary: content_on(secondary),
            secondary_container: container(secondary),
            text_on_secondary_container: on_container(secondary),
            tertiary,
            text_on_tertiary: content_on(tertiary),
            tertiary_container: container(tertiary),
            text_on_tertiary_container: on_container(tertiary),
            error,
            text_on_error: content_on(error),
            error_container: container(error),
            text_on_error_container: on_container(error),
            surface: background,
            surface_container_lowest: if is_dark { mix(background, Color::BLACK, 0.3) } else { mix(background, Color::WHITE, 0.6) },
            surface_container_high: mix(background, palette.separator, 0.65),
            surface_container_highest: mix(background, palette.separator, 1.3),
            text_on_surface: palette.text,
            text_on_surface_variant: mix(palette.text, background, 0.3),
            outline: mix(palette.text, background, 0.52),
            outline_variant: mix(palette.text, background, 0.8),
            inverse_surface: palette.text,
            inverse_on_surface: background,
            shadow: Color::rgba(0, 0, 0, if is_dark { 115 } else { 56 }),
        }
    }
}

pub fn home() -> String {
    std::env::var("HOME").unwrap_or_default()
}

// Theme state is shared with Quickshell and the theme scripts
pub fn config_dir() -> String {
    format!("{}/.config/amane", home())
}

// Runs switch-theme.sh, which themes every app and rewrites .current-theme
pub fn set_theme(key: &str) {
    static SEQUENCE: AtomicU64 = AtomicU64::new(0);

    let millis = SystemTime::now().duration_since(UNIX_EPOCH).map_or(0, |elapsed| elapsed.as_millis() as u64);
    let request = millis * 100 + SEQUENCE.fetch_add(1, Ordering::Relaxed) % 100;

    amane::spawn(&format!("{}/themes/switch-theme.sh {key} {request}", config_dir()));
}

fn theme_file() -> String {
    format!("{}/.current-theme", config_dir())
}

pub struct Theme {
    pub key: String,
    pub palette: Palette,
    pub roles: Roles,
}

impl Theme {
    fn load() -> Self {
        let key = fs::read_to_string(theme_file()).unwrap_or_default();
        let key = key.trim();

        let (key, palette) = match palette_for(key) {
            Some(palette) => (key, palette),
            None => (DEFAULT_THEME, palette_for(DEFAULT_THEME).expect("default theme exists")),
        };

        Self { key: String::from(key), palette, roles: Roles::new(&palette) }
    }
}

impl Service for Theme {
    fn new() -> Self {
        Self::load()
    }

    // switch-theme.sh rewrites the file, so every theme switch applies here too
    fn listen() {
        for _ in amane::watch_file(&theme_file()) {
            let loaded = Self::load();

            if loaded.key != Self::read().key {
                *Self::write() = loaded;
            }
        }
    }
}
