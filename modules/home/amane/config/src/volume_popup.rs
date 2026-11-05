// Volume popup: output level, output device and per-app volumes

use std::thread;
use std::time::Duration;

use amane::{
    Audio, Center, Column, Key, LayerWindow, Monitor, Parent, Rectangle, Row, Service, Start,
    Weight, Widget, children,
};

use crate::m3::{self, Grow, Variant};
use crate::popups::{self, Anchor, Popup};
use crate::system;
use crate::theme::{Roles, SHAPE_XL, TYPE_BODY, TYPE_LABEL, TYPE_TITLE, Theme};

const WIDTH: f32 = 288.0;
const PADDING: f32 = 12.0;
const INNER: f32 = WIDTH - 2.0 * PADDING;

// Same entries as the Sinks and Streams sections of `wpctl status`
const NODES: &str = r#"pw-dump 2>/dev/null | jq -r '
  (map(select(.type == "PipeWire:Interface:Metadata" and .props["metadata.name"] == "default"))
    | .[0].metadata // [] | map(select(.key == "default.audio.sink")) | .[0].value.name // "") as $default
  | map(select(.type == "PipeWire:Interface:Node")) | sort_by(.id) | .[]
  | .info.props as $p | ($p["media.class"] // "") as $class
  | select($class == "Audio/Sink" or ($class | startswith("Stream/") and contains("Audio") and (contains("Internal") | not)))
  | (.info.params.Props[0] // {}) as $v
  | [(if $class == "Audio/Sink" then "sink" else "stream" end), .id,
     (if $class == "Audio/Sink" then $p["node.description"] // $p["node.name"] else $p["node.name"] end // ""),
     (($v.channelVolumes // [0])[0] | pow(.; 1/3) * 100 | round), ($v.mute // false), ($p["node.name"] == $default)]
  | @tsv'"#;

#[derive(Clone, PartialEq)]
struct Node {
    id: u32,
    label: String,
    volume: u8,
    muted: bool,
    active: bool,
}

#[derive(Default, PartialEq)]
pub struct AudioNodes {
    sinks: Vec<Node>,
    streams: Vec<Node>,
}

impl AudioNodes {
    fn read_now() -> Self {
        let mut nodes = Self::default();

        for line in amane::output(NODES).lines() {
            let fields: Vec<&str> = line.split('\t').collect();
            let [kind, id, label, volume, muted, active] = fields[..] else {
                continue;
            };

            let node = Node {
                id: id.parse().unwrap_or_default(),
                label: String::from(label),
                volume: volume.parse::<u8>().unwrap_or_default().min(100),
                muted: muted == "true",
                active: active == "true",
            };

            match kind {
                "sink" => nodes.sinks.push(node),
                _ if !node.label.is_empty() => nodes.streams.push(node),
                _ => {}
            }
        }

        nodes
    }
}

fn refresh() {
    let nodes = AudioNodes::read_now();

    if nodes != *AudioNodes::read() {
        *AudioNodes::write() = nodes;
    }
}

// Runs a wpctl command, then reads the nodes back
fn wpctl(command: String) {
    thread::spawn(move || {
        amane::output(&format!("wpctl {command}"));
        refresh();
    });
}

impl Service for AudioNodes {
    fn new() -> Self {
        Self::default()
    }

    fn listen() {
        system::poll(Self::interval(), || popups::is_open(Popup::Volume), Self::read_now);
    }
}

#[derive(Default)]
pub struct VolumePopup {
    devices: bool,
    apps: bool,
}

impl Service for VolumePopup {
    fn new() -> Self {
        Self::default()
    }

    fn interval() -> Duration {
        Duration::from_secs(3600)
    }
}

pub fn reset() {
    *VolumePopup::write() = VolumePopup::default();
    thread::spawn(refresh);
}

fn volume_icon(volume: u8, muted: bool) -> &'static str {
    match volume {
        _ if muted => "volume_off",
        0..=30 => "volume_mute",
        31..=65 => "volume_down",
        _ => "volume_up",
    }
}

fn on_key(key: Key) {
    if key == Key::Escape {
        popups::close();
    }
}

pub fn view(monitor: &Monitor) -> LayerWindow {
    popups::window(monitor, Popup::Volume, Anchor::Right(86.0), on_key, |context| {
        let roles = Theme::read().roles;
        let audio = Audio::read();
        let nodes = AudioNodes::read();
        let state = VolumePopup::read();

        let (volume, muted) = (audio.volume(), audio.muted());
        let active = nodes.sinks.iter().find(|sink| sink.active).map(|sink| sink.label.clone());

        let titles = Column::new(children![
            m3::label("Volume", TYPE_TITLE, roles.text_on_surface).weight(Weight::Bold),
            m3::label(
                if muted { String::from("Muted") } else { active.clone().unwrap_or_else(|| String::from("Output")) },
                TYPE_LABEL,
                roles.text_on_surface_variant,
            )
            .elide(),
        ])
        .width(Parent);

        let header = Row::new(children![
            m3::icon_button(
                &roles,
                "volume/mute",
                volume_icon(volume, muted),
                (40.0, 40.0),
                Variant::Filled,
                true,
                !muted,
                Audio::toggle_mute,
            ),
            titles,
            m3::label(format!("{volume}%"), TYPE_TITLE, if muted { roles.text_on_surface_variant } else { roles.primary })
                .weight(Weight::Bold),
        ])
        .width(INNER)
        .gap(14.0)
        .align(Center);

        let slider = m3::slider(
            &roles,
            "volume/level",
            (INNER, 12.0, 32.0),
            (f32::from(volume), muted),
            "",
            None,
            Audio::set_volume,
        );

        let devices = m3::section(
            &roles,
            "volume/devices",
            INNER,
            ("speaker", "Output device", active.as_deref().unwrap_or_default()),
            (true, false),
            state.devices,
            || {
                let mut state = VolumePopup::write();
                state.devices = !state.devices;
            },
            sinks(&roles, &nodes.sinks),
        );

        let count = nodes.streams.len();
        let apps = m3::section(
            &roles,
            "volume/apps",
            INNER,
            ("tune", "App volumes", &format!("{count} {}", if count == 1 { "stream" } else { "streams" })),
            (false, true),
            state.apps,
            || {
                let mut state = VolumePopup::write();
                state.apps = !state.apps;
            },
            streams(&roles, &nodes.streams),
        );

        let column = Column::new(children![header, slider, Column::new(children![devices, apps]).gap(2.0)])
            .width(INNER)
            .gap(10.0);
        let height = m3::height_of(&column) + 2.0 * PADDING;

        let content = Rectangle::new().width(Parent).height(Parent).padding(PADDING).child(column);

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

fn sinks(roles: &Roles, sinks: &[Node]) -> Column {
    let width = INNER - 16.0;
    let mut rows: Vec<Box<dyn Widget>> = Vec::new();

    for sink in sinks {
        let key = format!("volume/sink/{}", sink.id);
        let (base, tint) = if sink.active {
            (roles.secondary_container, roles.text_on_secondary_container)
        } else {
            (amane::Color::TRANSPARENT, roles.text_on_surface)
        };

        let name = if sink.label.to_lowercase().contains("head") { "headphones" } else { "speaker" };
        let icon_color = if sink.active { roles.text_on_secondary_container } else { roles.text_on_surface_variant };

        let mut items: Vec<Box<dyn Widget>> = vec![
            Box::new(m3::icon(name, 18.0, icon_color, false)),
            Box::new(
                m3::label(sink.label.clone(), TYPE_BODY, tint)
                    .weight(if sink.active { Weight::Bold } else { Weight::SemiBold })
                    .elide(),
            ),
        ];
        if sink.active {
            items.push(Box::new(m3::icon("check", 18.0, roles.text_on_secondary_container, false)));
        }

        let id = sink.id;

        rows.push(Box::new(
            m3::hoverable(Rectangle::new().width(width).height(44.0), &key)
                .radius(22.0)
                .fill(m3::state_color(&key, base, tint))
                .padding(m3::horizontal(14.0, 14.0))
                .align_child(Start, Center)
                .on_click(move |_| wpctl(format!("set-default {id}")))
                .child(Row::new(items).width(Parent).gap(12.0).align(Center)),
        ));
    }

    Column::new(rows).width(width).gap(2.0)
}

fn streams(roles: &Roles, streams: &[Node]) -> Column {
    let width = INNER - 16.0;

    if streams.is_empty() {
        return Column::new(children![m3::centered(
            width,
            40.0,
            m3::label("No app streams", TYPE_BODY, roles.text_on_surface_variant),
        )])
        .width(width);
    }

    let mut rows: Vec<Box<dyn Widget>> = Vec::new();

    for stream in streams {
        let id = stream.id;
        let key = format!("volume/stream/{id}");

        let slider = m3::slider(
            roles,
            &key,
            (width - 8.0 - 18.0 - 72.0 - 32.0 - 3.0 * 10.0, 10.0, 24.0),
            (f32::from(stream.volume), stream.muted),
            "",
            None,
            move |volume| wpctl(format!("set-volume {id} {volume}%")),
        );

        let mute = m3::icon_button(
            roles,
            &format!("{key}/mute"),
            if stream.muted { "volume_off" } else { "volume_up" },
            (32.0, 32.0),
            Variant::Standard,
            true,
            stream.muted,
            move || wpctl(format!("set-mute {id} toggle")),
        );

        rows.push(Box::new(
            Rectangle::new().width(width).height(44.0).padding(m3::horizontal(8.0, 0.0)).align_child(Start, Center).child(
                Row::new(children![
                    m3::icon("apps", 18.0, roles.text_on_surface_variant, false),
                    Rectangle::new()
                        .width(72.0)
                        .height(20.0)
                        .align_child(Start, Center)
                        .child(m3::label(stream.label.clone(), TYPE_BODY, roles.text_on_surface).elide()),
                    slider,
                    mute,
                ])
                .gap(10.0)
                .align(Center),
            ),
        ));
    }

    Column::new(rows).width(width).gap(2.0)
}
