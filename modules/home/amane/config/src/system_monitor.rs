// System monitor popup: CPU, GPU and RAM graphs plus the busiest processes

use std::thread;
use std::time::Duration;

use amane::{
    Canvas, Center, Color, Column, End, Key, LayerWindow, Monitor, Padding, Parent, Path, Rectangle,
    Row, Service, Shape, Stack, Start, Weight, Widget, children, shapes,
};

use crate::anim::{self, EFFECTS};
use crate::m3::{self, Grow, Variant};
use crate::popups::{self, Anchor, Popup};
use crate::system::{self, History, Load};
use crate::theme::{self, Roles, SHAPE_LI, SHAPE_M, SHAPE_XS, SHAPE_XL, TYPE_BODY, TYPE_LABEL, TYPE_TITLE_L, Theme};

const WIDTH: f32 = 790.0;
const PADDING: f32 = 16.0;
const METRICS_WIDTH: f32 = 360.0;
const PROCESSES_WIDTH: f32 = WIDTH - 2.0 * PADDING - METRICS_WIDTH - 16.0;
const PROCESSES_HEIGHT: f32 = 196.0;

const LIST_WIDTH: f32 = PROCESSES_WIDTH - 16.0 - 8.0;
const LIST_HEIGHT: f32 = PROCESSES_HEIGHT - 12.0 - 8.0 - 26.0;
const ROW_HEIGHT: f32 = 36.0;

#[derive(Clone, PartialEq)]
struct Process {
    pid: u32,
    name: String,
    cpu: String,
    memory: String,
}

#[derive(Default, PartialEq)]
pub struct Processes {
    list: Vec<Process>,
}

impl Processes {
    fn read_now() -> Self {
        let output = amane::output("ps -eo pid=,comm=,pcpu=,pmem= --sort=-pcpu | head -n 80");

        let list = output
            .lines()
            .filter_map(|line| {
                let parts: Vec<&str> = line.split_whitespace().collect();
                let [pid, name, cpu, memory] = parts[..] else {
                    return None;
                };

                let percent = |value: &str| format!("{:.1}", value.parse::<f32>().unwrap_or_default());

                Some(Process { pid: pid.parse().ok()?, name: String::from(name), cpu: percent(cpu), memory: percent(memory) })
            })
            .collect();

        Self { list }
    }
}

fn refresh() {
    let processes = Processes::read_now();

    if processes != *Processes::read() {
        *Processes::write() = processes;
    }
}

impl Service for Processes {
    fn new() -> Self {
        Self::default()
    }

    fn interval() -> Duration {
        Duration::from_secs(2)
    }

    fn listen() {
        system::poll(Self::interval(), || popups::is_open(Popup::SystemMonitor), Self::read_now);
    }
}

#[derive(Default)]
pub struct SystemMonitor {
    // pixels scrolled down the process list
    scroll: f32,
}

impl Service for SystemMonitor {
    fn new() -> Self {
        Self::default()
    }

    fn interval() -> Duration {
        Duration::from_secs(3600)
    }
}

pub fn reset() {
    SystemMonitor::write().scroll = 0.0;
    thread::spawn(refresh);
}

fn kill(pid: u32) {
    thread::spawn(move || {
        amane::output(&format!("kill {pid}"));
        refresh();
    });
}

fn scroll_by(lines: f32) {
    let count = Processes::read().list.len();
    let max = (count as f32 * ROW_HEIGHT - LIST_HEIGHT).max(0.0);

    let mut state = SystemMonitor::write();
    state.scroll = (state.scroll + lines * 40.0).clamp(0.0, max);
}

fn on_key(key: Key) {
    if key == Key::Escape {
        popups::close();
    }
}

pub fn view(monitor: &Monitor) -> LayerWindow {
    popups::window(monitor, Popup::SystemMonitor, Anchor::TopLeft, on_key, |context| {
        let roles = Theme::read().roles;

        let row = Row::new(children![metrics(&roles), processes(&roles)]).gap(16.0);
        let height = m3::height_of(&row) + 2.0 * PADDING;

        let content = Rectangle::new().width(Parent).height(Parent).padding(PADDING).child(row);

        m3::surface(
            &roles,
            (WIDTH, height),
            SHAPE_XL,
            !context.top,
            if context.top { Grow::Top } else { Grow::Bottom },
            context.opened,
            content,
        )
    })
}

fn metrics(roles: &Roles) -> Column {
    let history = History::read();

    let cpu = history.cpu.last().copied().unwrap_or_default();
    let ram = history.ram.last().copied().unwrap_or_default();
    let gpu = Load::read().gpu;

    Column::new(children![
        metric_card(roles, ("memory", "CPU", format!("{cpu}%")), &history.cpu, roles.primary, (true, false)),
        metric_card(roles, ("developer_board", "GPU", format!("{gpu}\u{b0}C")), &history.gpu, roles.tertiary, (false, false)),
        metric_card(roles, ("memory_alt", "RAM", format!("{ram}%")), &history.ram, Theme::read().palette.misc, (false, true)),
    ])
    .width(METRICS_WIDTH)
    .gap(2.0)
}

fn metric_card(roles: &Roles, text: (&str, &str, String), history: &[f32], accent: Color, position: (bool, bool)) -> Rectangle {
    const SPARKLINE_WIDTH: f32 = METRICS_WIDTH - 32.0 - 40.0 - 84.0 - 2.0 * 14.0;

    let (name, title, value) = text;
    let (first, last) = position;
    let top = if first { SHAPE_LI } else { SHAPE_XS };
    let bottom = if last { SHAPE_LI } else { SHAPE_XS };

    let bubble = Rectangle::new()
        .width(40.0)
        .height(40.0)
        .radius(SHAPE_M)
        .fill(theme::mix(roles.surface_container_high, accent, 0.28))
        .align_child(Center, Center)
        .child(m3::icon(name, 24.0, accent, false));

    let labels = Column::new(children![
        m3::label(title, TYPE_LABEL, roles.text_on_surface_variant).weight(Weight::Bold),
        m3::label(value, TYPE_TITLE_L, roles.text_on_surface).weight(Weight::Bold),
    ])
    .width(84.0);

    Rectangle::new()
        .width(METRICS_WIDTH)
        .height(64.0)
        .radius_top_left(top)
        .radius_top_right(top)
        .radius_bottom_left(bottom)
        .radius_bottom_right(bottom)
        .fill(roles.surface_container_high)
        .padding(m3::horizontal(16.0, 16.0))
        .align_child(Start, Center)
        .child(Row::new(children![bubble, labels, sparkline(history, accent, SPARKLINE_WIDTH)]).gap(14.0).align(Center))
}

// Filled line graph, scaled to at least 100
fn sparkline(values: &[f32], color: Color, width: f32) -> Canvas {
    const HEIGHT: f32 = 40.0;

    let canvas = Canvas::new().width(width).height(HEIGHT);

    if values.len() < 2 {
        return canvas.shapes(shapes![]);
    }

    let max = values.iter().copied().fold(100.0, f32::max);
    let x = |index: usize| 2.0 + index as f32 * (width - 4.0) / (values.len() - 1) as f32;
    let y = |value: f32| HEIGHT - 3.0 - (value / max).clamp(0.0, 1.0) * (HEIGHT - 7.0);

    let line = |path: Path| {
        values.iter().enumerate().skip(1).fold(path.move_to(x(0), y(values[0])), |path, (index, &value)| {
            path.line_to(x(index), y(value))
        })
    };

    let area = line(Path::new()).line_to(width - 2.0, HEIGHT).line_to(2.0, HEIGHT).close();

    canvas.shapes(shapes![
        area.fill(theme::with_alpha(color, 0.16)),
        line(Path::new()).stroke(3.0, color).cap(amane::Cap::Round),
    ])
}

fn right_aligned(text: amane::Text) -> Rectangle {
    Rectangle::new().width(54.0).height(20.0).align_child(End, Center).child(text)
}

fn processes(roles: &Roles) -> Rectangle {
    let processes = Processes::read();
    let scroll = SystemMonitor::read().scroll;

    let heading = |text: &str| m3::label(text, TYPE_LABEL, roles.primary).weight(Weight::Bold);
    let header = Row::new(children![
        Rectangle::new().width(Parent).height(20.0).padding(m3::horizontal(14.0, 0.0)).align_child(Start, Center).child(heading("Process")),
        right_aligned(heading("CPU")),
        right_aligned(heading("MEM")),
        Rectangle::new().width(34.0).height(20.0),
    ])
    .width(Parent)
    .gap(12.0)
    .align(Center);

    let list: Box<dyn Widget> = if processes.list.is_empty() {
        Box::new(
            Rectangle::new()
                .width(Parent)
                .height(LIST_HEIGHT)
                .padding(m3::horizontal(14.0, 0.0))
                .child(m3::label("No process data", TYPE_BODY, roles.text_on_surface_variant)),
        )
    } else {
        Box::new(process_list(roles, &processes.list, scroll))
    };

    Rectangle::new()
        .width(PROCESSES_WIDTH)
        .height(PROCESSES_HEIGHT)
        .radius(SHAPE_LI)
        .fill(roles.surface_container_high)
        .padding(Padding { top: 12.0, right: 8.0, bottom: 8.0, left: 8.0 })
        .child(Column::new(vec![Box::new(header), list]).width(Parent).gap(6.0))
}

fn process_list(roles: &Roles, list: &[Process], scroll: f32) -> Rectangle {
    let first = (scroll / ROW_HEIGHT) as usize;
    let mut rows: Vec<Box<dyn Widget>> = Vec::new();

    for (index, process) in list.iter().enumerate().skip(first) {
        if index as f32 * ROW_HEIGHT > scroll + LIST_HEIGHT {
            break;
        }

        rows.push(Box::new(process_row(roles, process)));
    }

    let offset = first as f32 * ROW_HEIGHT - scroll;
    let content = list.len() as f32 * ROW_HEIGHT;

    let mut layers: Vec<Box<dyn Widget>> = vec![Box::new(
        Rectangle::new()
            .width(LIST_WIDTH)
            .height(LIST_HEIGHT - offset)
            .translate(0.0, offset)
            .child(Column::new(rows).width(LIST_WIDTH)),
    )];

    // scroll indicator
    if content > LIST_HEIGHT {
        let height = (LIST_HEIGHT * LIST_HEIGHT / content).max(24.0);
        let y = scroll * (LIST_HEIGHT - height) / (content - LIST_HEIGHT).max(1.0);

        layers.push(Box::new(
            Rectangle::new()
                .width(4.0)
                .height(height)
                .translate(LIST_WIDTH + 4.0, y)
                .radius(2.0)
                .fill(roles.outline_variant),
        ));
    }

    Rectangle::new()
        .width(Parent)
        .height(LIST_HEIGHT)
        .clip()
        .on_scroll(|scroll| scroll_by(scroll.y))
        .child(Stack::new(layers).width(LIST_WIDTH + 8.0).height(LIST_HEIGHT))
}

fn process_row(roles: &Roles, process: &Process) -> Rectangle {
    let key = format!("system-monitor/process/{}", process.pid);
    let hovered = anim::hovered(&key);
    let pid = process.pid;

    let close = Rectangle::new()
        .width(30.0)
        .height(30.0)
        .opacity(anim::float(&format!("{key}/close"), if hovered { 1.0 } else { 0.45 }, EFFECTS))
        .child(m3::icon_button(roles, &format!("{key}/kill"), "close", (30.0, 30.0), Variant::Standard, false, false, move || {
            kill(pid)
        }));

    let hover_key = key.clone();

    Rectangle::new()
        .width(LIST_WIDTH)
        .height(ROW_HEIGHT)
        .radius(ROW_HEIGHT / 2.0)
        .fill(m3::state_color(&key, Color::TRANSPARENT, roles.text_on_surface))
        .padding(m3::horizontal(14.0, 4.0))
        .align_child(Start, Center)
        .on_hover(move |inside| anim::set_hovered(&hover_key, inside))
        .child(
            Row::new(children![
                m3::label(process.name.clone(), TYPE_BODY, roles.text_on_surface).elide(),
                right_aligned(m3::label(process.cpu.clone(), TYPE_BODY, roles.text_on_surface)),
                right_aligned(m3::label(process.memory.clone(), TYPE_BODY, roles.text_on_surface_variant)),
                close,
            ])
            .width(Parent)
            .gap(12.0)
            .align(Center),
        )
}
