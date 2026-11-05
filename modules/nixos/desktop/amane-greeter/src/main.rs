// Login screen for greetd, built from the shell's theme and login card

// Shared with the shell (modules/home/amane/config/src), which uses more of them
#[allow(dead_code)]
mod anim;
#[allow(dead_code)]
mod icons;
#[allow(dead_code)]
mod login_screen;
#[allow(dead_code)]
mod m3;
#[allow(dead_code)]
mod theme;

mod greetd;
mod login;

use std::env;
use std::sync::LazyLock;
use std::time::Instant;

use amane::{App, End, Full, Keyboard, Layer, LayerWindow, Monitor, Parent, Rectangle, Row, Service, Stack, Widget, Zone, children};

use login::{Login, Stage};
use login_screen::Prompt;
use m3::Variant;
use theme::{Roles, Theme};

static OPENED: LazyLock<Instant> = LazyLock::new(Instant::now);

fn main() {
    // the greetd conversation starts before the first frame
    drop(Login::read());

    App::new().font(theme::FONT).window_per_monitor(view).run();
}

// The login card goes on one output, the others only show the backdrop and clock
fn is_main(monitor: &Monitor) -> bool {
    env::var("AMANE_GREETER_OUTPUT").map_or(true, |output| output == monitor.name)
}

fn view(monitor: &Monitor) -> LayerWindow {
    let roles = Theme::read().roles;
    let main = is_main(monitor);
    let wallpaper = format!("{}/wallpaper", theme::home());

    let mut layers: Vec<Box<dyn Widget>> =
        vec![Box::new(login_screen::backdrop(&roles, &wallpaper)), Box::new(login_screen::clock(&roles))];

    if main {
        let login = Login::read();

        let message = match (&login.message, login.stage) {
            (Some((error, text)), _) => Some((*error, text.as_str())),
            (None, Stage::Starting) => Some((false, "Starting session")),
            (None, Stage::Connecting) => Some((false, "Connecting to greetd")),
            (None, _) => None,
        };

        let prompt = Prompt {
            user: &login.user,
            question: &login.question,
            secret: login.secret,
            busy: login.stage != Stage::Asking,
            message,
        };

        let session = login.sessions.get(login.session).filter(|_| login.sessions.len() > 1).map(|session| -> Box<dyn Widget> {
            Box::new(m3::filter_chip(&roles, "greeter/session", ("monitor", &session.name), false, Some(login::next_session)))
        });

        layers.push(Box::new(login_screen::card(&roles, &prompt, *OPENED, login::submit, session)));
        layers.push(Box::new(power(&roles)));
    }

    let window = LayerWindow::new()
        .width(Full)
        .height(Full)
        .layer(Layer::Overlay)
        .space(Zone::Ignore)
        .namespace("amane:greeter")
        .child(Stack::new(layers).width(Parent).height(Parent));

    if main { window.keyboard(Keyboard::Exclusive).on_key(login_screen::on_key) } else { window }
}

// Restart and power off, in the bottom right corner
fn power(roles: &Roles) -> Rectangle {
    let reboot = m3::icon_button(roles, "login/reboot", "restart_alt", (56.0, 56.0), Variant::Tonal, false, false, || {
        amane::spawn("systemctl reboot")
    });
    let poweroff = m3::icon_button(roles, "login/poweroff", "power_settings_new", (56.0, 56.0), Variant::Error, false, false, || {
        amane::spawn("systemctl poweroff")
    });

    Rectangle::new()
        .width(Parent)
        .height(Parent)
        .padding(32.0)
        .align_child(End, End)
        .child(Row::new(children![reboot, poweroff]).gap(12.0))
}
