use std::fs;
use std::time::Duration;

use amane::{
    Audio, Button, Center, Color, Full, Image, Layer, LayerWindow, Link, Margin, Monitor, Padding, Parent, Pointer, Rectangle, Row, Scroll, Service, Size, Stack, Start, Text,
    Vertical, Weight, Widget, Workspace, Workspaces, Zone, children,
};

use crate::anim::{self, Motion};
use crate::popups::{self, Popup};
use crate::notifications;
use crate::system::{self, Blink, Clock, DISTRO_ICON, HOT_PERCENT, Load, NetBar, Vpn};
use crate::tray::Tray;
use crate::tray_menu;
use crate::theme::{
    self, BAR_HEIGHT, BAR_OPACITY, BAR_TEXT_SIZE, BORDER_RADIUS, FONT, FONT_SIZE, MARGIN, MODULE_PADDING,
    Palette, SYMBOL_FONT, Theme,
};

const NIRI_TOP_MODE: &str = "// Barre en haut : pas de surcharge.";
const NIRI_COMPACT_MODE: &str = "layout {\n    gaps 0\n    border {\n        off\n    }\n    shadow {\n        off\n    }\n}\nwindow-rule {\n    geometry-corner-radius 0\n    opacity 1.0\n}";

// The same two modes for Hyprland, applied live; the top one matches modules/home/hyprland/settings.nix
const HYPRLAND_TOP_MODE: &str = "hl.config({ general = { gaps_in = 6, gaps_out = 6, border_size = 2 }, decoration = { rounding = 12, active_opacity = 1.0, inactive_opacity = 0.9, shadow = { enabled = true } } })";
const HYPRLAND_COMPACT_MODE: &str = "hl.config({ general = { gaps_in = 0, gaps_out = 0, border_size = 0 }, decoration = { rounding = 0, active_opacity = 1.0, inactive_opacity = 1.0, shadow = { enabled = false } } })";

fn position_file() -> String {
    format!("{}/.bar-position", theme::config_dir())
}

// Top: floating rounded bar; bottom: flush bar with the compositor's gaps and borders turned off
fn apply_mode(top: bool) {
    if system::hyprland() {
        let mode = if top { HYPRLAND_TOP_MODE } else { HYPRLAND_COMPACT_MODE };
        let _ = std::process::Command::new("hyprctl").args(["eval", mode]).status();
        return;
    }

    let path = format!("{}/.config/niri/bar-mode.kdl", theme::home());
    let mode = if top { NIRI_TOP_MODE } else { NIRI_COMPACT_MODE };

    let _ = fs::write(path, format!("{mode}\n"));
}

pub struct Position {
    pub top: bool,
}

impl Service for Position {
    fn new() -> Self {
        let top = fs::read_to_string(position_file()).map_or(true, |text| text.trim() != "bottom");

        apply_mode(top);
        Self { top }
    }

    fn interval() -> Duration {
        Duration::from_secs(3600)
    }
}

pub fn toggle_position(_: &[String]) -> String {
    let mut position = Position::write();
    position.top = !position.top;

    let name = if position.top { "top" } else { "bottom" };

    apply_mode(position.top);
    let _ = fs::write(position_file(), format!("{name}\n"));

    String::from(name)
}

pub fn view(monitor: &Monitor) -> LayerWindow {
    let palette = Theme::read().palette;
    let top = Position::read().top;
    let workspaces = Workspaces::read();

    let focused = workspaces
        .list()
        .iter()
        .any(|workspace| workspace.focused() && workspace.output() == Some(monitor.name.as_str()));

    let bar = Bar { monitor: &monitor.name, palette };

    let left = Row::new(children![
        bar.distro(),
        bar.workspaces(workspaces.list()),
        bar.cpu(),
        bar.gpu(),
        bar.ram(),
    ])
    .height(Parent)
    .align(Center);

    let volume = bar.volume();
    let network = bar.network();
    let separator = bar.label("|", palette.text);
    let notifications = bar.notifications();
    let power = bar.power();

    // distance from the tray's right edge to the screen's, where its menus line up
    let tray_edge = if top { MARGIN as f32 } else { 0.0 }
        + fixed_width(&volume)
        + fixed_width(&network)
        + fixed_width(&separator)
        + fixed_width(&notifications)
        + fixed_width(&power);

    let right = Row::new(children![bar.tray(tray_edge), volume, network, separator, notifications, power])
    .height(Parent)
    .align(Center);

    let sides = Row::new(children![left, Rectangle::new().width(Parent).height(Parent), right])
        .width(Parent)
        .height(Parent);

    let clock = Rectangle::new()
        .width(Parent)
        .height(Parent)
        .align_child(Center, Center)
        .child(bar.clock());

    let alpha = if top && !focused { BAR_OPACITY } else { 1.0 };
    let background = anim::color(
        &format!("{}/background", monitor.name),
        theme::with_alpha(palette.background, alpha),
        Motion::linear(200),
    );

    let margin = if top { MARGIN } else { 0 };

    LayerWindow::new()
        .width(Full)
        .height(BAR_HEIGHT)
        .anchor_vertical(if top { Vertical::Top } else { Vertical::Bottom })
        .margin(Margin { top: margin, right: margin, bottom: 0, left: margin })
        .layer(Layer::Top)
        .space(Zone::Reserve)
        .namespace("amane-bar")
        // the game launcher takes the whole screen
        .visible(!popups::shown_on(Popup::SteamLauncher, &monitor.name))
        .child(
            Rectangle::new()
                .width(Parent)
                .height(Parent)
                .fill(background)
                .radius(if top { BORDER_RADIUS } else { 0.0 })
                .clip()
                .child(Stack::new(children![clock, sides]).width(Parent).height(Parent)),
        )
}

fn fixed_width(widget: &impl Widget) -> f32 {
    match widget.width() {
        Size::Fixed(width) => width,
        Size::Parent => 0.0,
    }
}

fn horizontal(left: f32, right: f32) -> Padding {
    Padding { top: 0.0, right, bottom: 0.0, left }
}

// Workspaces with windows, plus the visible ones, by name then by creation
fn bar_workspaces(list: &[Workspace]) -> Vec<&Workspace> {
    let mut shown: Vec<&Workspace> = list
        .iter()
        .filter(|workspace| workspace.windows() > 0 || workspace.active())
        .collect();

    shown.sort_by_key(|workspace| {
        workspace
            .name()
            .and_then(|name| name.parse::<i64>().ok())
            .unwrap_or(1000 + workspace.id())
    });

    shown
}

fn focus_relative(scroll: Scroll) {
    if scroll.y == 0.0 {
        return;
    }

    let delta: isize = if scroll.y < 0.0 { -1 } else { 1 };

    let workspaces = Workspaces::read();
    let shown = bar_workspaces(workspaces.list());

    let Some(current) = shown.iter().position(|workspace| workspace.focused()) else {
        return;
    };

    if let Some(target) = current.checked_add_signed(delta).and_then(|index| shown.get(index)) {
        Workspaces::focus(target.id());
    }
}

fn workspace_glyph(workspace: &Workspace) -> char {
    match workspace.name() {
        Some("magic") => '\u{f074}',
        Some("zellij") => '\u{f120}',
        Some("10") => '\u{f02b4}',
        Some("lock") => '\u{f023}',
        _ => '\u{f111}',
    }
}

struct Bar<'a> {
    monitor: &'a str,
    palette: Palette,
}

impl Bar<'_> {
    fn label(&self, text: impl Into<String>, color: Color) -> Text {
        Text::new(text)
            .font(FONT)
            .size(BAR_TEXT_SIZE)
            .weight(Weight::SemiBold)
            .color(color)
    }

    fn symbol(&self, glyph: char, size: f32, color: Color) -> Text {
        Text::new(glyph.to_string()).font(SYMBOL_FONT).size(size).color(color)
    }

    // Nerd Font glyph followed by text in the UI font
    fn glyph_label(&self, glyph: char, text: String, color: Color) -> Row {
        Row::new(children![
            self.symbol(glyph, FONT_SIZE, color),
            self.label(format!("\u{a0}{text}"), color),
        ])
        .align(Center)
    }

    // Clickable bar item that dims under the pointer
    fn module(
        &self,
        name: &str,
        content: impl Widget + 'static,
        padding: Padding,
        on_click: impl Fn(Button) + 'static,
    ) -> Rectangle {
        let key = format!("{}/{name}", self.monitor);
        let opacity = anim::float(&key, if anim::hovered(&key) { 0.6 } else { 1.0 }, Motion::linear(80));

        Rectangle::new()
            .width(fixed_width(&content) + padding.left + padding.right)
            .height(Parent)
            .padding(padding)
            .align_child(Start, Center)
            .opacity(opacity)
            .cursor(Pointer)
            .on_hover(move |inside| anim::set_hovered(&key, inside))
            .on_click(on_click)
            .child(content)
    }

    fn distro(&self) -> Rectangle {
        let icon = self.symbol(*DISTRO_ICON, 18.0, self.palette.text);

        self.module("distro", icon, horizontal(12.0, 0.0), |_| popups::toggle(Popup::AppLauncher))
    }

    fn workspaces(&self, list: &[Workspace]) -> Rectangle {
        let mut cells: Vec<Box<dyn Widget>> = Vec::new();

        for workspace in bar_workspaces(list) {
            let target = if workspace.focused() { self.palette.text } else { self.palette.caution };
            let color = anim::color(&format!("{}/workspace/{}", self.monitor, workspace.id()), target, Motion::linear(250));
            let id = workspace.id();

            cells.push(Box::new(
                Rectangle::new()
                    .width(32.0)
                    .height(Parent)
                    .align_child(Center, Center)
                    .cursor(Pointer)
                    .on_click(move |_| Workspaces::focus(id))
                    .on_scroll(focus_relative)
                    .child(self.symbol(workspace_glyph(workspace), FONT_SIZE, color)),
            ));
        }

        let row = Row::new(cells).height(Parent);

        Rectangle::new()
            .width(fixed_width(&row) + 16.0)
            .height(Parent)
            .padding(horizontal(12.0, 4.0))
            .child(row)
    }

    fn load_color(&self, percent: u8) -> Color {
        if percent < HOT_PERCENT {
            self.palette.text
        } else if Blink::read().on {
            self.palette.warning
        } else {
            self.palette.separator
        }
    }

    fn cpu(&self) -> Rectangle {
        let percent = Load::read().cpu;
        let content = self.glyph_label('\u{f2db}', format!("{percent}%"), self.load_color(percent));

        self.module("cpu", content, horizontal(MODULE_PADDING, MODULE_PADDING), |_| popups::toggle(Popup::SystemMonitor))
    }

    fn gpu(&self) -> Rectangle {
        let celsius = Load::read().gpu;
        let content = self.glyph_label('\u{f2c8}', format!("{celsius}\u{b0}C"), self.palette.text);

        self.module("gpu", content, horizontal(MODULE_PADDING, MODULE_PADDING), |_| popups::toggle(Popup::SystemMonitor))
    }

    fn ram(&self) -> Rectangle {
        let percent = Load::read().ram;
        let content = self.glyph_label('\u{efc5}', format!("{percent}%"), self.load_color(percent));

        self.module("ram", content, horizontal(MODULE_PADDING, MODULE_PADDING), |_| popups::toggle(Popup::SystemMonitor))
    }

    fn clock(&self) -> Rectangle {
        let text = self.label(Clock::read().text.clone(), self.palette.text);

        self.module("clock", text, horizontal(0.0, 0.0), |_| popups::toggle(Popup::Calendar))
    }

    // Collapsed to a thin strip that opens under the pointer
    fn tray(&self, edge: f32) -> Rectangle {
        const CELL: f32 = 18.0;
        const SPACING: f32 = 4.0;

        let tray = Tray::read();
        let key = format!("{}/tray", self.monitor);
        let open = anim::hovered(&key);

        let count = tray.items.len();
        let row_width = (count as f32 * (CELL + SPACING) - SPACING).max(0.0);
        let width = anim::float(
            &format!("{key}/width"),
            if open { row_width + MODULE_PADDING } else { MODULE_PADDING },
            Motion::curve([0.45, 0.0, 0.55, 1.0], 150),
        );
        let opacity = anim::float(&format!("{key}/opacity"), if open { 1.0 } else { 0.0 }, Motion::linear(150));

        let mut cells: Vec<Box<dyn Widget>> = Vec::new();

        for (index, item) in tray.items.iter().enumerate() {
            let item_key = format!("{key}/{}", item.key);
            let dim = anim::float(&item_key, if anim::hovered(&item_key) { 0.6 } else { 1.0 }, Motion::linear(80));

            let icon = Rectangle::new().width(16.0).height(16.0);
            let icon = match &item.icon {
                Some(path) => icon.fill(Image::contain(path.as_str()).thumbnail(32, 32)),
                None => icon,
            };

            let cell = Rectangle::new().width(CELL).height(CELL).opacity(dim).align_child(Center, Center).child(icon);

            // hidden icons take no clicks
            let cell = if open {
                let item = item.clone();
                let margin = edge + MODULE_PADDING / 2.0 + (count - 1 - index) as f32 * (CELL + SPACING);
                let hover_key = item_key.clone();

                cell.cursor(Pointer).on_hover(move |inside| anim::set_hovered(&hover_key, inside)).on_click(move |button| match button {
                    Button::Right => {
                        if let Some(menu) = &item.menu {
                            tray_menu::open(item.bus.clone(), menu.clone(), margin);
                        }
                    }
                    Button::Middle => item.secondary_activate(),
                    Button::Left => item.activate(),
                })
            } else {
                cell
            };

            cells.push(Box::new(cell));
        }

        let hover_key = key.clone();

        Rectangle::new()
            .width(width)
            .height(Parent)
            .clip()
            .align_child(Center, Center)
            .on_hover(move |inside| anim::set_hovered(&hover_key, inside))
            .child(
                Rectangle::new()
                    .width(row_width)
                    .height(CELL)
                    .opacity(opacity)
                    .child(Row::new(cells).gap(SPACING)),
            )
    }

    fn volume(&self) -> Rectangle {
        let audio = Audio::read();

        let glyph = if audio.muted() {
            '\u{f026}'
        } else if audio.volume() <= 30 {
            '\u{f027}'
        } else {
            '\u{f028}'
        };
        let color = if audio.muted() { self.palette.separator } else { self.palette.text };
        let content = self.glyph_label(glyph, format!("{}%", audio.volume()), color);

        self.module("volume", content, horizontal(MODULE_PADDING, MODULE_PADDING), |button| {
            if button == Button::Right {
                Audio::toggle_mute();
            } else {
                popups::toggle(Popup::Volume);
            }
        })
        .on_scroll(|scroll| {
            let volume = Audio::read().volume();

            if scroll.y < 0.0 {
                Audio::set_volume(volume.saturating_add(5).min(100));
            } else if scroll.y > 0.0 {
                Audio::set_volume(volume.saturating_sub(5));
            }
        })
    }

    fn network(&self) -> Rectangle {
        const WIFI: [char; 5] = ['\u{f092b}', '\u{f091f}', '\u{f0922}', '\u{f0925}', '\u{f0928}'];

        let network = NetBar::read();
        let palette = self.palette;

        let mut items: Vec<Box<dyn Widget>> = Vec::new();

        match network.link {
            Link::Wifi => {
                let color = if network.weak { palette.warning } else { palette.text };

                items.push(Box::new(self.symbol(WIFI[network.level], FONT_SIZE, color)));
            }
            Link::Offline => {
                items.push(Box::new(self.symbol('\u{f1616}', FONT_SIZE, palette.caution)));
                items.push(Box::new(self.label("\u{a0}Offline", palette.caution)));
            }
            Link::Wired | Link::Other => {
                items.push(Box::new(self.symbol('\u{f0200}', FONT_SIZE, palette.text)));
            }
        }

        if Vpn::read().connected {
            items.push(Box::new(self.label("VPN", palette.text)));
        }

        let row = Row::new(items).gap(4.0).align(Center);

        self.module("network", row, horizontal(5.0, 5.0), |_| popups::toggle(Popup::Network))
    }

    fn notifications(&self) -> Rectangle {
        let icon = self.symbol(notifications::bar_icon(), FONT_SIZE, self.palette.text);

        self.module("notifications", icon, horizontal(MODULE_PADDING, MODULE_PADDING), |button| {
            match button {
                Button::Right => notifications::toggle_dnd(),
                _ => popups::toggle(Popup::Notifications),
            }
        })
    }

    fn power(&self) -> Rectangle {
        let icon = self.symbol('\u{23fb}', 13.0, self.palette.text);

        self.module("power", icon, horizontal(6.0, 12.0), |_| popups::toggle(Popup::ControlCenter))
    }
}
