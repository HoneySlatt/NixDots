// Wi-Fi popup: radio switch, nearby networks and the password prompt

use std::time::{Duration, Instant};

use amane::{
    AccessPoint, Center, Column, Key, LayerWindow, Link, Monitor, Network, Padding, Parent, Rectangle,
    Row, Service, Stack, Start, TextInput, Weight, Widget, children,
};

use crate::anim::{self, EFFECTS, SPRING_DEFAULT, SPRING_FAST};
use crate::m3::{self, Grow, Variant};
use crate::popups::{self, Anchor, Popup};
use crate::theme::{Roles, SHAPE_L, SHAPE_M, SHAPE_XL, TYPE_BODY, TYPE_LABEL, TYPE_LABEL_S, TYPE_TITLE, Theme};

const PASSWORD: &str = "network-password";

const WIDTH: f32 = 320.0;
const PADDING: f32 = 12.0;
const INNER: f32 = WIDTH - 2.0 * PADDING;

// a rescan takes a few seconds to bring in new networks
const SCAN_TIME: Duration = Duration::from_secs(4);

pub struct NetworkPopup {
    // the secured network asking for a password
    selected: Option<String>,
    password: String,
    save: bool,
    show_password: bool,
    target: String,
    scan_started: Instant,
}

impl Service for NetworkPopup {
    fn new() -> Self {
        Self {
            selected: None,
            password: String::new(),
            save: true,
            show_password: false,
            target: String::new(),
            scan_started: Instant::now(),
        }
    }

    fn interval() -> Duration {
        Duration::from_secs(3600)
    }
}

pub fn reset() {
    {
        let mut state = NetworkPopup::write();
        state.selected = None;
        state.scan_started = Instant::now();
    }
    Network::scan();
}

fn back() {
    NetworkPopup::write().selected = None;
}

fn quote(text: &str) -> String {
    format!("'{}'", text.replace('\'', r"'\''"))
}

fn connect() {
    let (ssid, password, save) = {
        let mut state = NetworkPopup::write();
        let Some(ssid) = state.selected.take() else {
            return;
        };
        state.target = ssid.clone();
        (ssid, state.password.clone(), state.save)
    };

    if save {
        Network::connect(&ssid, Some(&password));
    } else {
        amane::spawn(&format!("nmcli --temporary dev wifi connect {} password {}", quote(&ssid), quote(&password)));
    }
}

fn choose(ssid: String, secured: bool, saved: bool) {
    if secured && !saved {
        let mut state = NetworkPopup::write();
        state.selected = Some(ssid);
        state.password.clear();
        state.save = true;
        state.show_password = false;
        drop(state);
        TextInput::set_text(PASSWORD, "");
    } else {
        NetworkPopup::write().target = ssid.clone();
        Network::connect(&ssid, None);
    }
}

fn on_key(key: Key) {
    if key != Key::Escape {
        return;
    }

    if NetworkPopup::read().selected.is_some() {
        back();
    } else {
        popups::close();
    }
}

// One entry per name, strongest first
fn networks(access_points: &[AccessPoint]) -> Vec<&AccessPoint> {
    let mut shown: Vec<&AccessPoint> = Vec::new();

    for point in access_points.iter().filter(|point| !point.ssid().is_empty()) {
        match shown.iter_mut().find(|known| known.ssid() == point.ssid()) {
            Some(known) if point.strength() > known.strength() || point.active() => *known = point,
            Some(_) => {}
            None => shown.push(point),
        }
    }

    shown.sort_by_key(|point| std::cmp::Reverse(point.strength()));
    shown.truncate(8);
    shown
}

fn signal_icon(strength: u8) -> &'static str {
    ["signal_wifi_0_bar", "network_wifi_1_bar", "network_wifi_2_bar", "network_wifi_3_bar", "signal_wifi_4_bar"]
        [usize::from(strength / 20).min(4)]
}

pub fn view(monitor: &Monitor) -> LayerWindow {
    popups::window(monitor, Popup::Network, Anchor::Right(55.0), on_key, |context| {
        let roles = Theme::read().roles;
        let network = Network::read();
        let state = NetworkPopup::read();

        let body: Box<dyn Widget> = if network.connecting() {
            Box::new(connecting(&roles, &state.target))
        } else if let Some(ssid) = &state.selected {
            Box::new(password_view(&roles, ssid, &state))
        } else {
            Box::new(list(&roles, &network, state.scan_started.elapsed() < SCAN_TIME))
        };

        let column = Column::new(vec![Box::new(header(&roles, &network)), body]).width(INNER).gap(12.0);
        let height = anim::float("network/height", m3::height_of(&column) + 2.0 * PADDING, SPRING_DEFAULT);

        let content = Rectangle::new().width(Parent).height(Parent).padding(PADDING).clip().child(column);

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

fn header(roles: &Roles, network: &Network) -> Row {
    let enabled = network.wifi_enabled();

    let status = if !enabled {
        String::from("Off")
    } else {
        match network.link() {
            Link::Wifi => String::from(network.ssid()),
            Link::Wired => String::from("Ethernet"),
            _ => String::from("Not connected"),
        }
    };

    let bubble = Rectangle::new()
        .width(40.0)
        .height(40.0)
        .radius(anim::float("network/bubble", if enabled { SHAPE_M } else { 20.0 }, SPRING_FAST))
        .fill(anim::color(
            "network/bubble-color",
            if enabled { roles.primary_container } else { roles.surface_container_highest },
            EFFECTS,
        ))
        .align_child(Center, Center)
        .child(m3::icon(
            if enabled { "wifi" } else { "wifi_off" },
            24.0,
            if enabled { roles.text_on_primary_container } else { roles.text_on_surface_variant },
            false,
        ));

    let titles = Column::new(children![
        m3::label("Wi-Fi", TYPE_TITLE, roles.text_on_surface).weight(Weight::Bold),
        m3::label(status, TYPE_LABEL, roles.text_on_surface_variant).elide(),
    ])
    .width(Parent);

    Row::new(children![bubble, titles, m3::switch(roles, "network/switch", enabled, move || Network::set_wifi(!enabled))])
        .width(INNER)
        .gap(14.0)
        .align(Center)
}

fn list(roles: &Roles, network: &Network, scanning: bool) -> Column {
    let enabled = network.wifi_enabled();

    let mut title: Vec<Box<dyn Widget>> = vec![Box::new(
        Rectangle::new().width(Parent).height(24.0).padding(m3::horizontal(4.0, 0.0)).align_child(Start, Center).child(
            m3::label(if enabled { "Available networks" } else { "Wi-Fi is off" }, TYPE_LABEL, roles.primary)
                .weight(Weight::Bold),
        ),
    )];
    if scanning && enabled {
        title.push(Box::new(m3::loading_indicator(roles.primary, 22.0)));
    }

    let mut rows: Vec<Box<dyn Widget>> = Vec::new();

    if enabled {
        let shown = networks(network.access_points());

        for (index, point) in shown.iter().enumerate() {
            rows.push(Box::new(row(roles, point, (index == 0, index == shown.len() - 1))));
        }
    }

    Column::new(children![
        Row::new(title).width(INNER).height(24.0).align(Center),
        Column::new(rows).width(INNER).gap(2.0),
    ])
    .width(INNER)
    .gap(10.0)
}

fn row(roles: &Roles, point: &AccessPoint, position: (bool, bool)) -> Rectangle {
    let key = format!("network/row/{}", point.ssid());
    let connected = point.active();
    let (first, last) = position;

    let top = anim::float(&format!("{key}/top"), if connected || first { 20.0 } else { 4.0 }, SPRING_FAST);
    let bottom = anim::float(&format!("{key}/bottom"), if connected || last { 20.0 } else { 4.0 }, SPRING_FAST);
    let (base, tint) = if connected {
        (roles.secondary_container, roles.text_on_secondary_container)
    } else {
        (roles.surface_container_high, roles.text_on_surface)
    };

    let bubble = Rectangle::new()
        .width(36.0)
        .height(36.0)
        .radius(anim::float(&format!("{key}/bubble"), if connected { SHAPE_M } else { 18.0 }, SPRING_FAST))
        .fill(if connected { roles.primary } else { roles.surface_container_highest })
        .align_child(Center, Center)
        .child(m3::icon(
            signal_icon(point.strength()),
            20.0,
            if connected { roles.text_on_primary } else { roles.text_on_surface_variant },
            false,
        ));

    let status = if connected { "Connected" } else if point.secured() { "Secured" } else { "Open" };
    let titles = Column::new(children![
        m3::label(point.ssid(), TYPE_BODY + 1.0, tint).weight(Weight::Bold).elide(),
        m3::label(status, TYPE_LABEL, if connected { roles.primary } else { roles.text_on_surface_variant }),
    ])
    .width(Parent)
    .gap(1.0);

    let mut items: Vec<Box<dyn Widget>> = vec![Box::new(bubble), Box::new(titles)];
    if point.secured() {
        items.push(Box::new(m3::icon("lock", 16.0, roles.text_on_surface_variant, false)));
    }

    let (ssid, secured, saved) = (String::from(point.ssid()), point.secured(), point.saved());

    m3::hoverable(Rectangle::new().width(INNER).height(52.0), &key)
        .radius_top_left(top)
        .radius_top_right(top)
        .radius_bottom_left(bottom)
        .radius_bottom_right(bottom)
        .fill(m3::state_color(&key, base, tint))
        .padding(m3::horizontal(12.0, 16.0))
        .align_child(Start, Center)
        .on_click(move |_| {
            if !connected {
                choose(ssid.clone(), secured, saved);
            }
        })
        .child(Row::new(items).width(Parent).gap(14.0).align(Center))
}

fn password_view(roles: &Roles, ssid: &str, state: &NetworkPopup) -> Column {
    let title = Row::new(children![
        m3::icon_button(roles, "network/back", "arrow_back", (40.0, 40.0), Variant::Standard, false, false, back),
        Column::new(children![
            m3::label(ssid, TYPE_TITLE, roles.text_on_surface).weight(Weight::Bold).elide(),
            m3::label("Secured network", TYPE_LABEL, roles.text_on_surface_variant),
        ])
        .width(Parent),
    ])
    .width(INNER)
    .gap(10.0)
    .align(Center);

    let input = TextInput::new(PASSWORD)
        .size(TYPE_TITLE)
        .color(roles.text_on_surface)
        .width(INNER - 16.0 - 8.0 - 40.0 - 8.0)
        .focused()
        .on_change(|text| NetworkPopup::write().password = text)
        .on_submit(|_| connect());
    let input = if state.show_password { input } else { input.password() };

    let show = state.show_password;
    let field = Rectangle::new()
        .width(INNER)
        .height(52.0)
        .radius(SHAPE_L)
        .fill(roles.surface_container_highest)
        .border(2.0, roles.primary)
        .child(
            Stack::new(children![
                Rectangle::new()
                    .width(Parent)
                    .height(Parent)
                    .padding(Padding { top: 9.0, right: 0.0, bottom: 0.0, left: 16.0 })
                    .child(m3::label("Password", TYPE_LABEL_S, roles.primary).weight(Weight::Bold)),
                Rectangle::new()
                    .width(Parent)
                    .height(Parent)
                    .padding(Padding { top: 22.0, right: 56.0, bottom: 4.0, left: 16.0 })
                    .align_child(Start, Center)
                    .child(input),
                Rectangle::new().width(Parent).height(Parent).padding(m3::horizontal(0.0, 8.0)).align_child(amane::End, Center).child(
                    m3::icon_button(
                        roles,
                        "network/eye",
                        if show { "visibility_off" } else { "visibility" },
                        (40.0, 40.0),
                        Variant::Standard,
                        false,
                        false,
                        || {
                            let mut state = NetworkPopup::write();
                            state.show_password = !state.show_password;
                        },
                    ),
                ),
            ])
            .width(INNER)
            .height(52.0),
        );

    let save = Row::new(children![
        Rectangle::new()
            .width(Parent)
            .height(32.0)
            .padding(m3::horizontal(4.0, 0.0))
            .align_child(Start, Center)
            .child(m3::label("Save password", TYPE_BODY, roles.text_on_surface)),
        m3::switch(roles, "network/save", state.save, || {
            let mut state = NetworkPopup::write();
            state.save = !state.save;
        }),
    ])
    .width(INNER)
    .gap(12.0)
    .align(Center);

    let half = (INNER - 8.0) / 2.0;
    let buttons = Row::new(children![
        m3::text_button(roles, "network/cancel", "Cancel", half, Variant::Outlined, back),
        m3::text_button(roles, "network/connect", "Connect", half, Variant::Filled, connect),
    ])
    .gap(8.0);

    Column::new(children![title, field, save, buttons]).width(INNER).gap(16.0)
}

fn connecting(roles: &Roles, target: &str) -> Column {
    let name = if target.is_empty() { "network" } else { target };

    Column::new(children![
        Rectangle::new().width(INNER).height(8.0),
        m3::centered(INNER, 48.0, m3::loading_indicator(roles.primary, 48.0)),
        m3::centered(
            INNER,
            22.0,
            m3::label(format!("Connecting to {name}"), TYPE_TITLE, roles.text_on_surface).weight(Weight::Bold),
        ),
        m3::centered(INNER, 18.0, m3::label("Please wait", TYPE_BODY, roles.text_on_surface_variant)),
        Rectangle::new().width(INNER).height(8.0),
    ])
    .width(INNER)
    .gap(14.0)
}
