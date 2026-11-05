// Login state: the greetd conversation runs on its own thread, the view only reads it

use std::env;
use std::fs;
use std::process;
use std::sync::{Mutex, PoisonError};
use std::thread;

use amane::{Service, TextInput};

use crate::greetd::{Greetd, Reply};
use crate::login_screen::INPUT;

#[derive(Clone, Copy, PartialEq)]
pub enum Stage {
    Connecting,
    Asking,
    Checking,
    Starting,
}

pub struct Session {
    pub name: String,
    cmd: Vec<String>,
}

pub struct Login {
    pub user: String,
    pub stage: Stage,
    pub question: String,
    pub secret: bool,
    // (is an error, text) shown under the field
    pub message: Option<(bool, String)>,
    pub sessions: Vec<Session>,
    pub session: usize,
}

static GREETD: Mutex<Option<Greetd>> = Mutex::new(None);

impl Service for Login {
    fn new() -> Self {
        let user = env::var("AMANE_GREETER_USER").unwrap_or_default();
        let sessions = sessions();

        // the default session is preselected, the others stay one click away
        let default = env::var("AMANE_GREETER_DEFAULT_SESSION").unwrap_or_default();
        let session = sessions.iter().position(|session| session.name == default).unwrap_or(0);

        Self {
            user,
            stage: Stage::Connecting,
            question: String::new(),
            secret: true,
            message: None,
            sessions,
            session,
        }
    }

    fn listen() {
        begin();
    }
}

// Sessions installed by NixOS, as wayland-sessions desktop entries
fn sessions() -> Vec<Session> {
    let folder = env::var("AMANE_GREETER_SESSIONS").unwrap_or_default();
    let mut sessions: Vec<Session> = fs::read_dir(folder)
        .into_iter()
        .flatten()
        .flatten()
        .filter_map(|entry| {
            let entry = fs::read_to_string(entry.path()).ok()?;
            let value = |key: &str| entry.lines().find_map(|line| line.strip_prefix(key)).map(str::trim);
            let cmd = value("Exec=")?.split_whitespace().filter(|part| !part.starts_with('%')).map(String::from).collect();

            Some(Session { name: value("Name=")?.to_string(), cmd })
        })
        .collect();

    sessions.sort_by(|a, b| a.name.cmp(&b.name));
    sessions
}

pub fn next_session() {
    let mut login = Login::write();

    if !login.sessions.is_empty() {
        login.session = (login.session + 1) % login.sessions.len();
    }
}

// Runs on the view's thread, the only one that can clear the field
pub fn submit(answer: String) {
    {
        let mut login = Login::write();

        if login.stage != Stage::Asking {
            return;
        }

        login.stage = Stage::Checking;
        login.message = None;
    }

    TextInput::set_text(INPUT, "");

    thread::spawn(move || {
        let reply = with_greetd(|greetd| greetd.answer(Some(&answer)));
        handle(reply);
    });
}

// Opens a fresh conversation for the user
fn begin() {
    let user = Login::read().user.clone();

    let reply = match Greetd::connect() {
        Ok(mut greetd) => {
            let reply = greetd.create_session(&user);
            *GREETD.lock().unwrap_or_else(PoisonError::into_inner) = Some(greetd);
            reply
        }
        Err(error) => Err(error),
    };

    handle(reply);
}

fn with_greetd(request: impl FnOnce(&mut Greetd) -> std::io::Result<Reply>) -> std::io::Result<Reply> {
    let mut greetd = GREETD.lock().unwrap_or_else(PoisonError::into_inner);

    match greetd.as_mut() {
        Some(greetd) => request(greetd),
        None => Err(std::io::Error::other("not connected to greetd")),
    }
}

fn handle(reply: std::io::Result<Reply>) {
    let mut reply = reply;

    loop {
        match reply {
            Ok(Reply::Question { secret, text }) => {
                let mut login = Login::write();
                login.stage = Stage::Asking;
                login.secret = secret;
                login.question = text.trim().trim_end_matches(':').to_string();
                return;
            }
            // Notices need an empty answer before greetd goes on
            Ok(Reply::Info { error, text }) => {
                Login::write().message = Some((error, text));
                reply = with_greetd(|greetd| greetd.answer(None));
            }
            Ok(Reply::Success) => return start(),
            Ok(Reply::Error { auth, text }) => {
                let text = if auth { String::from("Incorrect password") } else { text };
                return restart(text);
            }
            Err(error) => {
                Login::write().message = Some((true, error.to_string()));
                return;
            }
        }
    }
}

fn start() {
    let cmd = {
        let mut login = Login::write();
        login.stage = Stage::Starting;
        login.sessions.get(login.session).map(|session| session.cmd.clone()).unwrap_or_default()
    };

    match with_greetd(|greetd| greetd.start_session(&cmd)) {
        // greetd launches the session once the greeter is gone
        Ok(Reply::Success) => process::exit(0),
        Ok(Reply::Error { text, .. }) => restart(text),
        Ok(_) => restart(String::from("Unexpected answer from greetd")),
        Err(error) => restart(error.to_string()),
    }
}

// A failed attempt ends the conversation; a new one asks again
fn restart(text: String) {
    let _ = with_greetd(Greetd::cancel_session);
    let user = Login::read().user.clone();
    let reply = with_greetd(|greetd| greetd.create_session(&user));

    Login::write().message = Some((true, text));
    handle(reply);
}
