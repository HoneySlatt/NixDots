// Screenshots and screencasts of a frozen screen, a port of hyprquickshot (Mod+S on Hyprland)

use std::fs;
use std::process::Command;
use std::sync::{Mutex, PoisonError};
use std::thread;
use std::time::{SystemTime, UNIX_EPOCH};

use amane::{
    Center, Color, Image, Key, LayerWindow, Monitor, Point, Rectangle, Row, Service, Stack, Weight, Widget, children,
    window_size,
};

use crate::anim::{self, Motion, SPRING_DEFAULT};
use crate::m3;
use crate::popups::{self, Anchor, Popup};
use crate::system;
use crate::theme::{self, Palette, Theme};

const DIM_OPACITY: f32 = 0.6;
const BORDER_RADIUS: f32 = 10.0;
const OUTLINE_THICKNESS: f32 = 2.0;

// the output's size in logical pixels, kept by the view: window_size() is only right while drawing
static SIZE: Mutex<(f32, f32)> = Mutex::new((0.0, 0.0));

fn logical_size() -> (f32, f32) {
    *SIZE.lock().unwrap_or_else(PoisonError::into_inner)
}

// Crops the frozen screen ($1) to $2 (WxH+X+Y) into the next Screenshot_NN.png, copies it and says so
const SAVE: &str = r#"
dir="${HQS_DIR:-${XDG_SCREENSHOTS_DIR:-${XDG_PICTURES_DIR:-$HOME/Pictures}}}/Screenshots"
mkdir -p "$dir"
last=$(ls "$dir"/Screenshot_*.png 2>/dev/null | grep -oE '[0-9]+\.png' | grep -oE '^[0-9]+' | sort -n | tail -1)
last=$((10#${last:-0}))
name="Screenshot_$(printf "%02d" $((last + 1))).png"
magick "$1" -crop "$2" "$dir/$name" && wl-copy < "$dir/$name" && rm "$1" && notify-send -i "$dir/$name" "Screenshot" "$name"
"#;

// Records an output (-o name) or a region (-g "x,y wxh") with the default sink's sound into the next Screencast_NN.mp4
const RECORD: &str = r#"
AUDIO="$(wpctl inspect @DEFAULT_AUDIO_SINK@ | sed -n 's/.*node.name = "\(.*\)"/\1/p').monitor"
dir="${XDG_VIDEOS_DIR:-$HOME/Videos}/Screencasts"
mkdir -p "$dir"
last=$(ls "$dir"/Screencast_*.mp4 2>/dev/null | grep -oE '[0-9]+\.mp4' | grep -oE '^[0-9]+' | sort -n | tail -1)
last=$((10#${last:-0}))
name="Screencast_$(printf "%02d" $((last + 1))).mp4"
wf-recorder "$1" "$2" --audio="$AUDIO" -c libx264rgb -x bgr0 -p crf=15 -p preset=ultrafast -f "$dir/$name"
notify-send -i video-x-generic "Screencast" "$name"
"#;

#[derive(Clone, Copy, Default, PartialEq)]
enum Mode {
    #[default]
    Region,
    Window,
    Screen,
}

#[derive(Default)]
pub struct Screenshot {
    // the frozen screen, a new file each time since images are cached by path
    capture: String,
    // the output's name and top left corner in the compositor's layout, for screencasts
    output: String,
    origin: (f32, f32),
    // windows of the output's workspace, (x, y, width, height) from its top left corner
    windows: Vec<[f32; 4]>,
    mode: Mode,
    record: bool,
    // where the selection is heading; the drawn one springs after it
    target: [f32; 4],
    start: (f32, f32),
    dragging: bool,
    pointer: (f32, f32),
}

impl Service for Screenshot {
    fn new() -> Self {
        Self::default()
    }

    fn listen() {}
}

// Mod+S: stops a running screencast, otherwise freezes the focused output and opens the selector
pub fn ipc(_: &[String]) -> String {
    thread::spawn(|| {
        if !amane::output("pgrep -x wf-recorder").trim().is_empty() {
            amane::spawn("pkill --signal SIGINT -x wf-recorder");
            return;
        }

        let Some(output) = popups::focused_output() else {
            return;
        };

        let stamp = SystemTime::now().duration_since(UNIX_EPOCH).map_or(0, |time| time.as_millis());
        let runtime = std::env::var("XDG_RUNTIME_DIR").unwrap_or_else(|_| String::from("/tmp"));
        let capture = format!("{runtime}/amane-screenshot-{stamp}.png");

        let frozen = Command::new("grim").args(["-l", "1", "-o", &output, &capture]).status().is_ok_and(|status| status.success());
        if !frozen {
            return;
        }

        let (origin, windows) = if system::hyprland() { hyprland_layout(&output) } else { ((0.0, 0.0), Vec::new()) };

        *Screenshot::write() = Screenshot { capture, output, origin, windows, ..Screenshot::default() };
        popups::show(Popup::Screenshot);
    });

    String::new()
}

// The output's position and the windows on its active workspace, from hyprctl
fn hyprland_layout(output: &str) -> ((f32, f32), Vec<[f32; 4]>) {
    let monitor = amane::output(&format!(
        "hyprctl -j monitors | jq -r '.[] | select(.name == \"{output}\") | [.x, .y, .activeWorkspace.id] | @tsv'"
    ));
    let fields: Vec<f32> = monitor.split_whitespace().filter_map(|field| field.parse().ok()).collect();
    let [x, y, workspace] = fields[..] else {
        return ((0.0, 0.0), Vec::new());
    };

    let clients = amane::output(&format!(
        "hyprctl -j clients | jq -r '.[] | select(.workspace.id == {workspace} and .mapped and (.hidden | not)) | [.at[0], .at[1], .size[0], .size[1]] | @tsv'"
    ));
    let windows = clients
        .lines()
        .filter_map(|line| {
            let numbers: Vec<f32> = line.split_whitespace().filter_map(|field| field.parse().ok()).collect();
            let [left, top, width, height] = numbers[..] else {
                return None;
            };
            Some([left - x, top - y, width, height])
        })
        .collect();

    ((x, y), windows)
}

fn cancel() {
    let capture = Screenshot::read().capture.clone();
    let _ = fs::remove_file(capture);
    popups::close();
}

// A selection in logical pixels of the output
fn finish(area: [f32; 4]) {
    let [x, y, width, height] = area;
    if width < 1.0 || height < 1.0 {
        return;
    }

    let (capture, record, output, origin) = {
        let state = Screenshot::read();
        (state.capture.clone(), state.record, state.output.clone(), state.origin)
    };
    popups::close();

    if record {
        let _ = fs::remove_file(&capture);
        let full = Screenshot::read().mode == Mode::Screen;
        let (flag, value) = if full {
            (String::from("-o"), output)
        } else {
            (String::from("-g"), format!("{},{} {}x{}", (origin.0 + x).round(), (origin.1 + y).round(), width.round(), height.round()))
        };
        let _ = Command::new("sh").args(["-c", RECORD, "sh", &flag, &value]).spawn();
        return;
    }

    // the frozen screen has real pixels, the selection logical ones
    let scale = png_width(&capture).map_or(1.0, |pixels| pixels as f32 / logical_size().0.max(1.0));
    let crop = format!(
        "{}x{}+{}+{}",
        (width * scale).round(),
        (height * scale).round(),
        (x * scale).round(),
        (y * scale).round()
    );
    let _ = Command::new("sh").args(["-c", SAVE, "sh", &capture, &crop]).spawn();
}

// The width stored in a png's header
fn png_width(path: &str) -> Option<u32> {
    let bytes = fs::read(path).ok()?;
    let width = bytes.get(16..20)?;
    Some(u32::from_be_bytes(width.try_into().ok()?))
}

fn set_mode(mode: Mode) {
    {
        let mut state = Screenshot::write();
        state.mode = mode;
        state.target = [0.0; 4];
        state.dragging = false;
    }

    if mode == Mode::Screen {
        let (width, height) = logical_size();
        finish([0.0, 0.0, width, height]);
    }
}

fn drag(point: Point) {
    let mut state = Screenshot::write();
    if state.mode != Mode::Region {
        return;
    }

    if !state.dragging {
        state.dragging = true;
        state.start = (point.x, point.y);
    }

    let (start_x, start_y) = state.start;
    state.target = [start_x.min(point.x), start_y.min(point.y), (point.x - start_x).abs(), (point.y - start_y).abs()];
}

fn hover(point: Point) {
    let mut state = Screenshot::write();
    state.pointer = (point.x, point.y);

    if state.mode != Mode::Window {
        return;
    }

    let inside = |[x, y, width, height]: &[f32; 4]| point.x >= *x && point.x <= x + width && point.y >= *y && point.y <= y + height;
    if let Some(window) = state.windows.iter().rev().find(|window| inside(window)).copied() {
        state.target = window;
    }
}

// The button was let go: a dragged region, or a click on the hovered window
fn release() {
    let (mode, target, (x, y)) = {
        let mut state = Screenshot::write();
        state.dragging = false;
        (state.mode, state.target, state.pointer)
    };

    let [left, top, width, height] = target;
    let on_window = x >= left && x <= left + width && y >= top && y <= top + height;

    if mode == Mode::Region || on_window {
        finish(target);
    }
}

fn on_key(key: Key) {
    if key == Key::Escape {
        cancel();
    }
}

pub fn view(monitor: &Monitor) -> LayerWindow {
    popups::window(monitor, Popup::Screenshot, Anchor::Cover(Color::TRANSPARENT), on_key, |_| {
        let (width, height) = window_size();
        *SIZE.lock().unwrap_or_else(PoisonError::into_inner) = (width, height);
        let palette = Theme::read().palette;
        let state = Screenshot::read();

        // the drawn selection springs after its target, as hyprquickshot's did
        let spring = |name: &str, value: f32| anim::float(&format!("screenshot/{name}"), value, SPRING_DEFAULT);
        let [x, y, w, h] = state.target;
        let selection = [spring("x", x), spring("y", y), spring("width", w), spring("height", h)];

        let frozen = Rectangle::new().width(width).height(height).fill(Image::cover(state.capture.clone()));

        let dim = Rectangle::new()
            .width(width)
            .height(height)
            .shader(format!("{}/shaders/screenshot-dim.frag", theme::config_dir()))
            .shader_values(vec![selection, [DIM_OPACITY, BORDER_RADIUS, OUTLINE_THICKNESS, 0.0]])
            .on_drag(drag)
            .on_move(hover)
            .on_click(|_| release());

        let bar = toolbar(&palette, state.mode, state.record);
        let (bar_width, bar_height) = (m3::width_of(&bar), m3::height_of(&bar));

        Stack::new(children![frozen, dim, bar.translate((width - bar_width) / 2.0, height - 40.0 - bar_height)])
            .width(width)
            .height(height)
    })
}

// Region, window and screen buttons, then the screencast switch
fn toolbar(palette: &Palette, mode: Mode, record: bool) -> Rectangle {
    let buttons: Vec<Box<dyn Widget>> = [(Mode::Region, "region"), (Mode::Window, "window"), (Mode::Screen, "screen")]
        .into_iter()
        .map(|(button, icon)| -> Box<dyn Widget> {
            let key = format!("screenshot/button/{icon}");
            let color = if button == mode {
                theme::with_alpha(palette.accent, 0.45)
            } else if anim::hovered(&key) {
                theme::with_alpha(palette.separator, 0.7)
            } else {
                theme::with_alpha(palette.separator, 0.4)
            };
            let icon = Rectangle::new()
                .width(24.0)
                .height(24.0)
                .fill(Image::cover(format!("{}/icons/screenshot-{icon}.svg", theme::config_dir())));

            Box::new(
                m3::hoverable(Rectangle::new().width(48.0).height(48.0), &key)
                    .radius(8.0)
                    .fill(anim::color(&format!("{key}/color"), color, Motion::linear(100)))
                    .align_child(Center, Center)
                    .on_click(move |_| set_mode(button))
                    .child(icon),
            )
        })
        .collect();

    let switch_color = if record { theme::with_alpha(palette.warning, 0.8) } else { theme::with_alpha(palette.separator, 0.8) };
    let knob_x = anim::float("screenshot/switch/knob", if record { 40.0 - 16.0 - 3.0 } else { 3.0 }, Motion::curve([0.45, 0.0, 0.55, 1.0], 150));
    let switch = Rectangle::new()
        .width(40.0)
        .height(22.0)
        .radius(11.0)
        .fill(anim::color("screenshot/switch", switch_color, Motion::linear(150)))
        .cursor(amane::Pointer)
        .on_click(|_| {
            let mut state = Screenshot::write();
            state.record = !state.record;
        })
        .child(Rectangle::new().width(16.0).height(16.0).radius(8.0).fill(palette.text).translate(knob_x, 3.0));

    let label_color = anim::color("screenshot/label", if record { palette.warning } else { palette.text }, Motion::linear(150));
    let label = m3::label("Screencast", 14.0, label_color).weight(Weight::SemiBold);

    let row = Row::new(children![
        Row::new(buttons).gap(8.0).align(Center),
        Row::new(children![label, switch]).gap(8.0).align(Center),
    ])
    .gap(25.0)
    .align(Center);

    let (width, height) = (m3::width_of(&row) + 16.0, m3::height_of(&row) + 16.0);

    Rectangle::new()
        .width(width)
        .height(height)
        .radius(12.0)
        .fill(theme::with_alpha(palette.background, 0.85))
        .padding(8.0)
        // presses here must not start a region drag underneath
        .on_drag(|_| {})
        .child(row)
}
