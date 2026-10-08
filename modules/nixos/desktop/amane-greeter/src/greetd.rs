// greetd IPC: a native-endian u32 length, then a JSON object (no serde available)

use std::env;
use std::io::{self, Read, Write};
use std::os::unix::net::UnixStream;

pub enum Reply {
    Success,
    // `auth`: the answers were refused, rather than greetd failing
    Error { auth: bool, text: String },
    // Needs an answer, typed hidden when `secret`
    Question { secret: bool, text: String },
    // Needs no answer
    Info { error: bool, text: String },
}

pub struct Greetd {
    stream: UnixStream,
}

impl Greetd {
    pub fn connect() -> io::Result<Self> {
        let path = env::var("GREETD_SOCK").map_err(|_| io::Error::other("GREETD_SOCK is not set"))?;

        Ok(Self { stream: UnixStream::connect(path)? })
    }

    pub fn create_session(&mut self, username: &str) -> io::Result<Reply> {
        self.send(&format!(r#"{{"type":"create_session","username":{}}}"#, quote(username)))
    }

    pub fn answer(&mut self, response: Option<&str>) -> io::Result<Reply> {
        let response = response.map_or_else(|| String::from("null"), quote);

        self.send(&format!(r#"{{"type":"post_auth_message_response","response":{response}}}"#))
    }

    pub fn start_session(&mut self, cmd: &[String]) -> io::Result<Reply> {
        let cmd: Vec<String> = cmd.iter().map(|part| quote(part)).collect();

        self.send(&format!(r#"{{"type":"start_session","cmd":[{}],"env":[]}}"#, cmd.join(",")))
    }

    pub fn cancel_session(&mut self) -> io::Result<Reply> {
        self.send(r#"{"type":"cancel_session"}"#)
    }

    fn send(&mut self, request: &str) -> io::Result<Reply> {
        self.stream.write_all(&(request.len() as u32).to_ne_bytes())?;
        self.stream.write_all(request.as_bytes())?;

        let mut length = [0; 4];
        self.stream.read_exact(&mut length)?;

        let mut body = vec![0; u32::from_ne_bytes(length) as usize];
        self.stream.read_exact(&mut body)?;

        Ok(parse(&String::from_utf8_lossy(&body)))
    }
}

fn parse(json: &str) -> Reply {
    let text = |key| field(json, key).unwrap_or_default();

    match text("type").as_str() {
        "success" => Reply::Success,
        "auth_message" => {
            let message = text("auth_message");

            match text("auth_message_type").as_str() {
                "secret" => Reply::Question { secret: true, text: message },
                "visible" => Reply::Question { secret: false, text: message },
                kind => Reply::Info { error: kind == "error", text: message },
            }
        }
        _ => Reply::Error { auth: text("error_type") == "auth_error", text: text("description") },
    }
}

fn quote(text: &str) -> String {
    let mut quoted = String::from("\"");

    for character in text.chars() {
        match character {
            '"' => quoted.push_str("\\\""),
            '\\' => quoted.push_str("\\\\"),
            '\n' => quoted.push_str("\\n"),
            '\r' => quoted.push_str("\\r"),
            '\t' => quoted.push_str("\\t"),
            control if control.is_control() => quoted.push_str(&format!("\\u{:04x}", control as u32)),
            other => quoted.push(other),
        }
    }

    quoted.push('"');
    quoted
}

// String value of a top-level key; greetd only sends flat objects
fn field(json: &str, key: &str) -> Option<String> {
    let start = json.find(&format!("\"{key}\":"))? + key.len() + 3;
    let mut characters = json[start..].trim_start().chars();

    if characters.next()? != '"' {
        return None;
    }

    let mut value = String::new();

    while let Some(character) = characters.next() {
        match character {
            '"' => return Some(value),
            '\\' => match characters.next()? {
                'n' => value.push('\n'),
                'r' => value.push('\r'),
                't' => value.push('\t'),
                'u' => {
                    let code: String = characters.by_ref().take(4).collect();
                    value.extend(u32::from_str_radix(&code, 16).ok().and_then(char::from_u32));
                }
                escaped => value.push(escaped),
            },
            other => value.push(other),
        }
    }

    None
}
