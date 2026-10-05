pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery !== null && battery.isPresent
    readonly property int batteryPercent: hasBattery ? Math.round(battery.percentage * 100) : 0
    readonly property bool charging: hasBattery && (battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged)
    readonly property string batteryIcon: {
        if (charging)
            return "battery_charging_full";
        if (batteryPercent >= 95)
            return "battery_full";
        return "battery_" + Math.floor(batteryPercent / 15) + "_bar";
    }
    readonly property string batteryTime: {
        if (!hasBattery)
            return "";
        const seconds = charging ? battery.timeToFull : battery.timeToEmpty;
        if (seconds <= 0)
            return charging ? "Charging" : "";
        const h = Math.floor(seconds / 3600);
        const m = Math.floor(seconds % 3600 / 60);
        return (h > 0 ? h + " h " : "") + m + " min" + (charging ? " to full" : " left");
    }

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property int volume: sink?.audio ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property string volumeIcon: muted || volume === 0 ? "volume_off" : volume < 50 ? "volume_down" : "volume_up"

    function setVolume(percent) {
        if (sink?.audio)
            sink.audio.volume = Math.max(0, Math.min(100, percent)) / 100;
    }

    function toggleMute() {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    PwObjectTracker {
        objects: [root.sink]
    }

    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property var wifiNetwork: {
        for (const device of Networking.devices.values) {
            if (device.type !== DeviceType.Wifi)
                continue;
            const network = device.networks.values.find(n => n.connected);
            if (network)
                return network;
        }
        return null;
    }
    readonly property string wifiIcon: {
        if (!wifiEnabled)
            return "signal_wifi_off";
        if (!wifiNetwork)
            return "signal_wifi_0_bar";
        const bars = Math.round(wifiNetwork.signalStrength * 4);
        return bars >= 4 ? "network_wifi" : "network_wifi_" + Math.max(1, bars) + "_bar";
    }

    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property bool bluetoothEnabled: bluetoothAdapter?.enabled ?? false
    readonly property var bluetoothDevice: Bluetooth.devices.values.find(d => d.connected) ?? null
    readonly property string bluetoothIcon: !bluetoothEnabled ? "bluetooth_disabled" : bluetoothDevice ? "bluetooth_connected" : "bluetooth"

    function toggleBluetooth() {
        if (bluetoothAdapter)
            bluetoothAdapter.enabled = !bluetoothAdapter.enabled;
    }

    property int brightness: 0

    function refreshBrightness() {
        brightnessReader.running = true;
    }

    function setBrightness(percent) {
        brightness = Math.max(5, Math.min(100, percent));
        Quickshell.execDetached(["brightnessctl", "-c", "backlight", "set", brightness + "%"]);
    }

    Process {
        id: brightnessReader
        command: ["brightnessctl", "-m", "-c", "backlight"]
        stdout: StdioCollector {
            onStreamFinished: {
                const field = text.trim().split(",")[3];
                if (field)
                    root.brightness = parseInt(field);
            }
        }
    }
}
