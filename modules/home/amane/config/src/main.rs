mod anim;
mod art;
mod bar;
mod calendar;
mod calendar_pages;
mod control_center;
mod icons;
mod kopuz;
mod launcher;
mod lock;
mod login_screen;
mod m3;
mod music_launcher;
mod network_popup;
mod notifications;
mod osd;
mod popups;
mod power_menu;
mod screenshot;
mod small_launcher;
mod steam_launcher;
mod system;
mod system_monitor;
mod theme;
mod theme_launcher;
mod tray;
mod tray_menu;
mod volume_popup;
mod vpn_launcher;
mod wallpaper_launcher;

use amane::{App, Service};

use popups::Popup;

fn main() {
    // samples are collected from the start
    drop(system::History::read());
    // the tray watcher has to be there before programs register their items
    drop(tray::Tray::read());
    // programs may send notifications as soon as the session starts
    drop(amane::Notifications::read());

    App::new()
        .font(theme::FONT)
        .ipc("toggle-bar-position", bar::toggle_position)
        .ipc("toggle-launcher", |_| popups::ipc_toggle(Popup::SmallLauncher))
        .ipc("toggle-power-launcher", |_| popups::ipc_toggle(Popup::PowerMenu))
        .ipc("toggle-theme-launcher", |_| popups::ipc_toggle(Popup::ThemeLauncher))
        .ipc("toggle-wallpaper-launcher", |_| popups::ipc_toggle(Popup::WallpaperLauncher))
        .ipc("toggle-game-launcher", |_| popups::ipc_toggle(Popup::SteamLauncher))
        .ipc("toggle-vpn-launcher", |_| popups::ipc_toggle(Popup::VpnLauncher))
        .ipc("toggle-music-launcher", |_| popups::ipc_toggle(Popup::MusicLauncher))
        .ipc("screenshot", screenshot::ipc)
        .ipc("toggle-notifications", |_| popups::ipc_toggle(Popup::Notifications))
        .ipc("toggle-dnd", |_| {
            notifications::toggle_dnd();
            String::from(if notifications::dnd() { "on" } else { "off" })
        })
        .ipc("lock-screen", lock::start)
        .ipc("osd", osd::ipc)
        .window_per_monitor(bar::view)
        .window_per_monitor(popups::click_outside)
        .window_per_monitor(popups::view)
        .window_per_monitor(notifications::toast_window)
        .window_per_monitor(osd::view)
        .lock(lock::view)
        .run();
}
