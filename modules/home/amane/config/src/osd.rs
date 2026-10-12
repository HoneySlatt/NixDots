// On-screen display for the volume, microphone and brightness keys

use std::thread;
use std::time::{Duration, Instant};

use amane::{
    Audio, Brightness, Center, Layer, LayerWindow, Margin, Monitor, Rectangle, Row, Service, Vertical,
    children,
};

use crate::m3::{self, Grow};
use crate::theme::{TYPE_TITLE, Theme};

// main monitor
const OUTPUT: &str = "DP-2";
const SHOWN: Duration = Duration::from_millis(1500);

const PILL: (f32, f32) = (320.0, 64.0);
const PADDING: f32 = 8.0;
const PERCENT_WIDTH: f32 = 44.0;
// room for the shadow around the pill
const SHADOW: f32 = 24.0;

#[derive(Clone, Copy, PartialEq)]
enum Kind {
    Volume,
    Microphone,
    Brightness,
}

#[derive(Default)]
pub struct Osd {
    // what is shown, since when, and the last key press
    shown: Option<(Kind, Instant, Instant)>,
}

impl Service for Osd {
    fn new() -> Self {
        Self::default()
    }

    fn listen() {
        loop {
            thread::sleep(Duration::from_millis(100));

            let expired = Self::read().shown.is_some_and(|(_, _, pressed)| pressed.elapsed() > SHOWN);
            if expired {
                Self::write().shown = None;
            }
        }
    }
}

// `amane ipc call osd volume up`: changes the value, then shows it
pub fn ipc(arguments: &[String]) -> String {
    let arguments: Vec<&str> = arguments.iter().map(String::as_str).collect();

    let (kind, command) = match arguments.as_slice() {
        ["volume", "up"] => (Kind::Volume, "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
        ["volume", "down"] => (Kind::Volume, "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
        ["volume", "mute"] => (Kind::Volume, "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
        ["microphone", "mute"] => (Kind::Microphone, "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
        ["brightness", "up"] => (Kind::Brightness, "brightnessctl -q set 5%+"),
        ["brightness", "down"] => (Kind::Brightness, "brightnessctl -q set 5%-"),
        _ => return String::from("usage: osd volume up|down|mute, osd microphone mute, osd brightness up|down"),
    };

    if kind == Kind::Brightness && !Brightness::read().present() {
        return String::from("no backlight");
    }

    amane::spawn(command);

    let now = Instant::now();
    let mut osd = Osd::write();
    let opened = osd.shown.filter(|(shown, _, _)| *shown == kind).map_or(now, |(_, opened, _)| opened);
    osd.shown = Some((kind, opened, now));

    String::new()
}

fn layer() -> LayerWindow {
    LayerWindow::new()
        .width(PILL.0 + 2.0 * SHADOW)
        .height(PILL.1 + 2.0 * SHADOW)
        .anchor_vertical(Vertical::Bottom)
        .margin(Margin { top: 0, right: 0, bottom: 48, left: 0 })
        .layer(Layer::Overlay)
        .namespace("amane:osd")
}

pub fn view(monitor: &Monitor) -> LayerWindow {
    let Some((kind, opened, _)) = Osd::read().shown.filter(|_| monitor.name == OUTPUT) else {
        return layer().visible(false);
    };

    let roles = Theme::read().roles;
    let slider_width = PILL.0 - 2.0 * PADDING - PERCENT_WIDTH;
    let dims = (slider_width, 36.0, 48.0);

    let (slider, value) = match kind {
        Kind::Volume => {
            let audio = Audio::read();
            let state = (f32::from(audio.volume()), audio.muted());
            let icon = if audio.muted() { "volume_off" } else { "volume_up" };
            (m3::slider(&roles, "osd/volume", dims, state, icon, Some(Audio::toggle_mute), Audio::set_volume), audio.volume())
        }
        Kind::Microphone => {
            let audio = Audio::read();
            let state = (f32::from(audio.microphone_volume()), audio.microphone_muted());
            let icon = if audio.microphone_muted() { "mic_off" } else { "mic" };
            let slider = m3::slider(
                &roles,
                "osd/microphone",
                dims,
                state,
                icon,
                Some(Audio::toggle_microphone_mute),
                Audio::set_microphone_volume,
            );
            (slider, audio.microphone_volume())
        }
        Kind::Brightness => {
            let percent = Brightness::read().percent();
            (m3::slider(&roles, "osd/brightness", dims, (f32::from(percent), false), "brightness_6", None, Brightness::set), percent)
        }
    };

    let percent = Rectangle::new()
        .width(PERCENT_WIDTH)
        .height(48.0)
        .align_child(Center, Center)
        .child(m3::label(format!("{value}%"), TYPE_TITLE, roles.text_on_surface));

    let content = Rectangle::new()
        .width(PILL.0)
        .height(PILL.1)
        .padding(amane::Padding { top: PADDING, right: PADDING, bottom: PADDING, left: PADDING })
        .child(Row::new(children![slider, percent]));

    let pill = m3::surface(&roles, PILL, PILL.1 / 2.0, false, Grow::Bottom, opened, content);

    layer().child(Rectangle::new().width(PILL.0 + 2.0 * SHADOW).height(PILL.1 + 2.0 * SHADOW).align_child(Center, Center).child(pill))
}
