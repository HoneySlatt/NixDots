// Per-widget state kept outside the view tree: hover flags and running animations, keyed by name

use std::collections::{HashMap, HashSet};
use std::sync::{LazyLock, Mutex, PoisonError};
use std::time::{Duration, Instant};

use amane::{Blend, Color};

#[derive(Clone, Copy, PartialEq)]
pub struct Motion {
    // cubic-bezier control points, none for linear
    bezier: Option<[f32; 4]>,
    millis: u64,
}

impl Motion {
    pub const fn linear(millis: u64) -> Self {
        Self { bezier: None, millis }
    }

    pub const fn curve(bezier: [f32; 4], millis: u64) -> Self {
        Self { bezier: Some(bezier), millis }
    }

    fn duration(self) -> Duration {
        Duration::from_millis(self.millis)
    }

    // eased amount for a 0..1 time fraction; springs overshoot past 1
    fn ease(self, progress: f32) -> f32 {
        match self.bezier {
            None => progress,
            Some(points) => bezier(points, progress),
        }
    }
}

// Material 3 Expressive motion, same curves as Theme.qml
pub const SPRING_FAST: Motion = Motion::curve([0.42, 1.67, 0.21, 0.90], 350);
pub const SPRING_DEFAULT: Motion = Motion::curve([0.38, 1.21, 0.22, 1.00], 500);
pub const EFFECTS: Motion = Motion::curve([0.34, 0.80, 0.34, 1.00], 200);

fn bezier([x1, y1, x2, y2]: [f32; 4], x: f32) -> f32 {
    let sample = |a: f32, b: f32, t: f32| {
        let u = 1.0 - t;
        3.0 * u * u * t * a + 3.0 * u * t * t * b + t * t * t
    };

    // bisection on x(t), which is monotonic for valid control points
    let (mut low, mut high) = (0.0, 1.0);
    let mut t = x;

    for _ in 0..24 {
        if sample(x1, x2, t) < x {
            low = t;
        } else {
            high = t;
        }
        t = (low + high) / 2.0;
    }

    sample(y1, y2, t)
}

fn progress(started: Instant, motion: Motion) -> f32 {
    let total = motion.duration().as_secs_f32();

    if total == 0.0 {
        return 1.0;
    }

    (started.elapsed().as_secs_f32() / total).min(1.0)
}

// Eased value of a motion started at `started`, keeping frames coming until it ends
pub fn since(started: Instant, motion: Motion) -> f32 {
    let progress = progress(started, motion);

    if progress < 1.0 {
        amane::request_frame();
    }

    motion.ease(progress)
}

struct Tween<T> {
    from: T,
    target: T,
    started: Instant,
    motion: Motion,
}

impl<T: Blend> Tween<T> {
    fn current(&self) -> T {
        T::blend(self.from, self.target, self.motion.ease(progress(self.started, self.motion)))
    }

    fn to(&mut self, target: T) {
        if target == self.target {
            return;
        }

        self.from = self.current();
        self.target = target;
        self.started = Instant::now();
    }

    fn value(&self) -> T {
        // a tween that never left its value has nothing to draw
        if self.from == self.target {
            return self.target;
        }

        since(self.started, self.motion);
        self.current()
    }
}

static HOVERED: LazyLock<Mutex<HashSet<String>>> = LazyLock::new(Default::default);
static FLOATS: LazyLock<Mutex<HashMap<String, Tween<f32>>>> = LazyLock::new(Default::default);
static COLORS: LazyLock<Mutex<HashMap<String, Tween<Color>>>> = LazyLock::new(Default::default);

pub fn hovered(key: &str) -> bool {
    HOVERED.lock().unwrap_or_else(PoisonError::into_inner).contains(key)
}

pub fn set_hovered(key: &str, inside: bool) {
    let mut hovered = HOVERED.lock().unwrap_or_else(PoisonError::into_inner);

    if inside {
        hovered.insert(String::from(key));
    } else {
        hovered.remove(key);
    }
}

pub fn float(key: &str, target: f32, motion: Motion) -> f32 {
    animate(&FLOATS, key, target, motion)
}

pub fn color(key: &str, target: Color, motion: Motion) -> Color {
    animate(&COLORS, key, target, motion)
}

fn animate<T: Blend>(map: &Mutex<HashMap<String, Tween<T>>>, key: &str, target: T, motion: Motion) -> T {
    let mut map = map.lock().unwrap_or_else(PoisonError::into_inner);

    let tween = map.entry(String::from(key)).or_insert_with(|| Tween {
        from: target,
        target,
        started: Instant::now(),
        motion,
    });

    tween.to(target);
    tween.value()
}

// amane reports drags but not their end, so a drag counts as live for a short while after its last move
const DRAG_GRACE: Duration = Duration::from_millis(250);

static DRAGS: LazyLock<Mutex<HashMap<String, (f32, Instant)>>> = LazyLock::new(Default::default);

pub fn drag(key: &str, value: f32) {
    DRAGS
        .lock()
        .unwrap_or_else(PoisonError::into_inner)
        .insert(String::from(key), (value, Instant::now()));
}

// The dragged value while a drag is live
pub fn dragged(key: &str) -> Option<f32> {
    let drags = DRAGS.lock().unwrap_or_else(PoisonError::into_inner);
    let &(value, at) = drags.get(key)?;

    if at.elapsed() >= DRAG_GRACE {
        return None;
    }

    amane::request_frame();
    Some(value)
}
