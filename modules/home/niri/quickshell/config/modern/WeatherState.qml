pragma Singleton

import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property string temperature: "--"
    property string description: "Loading..."
    property string icon: "cloud" // default weather icon

    // Map wttr.in weather codes to Material Symbols icons
    function _weatherIcon(code) {
        let c = parseInt(code);
        if (c === 113) return "sunny"; // Sunny / Clear
        if (c === 116) return "partly_cloudy_day"; // Partly cloudy
        if (c === 119 || c === 122) return "cloud"; // Cloudy / Overcast
        if (c === 143 || c === 248 || c === 260) return "foggy"; // Fog
        if (c === 176 || c === 263 || c === 266 || c === 293 || c === 296)
            return "rainy_light"; // Light rain / drizzle
        if (c === 299 || c === 302 || c === 305 || c === 308 || c === 356 || c === 359)
            return "rainy_heavy"; // Heavy rain
        if (c === 179 || c === 323 || c === 326 || c === 368)
            return "weather_snowy"; // Light snow
        if (c === 182 || c === 185 || c === 281 || c === 284 || c === 311 || c === 314 || c === 317 || c === 350 || c === 362 || c === 365 || c === 374 || c === 377)
            return "weather_snowy"; // Sleet / ice
        if (c === 200 || c === 386 || c === 389 || c === 392 || c === 395)
            return "thunderstorm"; // Thunder
        if (c === 227 || c === 230 || c === 329 || c === 332 || c === 335 || c === 338 || c === 371)
            return "weather_snowy"; // Heavy snow / blizzard
        return "cloud"; // fallback cloudy
    }

    readonly property var _fetchProc: Process {
        command: ["curl", "-sf", "wttr.in/?format=j1"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text);
                    let current = data.current_condition[0];
                    root.temperature = current.temp_C + "°C";
                    root.description = current.weatherDesc[0].value;
                    root.icon = root._weatherIcon(current.weatherCode);
                } catch (e) {
                    root.temperature = "--";
                    root.description = "Unavailable";
                }
            }
        }
    }

    readonly property var _pollTimer: Timer {
        interval: 900000 // 15 minutes
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root._fetchProc.running = true
    }
}
