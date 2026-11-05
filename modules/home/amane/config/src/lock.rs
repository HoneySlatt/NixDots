// Lock screen (replaces hyprlock): the login card over the current wallpaper, on every output

use std::env;
use std::sync::{LazyLock, Mutex, PoisonError};
use std::time::Instant;

use amane::{Full, LayerWindow, Lock, Monitor, Parent, Service, Stack, TextInput, Widget};

use crate::login_screen::{self, INPUT, Prompt};
use crate::popups;
use crate::theme::Theme;

static USER: LazyLock<String> = LazyLock::new(|| env::var("USER").unwrap_or_default());

// Wallpaper and time of the current lock
static LOCKED: Mutex<Option<(String, Instant)>> = Mutex::new(None);

pub fn start(_: &[String]) -> String {
    let wallpaper = amane::output("awww query | sed -nE '1s/.*currently displaying: image: (.*)$/\\1/p'");
    *LOCKED.lock().unwrap_or_else(PoisonError::into_inner) = Some((wallpaper, Instant::now()));

    popups::close();
    TextInput::set_text(INPUT, "");
    Lock::start();

    String::new()
}

fn submit(password: String) {
    TextInput::set_text(INPUT, "");
    Lock::unlock(&password);
}

pub fn view(_: &Monitor) -> LayerWindow {
    let roles = Theme::read().roles;
    let lock = Lock::read();
    let (wallpaper, opened) = LOCKED.lock().unwrap_or_else(PoisonError::into_inner).clone().unwrap_or_else(|| (String::new(), Instant::now()));
    let user = USER.as_str();

    let prompt = Prompt {
        user,
        question: "",
        secret: true,
        busy: lock.checking(),
        message: lock.failed().then_some((true, "Incorrect password")),
    };

    let layers: Vec<Box<dyn Widget>> = vec![
        Box::new(login_screen::backdrop(&roles, &wallpaper)),
        Box::new(login_screen::clock(&roles)),
        Box::new(login_screen::card(&roles, &prompt, opened, submit, None)),
    ];

    LayerWindow::new().width(Full).height(Full).on_key(login_screen::on_key).child(Stack::new(layers).width(Parent).height(Parent))
}
